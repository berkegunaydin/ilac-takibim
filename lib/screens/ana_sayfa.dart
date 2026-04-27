import 'package:flutter/material.dart';
import '../models/ilac.dart';
import '../models/profil.dart';
import '../services/kayit_servisi.dart';
import '../services/bildirim_servisi.dart';
import '../services/reklam_servisi.dart';
import '../widgets/ilac_ekle_dialog.dart';
import 'bugun_ekrani.dart';
import 'tum_ilaclar_ekrani.dart';
import 'takvim_ekrani.dart';
import 'istatistik_ekrani.dart';
import 'premium_ekrani.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with WidgetsBindingObserver {
  List<Profil> profiller = [];
  int secilenProfilIndex = 0;
  int _secilenSekme = 0;
  bool _alarmIzniVerildi = true; // ayarlardan döndüğünde yeniden zamanlama için

  Profil get secilenProfil => profiller[secilenProfilIndex];
  List<Ilac> get ilaclar => secilenProfil.ilaclar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _yukle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _izinKontrol();
    }
  }

  Future<void> _yukle() async {
    final liste = await KayitServisi.profilleriYukle();
    setState(() => profiller = liste);
    // Uygulama her açıldığında bildirimleri yenile (telefon yeniden başlatma dahil)
    final tumIlaclar = liste.expand((p) => p.ilaclar).toList();
    await BildirimServisi.tumBildirimleriYenile(tumIlaclar);
    _izinKontrol();
  }

  Future<void> _izinKontrol() async {
    final alarmIzni = await BildirimServisi.alarmIzniVarMi();
    if (!mounted) return;

    if (!alarmIzni) {
      _alarmIzniVerildi = false;
      _alarmIzniDialogGoster();
      return;
    }

    // İzin yeni verildi → bildirimleri yenile
    if (!_alarmIzniVerildi) {
      _alarmIzniVerildi = true;
      final tumIlaclar = profiller.expand((p) => p.ilaclar).toList();
      await BildirimServisi.tumBildirimleriYenile(tumIlaclar);
    }

    final pilOptimize = await BildirimServisi.pilOptimizasyonuAktifMi();
    if (pilOptimize && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Bildirimler uygulama kapalıyken gelmeyebilir. Pil iznini açın.'),
          action: SnackBarAction(
            label: 'Düzelt',
            onPressed: BildirimServisi.pilOptimizasyonundanCikar,
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _alarmIzniDialogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Alarm İzni Gerekli'),
        content: const Text(
          'Bildirimlerin çalışması için "Alarm ve hatırlatıcılar" iznini açmanız gerekiyor.\n\n'
          'Açılan ekranda İlaç Takibim uygulamasının yanındaki anahtarı açın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await BildirimServisi.alarmAyarlariniAc();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75)),
            child: const Text('İzin Ver',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _kaydet() async {
    await KayitServisi.profilleriKaydet(profiller);
  }

  Future<void> _ilacEkle(String isim, String doz, String saat, String emoji, List<int> gunler, int stok, int stokUyariEsigi, int bildirimOnce) async {
    final yeniIlac = Ilac(isim: isim, doz: doz, saat: saat, emoji: emoji, gunler: gunler, stok: stok, stokUyariEsigi: stokUyariEsigi, bildirimOnce: bildirimOnce);
    setState(() => ilaclar.add(yeniIlac));
    await _kaydet();
    await BildirimServisi.bildirimAyarla(yeniIlac);
    ReklamServisi.ilacEklendi();
  }

  void _ilacSil(Ilac ilac) {
    setState(() => ilaclar.remove(ilac));
    _kaydet();
    BildirimServisi.iptalEt(ilac);
  }

  void _ilacDuzenle(Ilac ilac, String isim, String doz, String saat, String emoji, List<int> gunler, int stok, int stokUyariEsigi, int bildirimOnce) {
    final index = ilaclar.indexOf(ilac);
    final yeniIlac = Ilac(
      bildirimId: ilac.bildirimId,
      isim: isim, doz: doz, saat: saat, emoji: emoji,
      gunler: gunler, eklemeTarihi: ilac.eklemeTarihi,
      bildirimOnce: bildirimOnce,
      stok: stok, stokUyariEsigi: stokUyariEsigi, gecmis: ilac.gecmis,
    );
    setState(() => ilaclar[index] = yeniIlac);
    _kaydet();
    BildirimServisi.bildirimAyarla(yeniIlac);
  }

  void _alindiToggle(Ilac ilac) {
    final bugun = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      ilac.alindi = !ilac.alindi;
      ilac.sonAlinmaTarihi = ilac.alindi ? bugun : '';
      ilac.gecmis[bugun] = ilac.alindi;
      if (ilac.alindi && ilac.stok > 0) {
        ilac.stok--;
        if (ilac.stok == ilac.stokUyariEsigi) {
          BildirimServisi.stokBildirimi(ilac);
        }
      } else if (!ilac.alindi && ilac.stok >= 0) {
        ilac.stok++;
      }
    });
    _kaydet();
    // Takip alarmını güncelle: alındıysa iptal et, geri alındıysa yeniden planla
    BildirimServisi.bildirimAyarla(ilac);
  }

  void _profilEkle() {
    final isimController = TextEditingController();
    String secilenEmoji = '👤';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: ['👤', '👩', '👨', '👧', '👦', '👴', '👵'].map((e) =>
                  GestureDetector(
                    onTap: () => setDialogState(() => secilenEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: secilenEmoji == e
                            ? const Color(0xFFE1F5EE)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: isimController,
                decoration: const InputDecoration(
                  labelText: 'İsim',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (isimController.text.isNotEmpty) {
                  setState(() => profiller.add(
                    Profil(isim: isimController.text, emoji: secilenEmoji),
                  ));
                  _kaydet();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
              child: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _profilSecenekler(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF1D9E75)),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _profilDuzenle(index);
              },
            ),
            if (profiller.length > 1)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _profilSil(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _profilDuzenle(int index) {
    final profil = profiller[index];
    final isimController = TextEditingController(text: profil.isim);
    String secilenEmoji = profil.emoji;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Profili Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: ['👤', '👩', '👨', '👧', '👦', '👴', '👵'].map((e) =>
                  GestureDetector(
                    onTap: () => setDialogState(() => secilenEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: secilenEmoji == e
                            ? const Color(0xFFE1F5EE)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: isimController,
                decoration: const InputDecoration(
                  labelText: 'İsim',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (isimController.text.isNotEmpty) {
                  setState(() {
                    profiller[index] = Profil(
                      isim: isimController.text,
                      emoji: secilenEmoji,
                      ilaclar: profil.ilaclar,
                    );
                  });
                  _kaydet();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _profilSil(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profili Sil'),
        content: Text('${profiller[index].isim} profilini silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                profiller.removeAt(index);
                if (secilenProfilIndex >= profiller.length) {
                  secilenProfilIndex = profiller.length - 1;
                }
              });
              _kaydet();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _tanilamaDialogGoster() async {
    final bildirimIzni = await BildirimServisi.alarmIzniVarMi();
    final pilOptimize = await BildirimServisi.pilOptimizasyonuAktifMi();
    final zamanlanmis = await bildirimPlugin.pendingNotificationRequests();
    if (!mounted) return;

    // Her ilacın en yakın bildirim zamanını hesapla
    final sirali = ilaclar
        .where((ilac) => ilac.gunler.isNotEmpty)
        .map((ilac) {
          final zamanlari = BildirimServisi.bildirimZamanlariHesapla(ilac);
          return (ilac: ilac, sonraki: zamanlari.isNotEmpty ? zamanlari.first : null);
        })
        .where((e) => e.sonraki != null)
        .toList()
      ..sort((a, b) => a.sonraki!.compareTo(b.sonraki!));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bildirim Tanılama'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _durumSatiri('Bildirim & alarm izni',
                    bildirimIzni ? '✅ Verilmiş' : '❌ Verilmemiş'),
                _durumSatiri('Pil optimizasyonu',
                    pilOptimize ? '⚠️ Aktif (engel)' : '✅ Devre dışı'),
                _durumSatiri('Zamanlanmış bildirim',
                    '${zamanlanmis.length} adet'),
                if (BildirimServisi.sonHata != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '❌ Hata: ${BildirimServisi.sonHata}',
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ),
                if (sirali.isNotEmpty) ...[
                  const Divider(height: 20),
                  const Text('Yakında gelecek bildirimler:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...sirali.take(5).map((e) {
                    final dt = e.sonraki!;
                    final now = DateTime.now();
                    final fark = dt.difference(now);
                    final farkStr = fark.inDays > 0
                        ? '${fark.inDays}g ${fark.inHours % 24}sa'
                        : fark.inHours > 0
                            ? '${fark.inHours}sa ${fark.inMinutes % 60}dk'
                            : '${fark.inMinutes}dk ${fark.inSeconds % 60}sn';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(e.ilac.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${e.ilac.isim} — ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ($farkStr sonra)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final tumIlaclar = profiller.expand((p) => p.ilaclar).toList();
              await BildirimServisi.tumBildirimleriYenile(tumIlaclar);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Tüm bildirimler yenilendi'),
                  duration: Duration(seconds: 2),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75)),
            child: const Text('Yenile',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _durumSatiri(String baslik, String deger) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(baslik,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
            Text(deger,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  void _premiumGoster() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumEkrani(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (profiller.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final navBarYuksekligi = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          _header(),
          _sekmeler(),
          Expanded(child: _ekran()),
          SizedBox(height: navBarYuksekligi), // navigation bar alanını boşalt
        ],
      ),
      floatingActionButton: _secilenSekme == 0 || _secilenSekme == 1
          ? FloatingActionButton(
              onPressed: _ilacEkleDialogAc,
              backgroundColor: const Color(0xFF1D9E75),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _ekran() {
    switch (_secilenSekme) {
      case 0:
        return BugunEkrani(ilaclar: ilaclar, onAlindiToggle: _alindiToggle);
      case 1:
        return TumIlaclarEkrani(
          ilaclar: ilaclar,
          onSil: _ilacSil,
          onDuzenle: _ilacDuzenle,
        );
      case 2:
        return TakvimEkrani(ilaclar: ilaclar);
      case 3:
        return IstatistikEkrani(ilaclar: ilaclar);
      default:
        return const SizedBox();
    }
  }

  Widget _header() {
    final statusBarYuksekligi = MediaQuery.of(context).padding.top;
    return Container(
      color: const Color(0xFF1D9E75),
      padding: EdgeInsets.fromLTRB(20, statusBarYuksekligi + 12, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Merhaba 👋',
                      style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(secilenProfil.isim,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _premiumGoster,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('⭐ Premium · Yakında',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _tanilamaDialogGoster,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...profiller.asMap().entries.map((e) {
                  final secili = e.key == secilenProfilIndex;
                  return GestureDetector(
                    onTap: () => setState(() => secilenProfilIndex = e.key),
                    onLongPress: () => _profilSecenekler(e.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: secili ? Colors.white : Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${e.value.emoji} ${e.value.isim}',
                        style: TextStyle(
                          fontSize: 13,
                          color: secili ? const Color(0xFF1D9E75) : Colors.white,
                          fontWeight: secili ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _profilEkle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('+ Profil',
                        style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _sekmeler() {
    const sekmeler = ['Bugün', 'İlaçlar', 'Takvim', 'İstatistik'];
    return Container(
      color: const Color(0xFF1D9E75),
      child: Row(
        children: List.generate(sekmeler.length, (i) {
          final secili = _secilenSekme == i;
          return GestureDetector(
            onTap: () => setState(() => _secilenSekme = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: secili ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                sekmeler[i],
                style: TextStyle(
                  color: secili ? Colors.white : Colors.white.withValues(alpha:0.6),
                  fontWeight: secili ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _ilacEkleDialogAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => IlacEkleDialog(onKaydet: _ilacEkle),
    );
  }
}