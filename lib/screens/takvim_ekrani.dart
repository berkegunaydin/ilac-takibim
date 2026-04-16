import 'package:flutter/material.dart';
import '../models/ilac.dart';

class TakvimEkrani extends StatefulWidget {
  final List<Ilac> ilaclar;

  const TakvimEkrani({super.key, required this.ilaclar});

  @override
  State<TakvimEkrani> createState() => _TakvimEkraniState();
}

class _TakvimEkraniState extends State<TakvimEkrani> {
  DateTime secilenAy = DateTime.now();
  DateTime? secilenGun;

  List<Ilac> _gunIlaclar(DateTime gun) {
    final gunStr = gun.toIso8601String().substring(0, 10);
    return widget.ilaclar.where((ilac) {
      if (gunStr.compareTo(ilac.eklemeTarihi) < 0) return false;
      return ilac.gunler.contains(gun.weekday);
    }).toList();
  }

  bool _gunAlindi(DateTime gun) {
    final gunStr = gun.toIso8601String().substring(0, 10);
    final ilaclar = _gunIlaclar(gun);
    if (ilaclar.isEmpty) return false;
    return ilaclar.every((ilac) =>
        ilac.gecmis[gunStr] == true ||
        (ilac.sonAlinmaTarihi == gunStr && ilac.alindi));
  }

  bool _gunKismiAlindi(DateTime gun) {
    final gunStr = gun.toIso8601String().substring(0, 10);
    final ilaclar = _gunIlaclar(gun);
    if (ilaclar.isEmpty) return false;
    return ilaclar.any((ilac) =>
        ilac.gecmis[gunStr] == true ||
        (ilac.sonAlinmaTarihi == gunStr && ilac.alindi));
  }

  @override
  Widget build(BuildContext context) {
    final ilkGun = DateTime(secilenAy.year, secilenAy.month, 1);
    final sonGun = DateTime(secilenAy.year, secilenAy.month + 1, 0);
    final bosluk = ilkGun.weekday - 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => secilenAy =
                  DateTime(secilenAy.year, secilenAy.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_ayIsmi(secilenAy.month)} ${secilenAy.year}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () => setState(() => secilenAy =
                  DateTime(secilenAy.year, secilenAy.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 7,
          itemBuilder: (context, i) {
            const gunler = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
            return Center(
              child: Text(gunler[i],
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
            );
          },
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: bosluk + sonGun.day,
          itemBuilder: (context, i) {
            if (i < bosluk) return const SizedBox();
            final gun =
                DateTime(secilenAy.year, secilenAy.month, i - bosluk + 1);
            final bugun = DateTime.now();
            final bugunMu = gun.year == bugun.year &&
                gun.month == bugun.month &&
                gun.day == bugun.day;
            final alindi = _gunAlindi(gun);
            final kismiAlindi = _gunKismiAlindi(gun);
            final gelecek = gun.isAfter(bugun);

            return GestureDetector(
              onTap: () => setState(() => secilenGun = gun),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: alindi
                      ? const Color(0xFF1D9E75)
                      : kismiAlindi
                          ? const Color(0xFFE1F5EE)
                          : bugunMu
                              ? const Color(0xFFE6F1FB)
                              : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: bugunMu
                      ? Border.all(
                          color: const Color(0xFF378ADD), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${gun.day}',
                    style: TextStyle(
                      fontSize: 13,
                      color: alindi
                          ? Colors.white
                          : gelecek
                              ? Colors.grey.withValues(alpha:0.4)
                              : Colors.black87,
                      fontWeight:
                          bugunMu ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (secilenGun != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '${secilenGun!.day} ${_ayIsmi(secilenGun!.month)}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._gunIlaclar(secilenGun!).map((ilac) {
            final gunStr =
                secilenGun!.toIso8601String().substring(0, 10);
            final alindi = ilac.gecmis[gunStr] == true ||
                (ilac.sonAlinmaTarihi == gunStr && ilac.alindi);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFE8E8E8), width: 0.5),
              ),
              child: Row(
                children: [
                  Text(ilac.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ilac.isim,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text(ilac.saat,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(
                    alindi ? Icons.check_circle : Icons.cancel_outlined,
                    color: alindi
                        ? const Color(0xFF1D9E75)
                        : Colors.redAccent,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _ayIsmi(int ay) {
    const aylar = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return aylar[ay];
  }
}