import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/ilac.dart';

final FlutterLocalNotificationsPlugin bildirimPlugin =
    FlutterLocalNotificationsPlugin();

class BildirimServisi {
  // Slot düzeni: 0-6 ana alarm, 7-13 takip alarmı, 14 stok uyarısı
  static const int _gunSayisi = 14;
  static String? sonHata;

  static const _bataryaKanali = MethodChannel('com.app.ilactakibim/battery');
  static const _alarmKanali  = MethodChannel('com.app.ilactakibim/alarm');

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

  /// Bildirimleri zamanlar; zamanlanabilen ana bildirim sayısını döner.
  static Future<int> bildirimAyarla(Ilac ilac) async {
    int zamanlanan = 0;
    try {
      await _iptalEt(ilac);

      final parcalar = ilac.saat.split(':');
      final saatInt = int.parse(parcalar[0]);
      final dakikaInt = int.parse(parcalar[1]);
      final now = tz.TZDateTime.now(tz.local);
      final bugun = DateTime.now().toIso8601String().substring(0, 10);

      int slot = 0;
      for (int i = 0; i < 7; i++) {
        final hedef = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, saatInt, dakikaInt)
            .add(Duration(days: i));
        if (!ilac.gunler.contains(hedef.weekday)) continue;

        // Ana alarm — bildirimOnce dakika önce
        final anaTetik = hedef.subtract(Duration(minutes: ilac.bildirimOnce));
        if (anaTetik.isAfter(now)) {
          final baslik = ilac.bildirimOnce == 0
              ? '💊 İlaç Zamanı!'
              : '💊 ${ilac.bildirimOnce} dakika kaldı!';
          await _alarmKanali.invokeMethod('schedule', {
            'id':        ilac.bildirimId + slot,
            'triggerMs': anaTetik.millisecondsSinceEpoch,
            'title':     baslik,
            'body':      '${ilac.isim} alma vakti — ${ilac.doz}',
          });
          zamanlanan++;
        }

        // Takip alarmı — 1 saat sonra, bugün alınmadıysa
        final takipTetik = hedef.add(const Duration(hours: 1));
        if (takipTetik.isAfter(now)) {
          final hedefTarih =
              '${hedef.year}-${hedef.month.toString().padLeft(2, '0')}-${hedef.day.toString().padLeft(2, '0')}';
          final bugunAlindi = hedefTarih == bugun && ilac.sonAlinmaTarihi == bugun;
          if (!bugunAlindi) {
            await _alarmKanali.invokeMethod('schedule', {
              'id':        ilac.bildirimId + 7 + slot,
              'triggerMs': takipTetik.millisecondsSinceEpoch,
              'title':     '⏰ Hatırlatma!',
              'body':      '${ilac.isim} almayı unutmayın — ${ilac.doz}',
            });
          }
        }

        slot++;
      }
    } catch (e) {
      sonHata = 'bildirimAyarla: $e';
      debugPrint('BildirimServisi.bildirimAyarla hatası: $e');
    }
    return zamanlanan;
  }

  static Future<void> tumBildirimleriYenile(List<Ilac> ilaclar) async {
    await bildirimPlugin.cancelAll();
    for (final ilac in ilaclar) {
      await bildirimAyarla(ilac); // dönüş değeri burada kullanılmıyor
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

  /// Anında bir test bildirimi + [saniye] sn sonrasına zamanlanmış test bildirimi gönderir.
  static Future<void> testBildirimiGonder({int saniye = 10}) async {
    await bildirimPlugin.show(
      999999,
      '🔔 Test (Anında)',
      'Bu bildirim hemen gönderildi — kanal çalışıyor.',
      const NotificationDetails(android: _stokKanali),
    );

    final zamani = tz.TZDateTime.now(tz.local).add(Duration(seconds: saniye));
    try {
      await bildirimPlugin.zonedSchedule(
        999998,
        '⏰ Test ($saniye sn)',
        'Bu bildirim $saniye saniye sonraya zamanlanmıştı.',
        zamani,
        const NotificationDetails(android: _ilacKanali),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      sonHata = 'testBildirimiGonder: $e';
      debugPrint('testBildirimiGonder zamanlama hatası: $e');
    }
  }

  /// İlacın önümüzdeki 7 günlük bildirim zamanlarını hesaplar (gerçekten zamanlamaz).
  static List<tz.TZDateTime> bildirimZamanlariHesapla(Ilac ilac) {
    final parcalar = ilac.saat.split(':');
    final saatInt = int.parse(parcalar[0]);
    final dakikaInt = int.parse(parcalar[1]);
    final now = tz.TZDateTime.now(tz.local);
    final zamanlari = <tz.TZDateTime>[];
    for (int i = 0; i < 7; i++) {
      final hedef = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, saatInt, dakikaInt)
          .add(Duration(days: i));
      if (!hedef.isAfter(now)) continue;
      if (!ilac.gunler.contains(hedef.weekday)) continue;
      zamanlari.add(now.add(hedef.difference(now)));
    }
    return zamanlari;
  }

  static Future<void> _iptalEt(Ilac ilac) async {
    for (int i = 0; i <= _gunSayisi; i++) {
      try {
        await _alarmKanali.invokeMethod('cancel', {'id': ilac.bildirimId + i});
      } catch (_) {}
      await bildirimPlugin.cancel(ilac.bildirimId + i);
    }
  }
}
