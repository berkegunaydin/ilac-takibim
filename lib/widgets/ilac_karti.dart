import 'package:flutter/material.dart';
import '../models/ilac.dart';

class IlacKarti extends StatelessWidget {
  final Ilac ilac;
  final bool bugunModu;
  final VoidCallback? onAlindiToggle;
  final VoidCallback? onSil;
  final VoidCallback? onDuzenle;

  const IlacKarti({
    super.key,
    required this.ilac,
    required this.bugunModu,
    this.onAlindiToggle,
    this.onSil,
    this.onDuzenle,
  });

  String _gunIsmi(int gun) {
    const isimler = {
      1: 'Pzt', 2: 'Sal', 3: 'Çar',
      4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz'
    };
    return isimler[gun] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final saatParcalar = ilac.saat.split(':');
    final dakika = int.parse(saatParcalar[0]) * 60 + int.parse(saatParcalar[1]);
    Color renk = ilac.alindi
        ? const Color(0xFF1D9E75)
        : dakika <= 13 * 60
            ? const Color(0xFFFAC775)
            : const Color(0xFF85B7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: bugunModu ? 80 : 95,
                decoration: BoxDecoration(
                  color: renk,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(ilac.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ilac.isim, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(ilac.doz, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      bugunModu
                          ? '${ilac.saat} · ${ilac.alindi ? "✓ Alındı" : "Bekliyor"}'
                          : ilac.saat,
                      style: TextStyle(fontSize: 11, color: renk),
                    ),
                    if (!bugunModu)
                      Text(
                        ilac.gunler.length == 7 ? 'Her gün' : ilac.gunler.map(_gunIsmi).join(', '),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    if (ilac.stok > 0)
                      Text(
                        'Stok: ${ilac.stok} adet${ilac.stok <= ilac.stokUyariEsigi ? " ⚠️" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ilac.stok <= ilac.stokUyariEsigi ? Colors.orange : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (bugunModu)
                GestureDetector(
                  onTap: onAlindiToggle,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: ilac.alindi ? const Color(0xFFE1F5EE) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                    ),
                    child: Icon(
                      ilac.alindi ? Icons.check : Icons.circle_outlined,
                      color: ilac.alindi ? const Color(0xFF1D9E75) : Colors.grey,
                      size: 20,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    IconButton(
                      onPressed: onDuzenle,
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                    ),
                    IconButton(
                      onPressed: onSil,
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}