import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/ilac.dart';

final FlutterLocalNotificationsPlugin bildirimPlugin =
    FlutterLocalNotificationsPlugin();

class BildirimServisi {
  // Bir ilaca ayrılan bildirim ID aralığı: [bildirimId, bildirimId + _gunSayisi)
  // Son slot (_gunSayisi) stok uyarısı için ayrılmıştır.
  // 7 gün × 4 hafta = 28 slot + 1 stok slotu = 29 toplam
  static const int _gunSayisi = 28;

  static const _bataryaKanali = MethodChannel('com.app.ilactakibim/battery');

  static const _ilacKanali = AndroidNotificationDetails(
    'ilac_kanal',
    'İlaç Hatırlatıcı',
    channelDescription: 'İlaç alma zamanı bildirimleri',
    importance: Importance.max,
    priority: Priority.max,
  );

  static const _stokKanali = AndroidNotificationDetails(
    'stok_kanal',
    'Stok Uyarısı',
    channelDescription: 'İlaç stok uyarıları',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidAyarlar =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings ayarlar =
        InitializationSettings(android: androidAyarlar);
    await bildirimPlugin.initialize(ayarlar);
  }

  static Future<void> requestIzinler() async {
    final androidPlugin = bildirimPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    await androidPlugin.requestNotificationsPermission();
    await androidPlugin.requestExactAlarmsPermission();
  }

  static Future<void> bildirimAyarla(Ilac ilac) async {
    try {
      await _iptalEt(ilac);

      final parcalar = ilac.saat.split(':');
      final saatInt = int.parse(parcalar[0]);
      final dakikaInt = int.parse(parcalar[1]);
      final now = tz.TZDateTime.now(tz.local);

      // matchDateTimeComponents yerine her gün için önümüzdeki 4 haftayı
      // tek tek zamanla — alarmClock modu ile %100 güvenilir.
      int slot = 0;
      for (final gun in ilac.gunler) {
        var ilkTekrar = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, saatInt, dakikaInt);
        while (ilkTekrar.weekday != gun || !ilkTekrar.isAfter(now)) {
          ilkTekrar = ilkTekrar.add(const Duration(days: 1));
        }
        for (int hafta = 0; hafta < 4; hafta++) {
          await bildirimPlugin.zonedSchedule(
            ilac.bildirimId + slot,
            '💊 İlaç Zamanı!',
            '${ilac.isim} alma vakti geldi — ${ilac.doz}',
            ilkTekrar.add(Duration(days: hafta * 7)),
            const NotificationDetails(android: _ilacKanali),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          slot++;
        }
      }
    } catch (e) {
      debugPrint('BildirimServisi.bildirimAyarla hatası: $e');
    }
  }

  static Future<void> tumBildirimleriYenile(List<Ilac> ilaclar) async {
    await bildirimPlugin.cancelAll();
    for (final ilac in ilaclar) {
      await bildirimAyarla(ilac);
    }
  }

  static Future<void> iptalEt(Ilac ilac) => _iptalEt(ilac);

  static Future<void> stokBildirimi(Ilac ilac) async {
    try {
      await bildirimPlugin.show(
        ilac.bildirimId + _gunSayisi,
        '⚠️ Stok Azalıyor!',
        '${ilac.isim} için sadece ${ilac.stok} adet kaldı',
        const NotificationDetails(android: _stokKanali),
      );
    } catch (e) {
      debugPrint('BildirimServisi.stokBildirimi hatası: $e');
    }
  }

  static Future<bool> alarmIzniVarMi() async {
    final androidPlugin = bildirimPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    final bildirimAcik = await androidPlugin.areNotificationsEnabled() ?? true;
    final exactAlarmAcik =
        await androidPlugin.canScheduleExactNotifications() ?? true;
    return bildirimAcik && exactAlarmAcik;
  }

  static Future<void> alarmAyarlariniAc() async {
    final androidPlugin = bildirimPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Pil optimizasyonu aktifse true döner (bildirimler gecikebilir).
  static Future<bool> pilOptimizasyonuAktifMi() async {
    try {
      final ignore = await _bataryaKanali
          .invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? true;
      return !ignore; // ignore=false → optimizasyon aktif → true döner
    } catch (_) {
      return false;
    }
  }

  /// Pil optimizasyonu muafiyet ekranını açar.
  static Future<void> pilOptimizasyonundanCikar() async {
    try {
      await _bataryaKanali.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  /// Anında bir test bildirimi + 10 sn sonrasına zamanlanmış bir test bildirimi gönderir.
  static Future<void> testBildirimiGonder() async {
    // 1) Anında bildirim — kanal/izin çalışıyor mu?
    await bildirimPlugin.show(
      999999,
      '🔔 Test (Anında)',
      'Bu bildirim hemen gönderildi — kanal çalışıyor.',
      const NotificationDetails(android: _stokKanali),
    );

    // 2) 10 sn sonrasına zamanlanmış — zonedSchedule çalışıyor mu?
    final zamani =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    try {
      await bildirimPlugin.zonedSchedule(
        999998,
        '⏰ Test (10 sn)',
        'Bu bildirim 10 saniye sonraya zamanlanmıştı.',
        zamani,
        const NotificationDetails(android: _ilacKanali),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('testBildirimiGonder zamanlama hatası: $e');
    }
  }

  static Future<void> _iptalEt(Ilac ilac) async {
    for (int i = 0; i <= _gunSayisi; i++) {
      await bildirimPlugin.cancel(ilac.bildirimId + i);
    }
  }
}
