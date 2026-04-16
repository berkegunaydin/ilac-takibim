import 'package:flutter/material.dart';
import '../models/ilac.dart';
import '../widgets/ilac_karti.dart';
import '../widgets/ilac_ekle_dialog.dart';

class TumIlaclarEkrani extends StatelessWidget {
  final List<Ilac> ilaclar;
  final Function(Ilac) onSil;
  final Function(Ilac, String, String, String, String, List<int>, int, int) onDuzenle;

  const TumIlaclarEkrani({
    super.key,
    required this.ilaclar,
    required this.onSil,
    required this.onDuzenle,
  });

  @override
  Widget build(BuildContext context) {
    return ilaclar.isEmpty
        ? const Center(
            child: Text(
              'Henüz ilaç eklenmedi\n"+" butonuna bas!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Tüm İlaçlar', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              ...ilaclar.map((ilac) => IlacKarti(
                    ilac: ilac,
                    bugunModu: false,
                    onSil: () => onSil(ilac),
                    onDuzenle: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => IlacEkleDialog(
                          duzenlenecekIlac: ilac,
                          onKaydet: (isim, doz, saat, emoji, gunler, stok, stokUyariEsigi) =>
                              onDuzenle(ilac, isim, doz, saat, emoji, gunler, stok, stokUyariEsigi),
                        ),
                      );
                    },
                  )),
            ],
          );
  }
}