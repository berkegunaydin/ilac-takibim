import 'package:flutter/material.dart';
import '../models/ilac.dart';
import '../data/ilac_veritabani.dart';

class IlacEkleDialog extends StatefulWidget {
  final Ilac? duzenlenecekIlac;
  final Function(String isim, String doz, String saat, String emoji,
      List<int> gunler, int stok, int stokUyariEsigi, int bildirimOnce) onKaydet;

  const IlacEkleDialog({
    super.key,
    this.duzenlenecekIlac,
    required this.onKaydet,
  });

  @override
  State<IlacEkleDialog> createState() => _IlacEkleDialogState();
}

class _IlacEkleDialogState extends State<IlacEkleDialog> {
  late TextEditingController isimController;
  late String secilenEmoji;
  late String secilenBirim;
  late String secilenMiktar;
  late String secilenGuc;
  late int secilenStok;
  late String secilenBildirimZamani;
  TimeOfDay? secilenSaat;
  late String saatText;
  late List<int> secilenGunler;
  List<String> oneri = [];

  static const _birimler = ['Tablet', 'Kapsül', 'Damla', 'mL'];
  static const _miktarlar = ['½', '1', '2', '3'];
  static const _gucler = [
    '100mg', '200mg', '250mg', '400mg', '500mg', '750mg', '1000mg'
  ];
  static const _stoklar = [7, 10, 14, 21, 28, 30, 60, 90];
  static const _bildirimZamanlari = {
    'Zamanında': 0, '5 dk önce': 5, '15 dk önce': 15,
    '30 dk önce': 30, '1 sa önce': 60,
  };

  @override
  void initState() {
    super.initState();
    final ilac = widget.duzenlenecekIlac;
    isimController = TextEditingController(text: ilac?.isim ?? '');
    secilenEmoji = ilac?.emoji ?? '💊';
    saatText = ilac?.saat ?? 'Saat seç';
    secilenGunler =
        ilac != null ? List.from(ilac.gunler) : [1, 2, 3, 4, 5, 6, 7];

    if (ilac != null) {
      final doz = ilac.doz;
      secilenBirim =
          _birimler.firstWhere((b) => doz.contains(b), orElse: () => 'Tablet');
      secilenMiktar =
          _miktarlar.firstWhere((m) => doz.startsWith(m), orElse: () => '1');
      final gucMatch = RegExp(r'\d+mg').firstMatch(doz);
      final guc = gucMatch?.group(0) ?? '500mg';
      secilenGuc = _gucler.contains(guc) ? guc : '500mg';
      secilenStok = _stoklar.contains(ilac.stok) ? ilac.stok : 30;

      final parcalar = ilac.saat.split(':');
      secilenSaat = TimeOfDay(
        hour: int.parse(parcalar[0]),
        minute: int.parse(parcalar[1]),
      );
      secilenBildirimZamani = _bildirimZamanlari.entries
          .firstWhere((e) => e.value == (ilac.bildirimOnce),
              orElse: () => _bildirimZamanlari.entries.first)
          .key;
    } else {
      secilenBirim = 'Tablet';
      secilenMiktar = '1';
      secilenGuc = '500mg';
      secilenStok = 30;
      secilenBildirimZamani = 'Zamanında';
    }

    isimController.addListener(_oneriGuncelle);
  }

  void _oneriGuncelle() {
    final query = isimController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => oneri = []);
      return;
    }
    setState(() {
      oneri = ilacVeritabani
          .where((e) => e.toLowerCase().contains(query))
          .take(4)
          .toList();
    });
  }

  String get _dozString {
    final gucGoster = secilenBirim == 'Tablet' || secilenBirim == 'Kapsül';
    return '$secilenMiktar $secilenBirim${gucGoster ? ' · $secilenGuc' : ''}';
  }

  @override
  void dispose() {
    isimController.removeListener(_oneriGuncelle);
    isimController.dispose();
    super.dispose();
  }

  Widget _secimSatiri(
    String label,
    List<String> secenekler,
    String secilen,
    void Function(String) onSec,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: secenekler.map((o) {
            final aktif = secilen == o;
            return GestureDetector(
              onTap: () => setState(() => onSec(o)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: aktif
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: aktif
                        ? const Color(0xFF1D9E75)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  o,
                  style: TextStyle(
                    fontSize: 13,
                    color: aktif ? Colors.white : Colors.black87,
                    fontWeight:
                        aktif ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.duzenlenecekIlac == null ? 'Yeni İlaç Ekle' : 'İlacı Düzenle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['💊', '🧴', '💉', '🌿', '🍋']
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => secilenEmoji = e),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: secilenEmoji == e
                                ? const Color(0xFFE1F5EE)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: secilenEmoji == e
                                  ? const Color(0xFF1D9E75)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(e,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: isimController,
              decoration: const InputDecoration(
                labelText: 'İlaç / Takviye adı',
                border: OutlineInputBorder(),
              ),
            ),
            if (oneri.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Column(
                  children: oneri
                      .map((o) => ListTile(
                            dense: true,
                            title: Text(o,
                                style: const TextStyle(fontSize: 13)),
                            onTap: () {
                              isimController.text = o;
                              setState(() => oneri = []);
                            },
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 12),
            _secimSatiri(
                'Birim', _birimler, secilenBirim, (v) => secilenBirim = v),
            const SizedBox(height: 12),
            _secimSatiri('Doz miktarı', _miktarlar, secilenMiktar,
                (v) => secilenMiktar = v),
            if (secilenBirim == 'Tablet' || secilenBirim == 'Kapsül') ...[
              const SizedBox(height: 12),
              _secimSatiri(
                  'Güç', _gucler, secilenGuc, (v) => secilenGuc = v),
            ],
            const SizedBox(height: 12),
            _secimSatiri(
              'Stok adedi',
              _stoklar.map((s) => s.toString()).toList(),
              secilenStok.toString(),
              (v) => secilenStok = int.parse(v),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: secilenSaat ?? TimeOfDay.now(),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    secilenSaat = picked;
                    saatText =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      saatText,
                      style: TextStyle(
                        fontSize: 16,
                        color: secilenSaat == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    const Icon(Icons.access_time, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _secimSatiri(
              'Bildirim zamanı',
              _bildirimZamanlari.keys.toList(),
              secilenBildirimZamani,
              (v) => secilenBildirimZamani = v,
            ),
            const SizedBox(height: 10),
            const Text('Günler',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ['Pt', 1],
                ['Sa', 2],
                ['Ça', 3],
                ['Pe', 4],
                ['Cu', 5],
                ['Ct', 6],
                ['Pz', 7]
              ].map((g) {
                final label = g[0] as String;
                final gun = g[1] as int;
                final secili = secilenGunler.contains(gun);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (secili) {
                      secilenGunler.remove(gun);
                    } else {
                      secilenGunler.add(gun);
                    }
                  }),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: secili
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: secili
                            ? const Color(0xFF1D9E75)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secili ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isimController.text.isNotEmpty &&
                      secilenSaat != null) {
                    final stokUyariEsigi =
                        (secilenStok * 0.1).round().clamp(1, secilenStok);
                    widget.onKaydet(
                      isimController.text,
                      _dozString,
                      saatText,
                      secilenEmoji,
                      secilenGunler,
                      secilenStok,
                      stokUyariEsigi,
                      _bildirimZamanlari[secilenBildirimZamani] ?? 0,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kaydet'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
