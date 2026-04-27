import 'package:google_mobile_ads/google_mobile_ads.dart';

class ReklamServisi {
  // Gerçek ID'leri AdMob hesabından alınca buraya yaz
  static const String _interstitialId =
      'ca-app-pub-3940256099942544/1033173712'; // Test ID

  static InterstitialAd? _ad;
  static int _ilacEklenmeSayisi = 0;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _yukle();
  }

  static void _yukle() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              _yukle(); // bir sonraki için hazırla
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _ad = null;
              _yukle();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _ad = null;
        },
      ),
    );
  }

  static void ilacEklendi() {
    _ilacEklenmeSayisi++;
    if (_ilacEklenmeSayisi % 2 == 0) {
      goster();
    }
  }

  static void goster() {
    _ad?.show();
  }
}
