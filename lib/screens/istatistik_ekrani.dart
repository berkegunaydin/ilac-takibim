import 'package:flutter/material.dart';
import '../models/ilac.dart';

class IstatistikEkrani extends StatelessWidget {
  final List<Ilac> ilaclar;

  const IstatistikEkrani({super.key, required this.ilaclar});

  double _duzenlilikYuzdesi(Ilac ilac) {
    if (ilac.gecmis.isEmpty) return 0;
    final alinan = ilac.gecmis.values.where((v) => v).length;
    return alinan / ilac.gecmis.length * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (ilaclar.isEmpty) {
      return const Center(
        child: Text('Henüz ilaç eklenmedi',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final toplamGecmis = ilaclar
        .expand((i) => i.gecmis.values)
        .toList();
    final toplamAlindi = toplamGecmis.where((v) => v).length;
    final genelYuzde = toplamGecmis.isEmpty
        ? 0.0
        : toplamAlindi / toplamGecmis.length * 100;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Genel Uyum',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '%${genelYuzde.toInt()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: genelYuzde / 100,
                backgroundColor: Colors.white.withValues(alpha:0.3),
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('İlaç Bazında',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 10),
        ...ilaclar.map((ilac) {
          final yuzde = _duzenlilikYuzdesi(ilac);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ilac.emoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(ilac.isim,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      '%${yuzde.toInt()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: yuzde >= 80
                            ? const Color(0xFF1D9E75)
                            : yuzde >= 50
                                ? const Color(0xFFBA7517)
                                : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: yuzde / 100,
                  backgroundColor: const Color(0xFFE8E8E8),
                  color: yuzde >= 80
                      ? const Color(0xFF1D9E75)
                      : yuzde >= 50
                          ? const Color(0xFFFAC775)
                          : Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  ilac.gecmis.isEmpty
                      ? 'Henüz veri yok'
                      : '${ilac.gecmis.values.where((v) => v).length}/${ilac.gecmis.length} gün alındı',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}