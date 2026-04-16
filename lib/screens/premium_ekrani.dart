import 'package:flutter/material.dart';

class PremiumEkrani extends StatelessWidget {
  const PremiumEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        title: const Text('Premium'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('⭐', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Premium Yakında!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Şu an tüm özellikler ücretsiz',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            _ozellik('✅', 'Sınırsız ilaç ekle — Ücretsiz'),
            _ozellik('✅', 'Sınırsız profil (aile üyeleri) — Ücretsiz'),
            _ozellik('✅', 'Takvim ve istatistikler — Ücretsiz'),
            _ozellik('✅', 'Stok takibi ve uyarılar — Ücretsiz'),
            _ozellik('🔜', 'Reklamsız deneyim — Yakında'),
            _ozellik('🔜', 'Bulut yedekleme — Yakında'),
            _ozellik('🔜', 'Birden fazla cihaz desteği — Yakında'),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    'Erken kullanıcı avantajı',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D9E75)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Premium çıktığında erken kullanıcılara özel indirim sunulacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ozellik(String ikon, String metin) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(ikon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(metin, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
