// lib/core/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // TimeOfDay için gerekli
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
// main.dart içinde tanımladığımız global plugin nesnesine erişim için
// Projenizin dosya yapısına göre bu yolun doğru olduğundan emin olun:
import 'package:mindvault/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Android'de yerel bildirimleri yönetmek için servis sınıfı.
///
/// Kullanım:
/// 1. `main.dart` içinde `RepositoryProvider` ile sağlayın.
/// 2. Widget'larda `context.read<NotificationService>()` ile erişin.
/// 3. Gerekli metotları (izin isteme, planlama, iptal etme) çağırın.
class NotificationService {
  // main.dart'ta başlatılan global plugin örneğini kullanır
  final FlutterLocalNotificationsPlugin _plugin = flutterLocalNotificationsPlugin;

  // --- Bildirim Kanalları (Android 8.0+ için) ---
  // Kullanıcıların ayarlardan bildirim türlerini yönetebilmesi için kanallar önemlidir.
  static const String _dailyReminderChannelId = 'mindvault_daily_reminder_channel';
  static const String _dailyReminderChannelName = 'Günlük Hatırlatıcı';
  static const String _dailyReminderChannelDesc = 'Günlük yazma hatırlatıcı bildirimleri.';

  static const String _inactivityChannelId = 'mindvault_inactivity_channel';
  static const String _inactivityChannelName = 'Etkinlik Hatırlatıcı';
  static const String _inactivityChannelDesc = 'Uygulama kullanımını teşvik eden hatırlatıcılar.';

  // --- Bildirim ID'leri ---
  // Farklı bildirim türlerini yönetmek (iptal etmek vb.) için benzersiz ID'ler kullanılır.
  static const int dailyReminderId = 0;
  static const int inactivityReminderId = 1;

  // --- Android Bildirim Stilleri/Detayları ---
  // Her kanal için varsayılan görünüm ayarları.
  static const AndroidNotificationDetails _dailyReminderDetails =
  AndroidNotificationDetails(
    _dailyReminderChannelId,
    _dailyReminderChannelName,
    channelDescription: _dailyReminderChannelDesc,
    importance: Importance.max, // Bildirimin görünürlüğü ve sesi için yüksek öncelik
    priority: Priority.high,
    ticker: 'Mind Vault Hatırlatıcı', // Bildirim geldiğinde durum çubuğunda kısa süreli görünen metin
    // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Bildirimde büyük ikon (isteğe bağlı)
    // color: Colors.purple, // Bildirim ikonunun arka plan rengi (isteğe bağlı)
  );

  static const AndroidNotificationDetails _inactivityReminderDetails =
  AndroidNotificationDetails(
    _inactivityChannelId,
    _inactivityChannelName,
    channelDescription: _inactivityChannelDesc,
    importance: Importance.defaultImportance, // Daha standart öncelik
    priority: Priority.defaultPriority,
    ticker: 'Mind Vault',
  );

  // --- İzin İsteme ---

  /// Android 13 ve üzeri için bildirim iznini ve tam zamanlama iznini ister.
  /// Kullanıcıdan izin istemeden önce nedenini açıklamak iyi bir pratiktir.
  /// Returns `true` if both permissions are granted, `false` otherwise.
  Future<bool> requestAndroidPermissions() async {
    bool notificationGranted = false;
    bool exactAlarmGranted = false;

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) {
        if (kDebugMode) print("Android bildirim implementasyonu bulunamadı.");
        return false;
      }

      // Önce bildirim iznini iste (Android 13+)
      notificationGranted = await androidPlugin.requestNotificationsPermission() ?? false;

      // Sonra tam zamanlama iznini iste (Android 12+)
      exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission() ?? false;

      if (kDebugMode) {
        print("Android Bildirim İzni: $notificationGranted");
        print("Android Tam Zamanlama İzni: $exactAlarmGranted");
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("Android izinleri istenirken HATA: $e");
        print(s);
      }
      // Hata durumunda izinlerin verilmediğini varsayalım
      notificationGranted = false;
      exactAlarmGranted = false;
    }
    // Zamanlanmış bildirimler için her ikisinin de verilmesi genellikle gereklidir.
    // Sadece anlık bildirimler için notificationGranted yeterli olabilir.
    return notificationGranted && exactAlarmGranted;
  }

  // --- Bildirim Planlama ---

  /// Her gün belirtilen saatte tekrarlayan günlük hatırlatıcıyı planlar.
  /// Varsa, önceki aynı ID'li hatırlatıcıyı iptal eder.
  Future<void> scheduleDailyReminder(TimeOfDay reminderTime, BuildContext context) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(reminderTime);

      await _plugin.zonedSchedule(
        dailyReminderId,
        l10n.notificationTitle,
        l10n.notificationBody,
        scheduledDate,
        const NotificationDetails(android: _dailyReminderDetails),
        payload: 'action_open_add_entry',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        print("Günlük hatırlatıcı planlandı: ID=$dailyReminderId, Saat=$reminderTime, İlk Zaman=${scheduledDate.toIso8601String()}");
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("Günlük hatırlatıcı planlanırken HATA: $e");
        print(s);
      }
    }
  }

  /// Belirtilen süre geçtikten sonra gösterilecek tek seferlik inaktivite hatırlatıcısını planlar.
  /// Varsa, önceki aynı ID'li hatırlatıcıyı iptal eder.
  Future<void> scheduleInactivityReminder(Duration afterDuration, BuildContext context) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(afterDuration);

      await _plugin.zonedSchedule(
        inactivityReminderId,
        l10n.notificationMissedTitle,
        l10n.notificationMissedBody,
        scheduledDate,
        const NotificationDetails(android: _inactivityReminderDetails),
        payload: 'action_open_app',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        print("İnaktivite hatırlatıcısı planlandı: ID=$inactivityReminderId, Zaman=${scheduledDate.toIso8601String()}");
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("İnaktivite hatırlatıcısı planlanırken HATA: $e");
        print(s);
      }
    }
  }

  // --- Bildirim İptal Etme ---

  /// Günlük hatırlatıcıyı iptal eder.
  Future<void> cancelDailyReminder() async {
    await _cancelNotificationById(dailyReminderId, "Günlük");
  }

  /// İnaktivite hatırlatıcısını iptal eder.
  Future<void> cancelInactivityReminder() async {
    await _cancelNotificationById(inactivityReminderId, "İnaktivite");
  }

  /// Belirtilen ID'ye sahip bildirimi iptal etmek için özel yardımcı metot.
  Future<void> _cancelNotificationById(int id, String typeForLog) async {
    try {
      await _plugin.cancel(id);
      if (kDebugMode) {
        print("$typeForLog hatırlatıcısı (ID=$id) iptal edildi.");
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("$typeForLog hatırlatıcısı (ID=$id) iptal edilirken HATA: $e");
        print(s);
      }
    }
  }

  /// Tüm planlanmış bildirimleri iptal eder.
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      if (kDebugMode) {
        print("Tüm planlanmış bildirimler iptal edildi.");
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("Tüm bildirimler iptal edilirken HATA: $e");
        print(s);
      }
    }
  }

  // --- Kontrol Metotları ---

  /// Belirtilen ID'ye sahip bir bildirimin planlanmış (beklemede) olup olmadığını kontrol eder.
  Future<bool> isNotificationScheduled(int id) async {
    try {
      final List<PendingNotificationRequest> pendingRequests =
      await _plugin.pendingNotificationRequests();
      final bool isScheduled = pendingRequests.any((req) => req.id == id);
      if(kDebugMode){
        // print("Bekleyen bildirimler: ${pendingRequests.map((e) => 'ID: ${e.id}, Title: ${e.title}').toList()}");
        print("ID=$id için bildirim planlı mı? $isScheduled");
      }
      return isScheduled;
    } catch (e, s) {
      if (kDebugMode) {
        print("Bekleyen bildirimler kontrol edilirken HATA: $e");
        print(s);
      }
      return false;
    }
  }

  // --- Yardımcı Metotlar ---

  /// Verilen TimeOfDay için bir sonraki geçerli tarihi ve saati hesaplar.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    // Eğer hesaplanan saat şu andan önceyse veya çok yakınsa (örn. aynı dakika), bir sonraki güne ayarla
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}