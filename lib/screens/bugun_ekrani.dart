import 'package:flutter/material.dart';
import '../models/ilac.dart';
import '../widgets/ilac_karti.dart';

class BugunEkrani extends StatelessWidget {
  final List<Ilac> ilaclar;
  final Function(Ilac) onAlindiToggle;

  const BugunEkrani({
    super.key,
    required this.ilaclar,
    required this.onAlindiToggle,
  });

  List<Ilac> get bugunIlaclar {
    final bugunGun = DateTime.now().weekday;
    return ilaclar.where((i) => i.gunler.contains(bugunGun)).toList()
      ..sort((a, b) => a.saat.compareTo(b.saat));
  }

  int get alinanSayisi => bugunIlaclar.where((i) => i.alindi).length;

  @override
  Widget build(BuildContext context) {
    final tamamlanma = bugunIlaclar.isEmpty ? 0.0 : alinanSayisi / bugunIlaclar.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bugün', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Text(
                bugunIlaclar.isEmpty
                    ? 'Bugün ilaç yok 🎉'
                    : '${bugunIlaclar.length} ilaçtan $alinanSayisi tanesi alındı',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (bugunIlaclar.isNotEmpty) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: tamamlanma,
                  backgroundColor: const Color(0xFFE8E8E8),
                  color: const Color(0xFF1D9E75),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  '%${(tamamlanma * 100).toInt()} tamamlandı',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (bugunIlaclar.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Bugün alınacak ilaç yok!', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...bugunIlaclar.map((ilac) => IlacKarti(
                ilac: ilac,
                bugunModu: true,
                onAlindiToggle: () => onAlindiToggle(ilac),
              )),
      ],
    );
  }
}