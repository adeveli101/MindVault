// lib/features/settings/screens/notification/settings_notification_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/notifications/notification_service.dart';
// Servis, Tema ve Provider importları (Yolları kontrol edin)
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsNotificationScreen extends StatefulWidget {
  const SettingsNotificationScreen({super.key});

  @override
  State<SettingsNotificationScreen> createState() =>
      _SettingsNotificationScreenState();
}

class _SettingsNotificationScreenState extends State<SettingsNotificationScreen> {
  // --- SharedPreferences Anahtarları ---
  // Sadece günlük hatırlatıcı ile ilgili anahtarlar kaldı
  static const String _prefsKeyReminderEnabled = 'reminder_enabled_v3'; // Yeni versiyon
  static const String _prefsKeyReminderHour = 'reminder_hour_v3';
  static const String _prefsKeyReminderMinute = 'reminder_minute_v3';
  // İnaktivite anahtarı kaldırıldı

  // --- State Değişkenleri ---
  bool _isLoading = true;
  bool _permissionsGranted = false; // Bildirim izinlerinin durumunu tutar
  bool _dailyReminderEnabled = false;
  TimeOfDay? _selectedTime;

  // --- Servis Referansı ---
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = context.read<NotificationService>();
    _initializeSettings(); // Ayarları ve izin durumunu yükle
  }

  /// Ayarları ve izin durumunu yükler/kontrol eder.
  Future<void> _initializeSettings() async {
    setState(() => _isLoading = true);
    try {
      // Önce izin durumunu kontrol et (servise bir metot eklenebilir veya burada yapılır)
      // Şimdilik basitlik adına, doğrudan izin isteme fonksiyonunun sonucuna bakalım.
      // Gerçek uygulamada, mevcut izin durumunu kontrol eden bir metot daha iyi olabilir.
      // Bu örnekte, izin isteğini _askForPermissions içinde yapacağız.
      // Başlangıçta izin verilmiş varsaymıyoruz, kontrolü kullanıcı etkileşimine bırakıyoruz.
      // _permissionsGranted = await _checkPermissions(); // Varsayımsal kontrol metodu

      final prefs = await SharedPreferences.getInstance();
      // ignore: unused_local_variable
      final reminderEnabled = prefs.getBool(_prefsKeyReminderEnabled) ?? false;
      final hour = prefs.getInt(_prefsKeyReminderHour);
      final minute = prefs.getInt(_prefsKeyReminderMinute);

      TimeOfDay? loadedTime;
      if (hour != null && minute != null) {
        loadedTime = TimeOfDay(hour: hour, minute: minute);
      }

      // State'i güncelle (izin durumu başlangıçta false)
      if (mounted) {
        setState(() {
          // Eğer ayarlarda hatırlatıcı açıksa ama izin durumu bilinmiyorsa,
          // şimdilik kapalı başlatmak daha güvenli olabilir. İzin alınınca açılır.
          // Ya da izin durumunu başta kontrol eden bir mekanizma eklenmeli.
          // Bu örnekte, izin kontrolünü switch'e bırakıyoruz.
          // Başlangıçta _permissionsGranted = false olduğu için,
          // _dailyReminderEnabled'ı da false başlatmak mantıklı.
          // Kullanıcı switch'i açınca izin istenir ve gerekirse ayar yüklenir/korunur.
          // _dailyReminderEnabled = reminderEnabled; // Yerine false başlatıyoruz
          _selectedTime = loadedTime;
          _isLoading = false;
        });
      }

      // TODO: Eğer daha önce izin verilmişse ve hatırlatıcı açıksa,
      // planlanmış bildirimin hala var olup olmadığını kontrol edip
      // yoksa yeniden planlamak iyi olabilir (isNotificationScheduled ile).
      // Bu, _loadSettings içinde veya _askForPermissions sonrası yapılabilir.

    } catch (e, s) {
      if (kDebugMode) print("Ayarlar yüklenirken hata: $e\n$s");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Gerekli Android bildirim izinlerini ister ve state'i günceller.
  Future<bool> _askForPermissions() async {
    if (kDebugMode) print("Bildirim izinleri isteniyor...");
    final bool granted = await _notificationService.requestAndroidPermissions();
    if(mounted) {
      setState(() {
        _permissionsGranted = granted;
        // Eğer izin verilmediyse ve switch açıksa, switch'i kapat
        if(!granted && _dailyReminderEnabled) {
          _dailyReminderEnabled = false;
          _saveSettings(); // Kapalı durumu kaydet
          _notificationService.cancelDailyReminder(); // Planlanmışı iptal et
        }
      });
    }
    if (!granted) {
      _showSnackbar(AppLocalizations.of(context)!.notificationPermissionsRequired, isError: true);
    } else {
      if (kDebugMode) print("Bildirim izinleri verildi.");
    }
    return granted;
  }


  /// Kayıtlı ayarları SharedPreferences'a kaydeder.
  Future<void> _saveSettings() async {
    if (_isLoading) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Sadece günlük hatırlatıcı ayarlarını kaydet
      await prefs.setBool(_prefsKeyReminderEnabled, _dailyReminderEnabled && _permissionsGranted); // İzin yoksa kapalı kaydet
      if (_selectedTime != null) {
        await prefs.setInt(_prefsKeyReminderHour, _selectedTime!.hour);
        await prefs.setInt(_prefsKeyReminderMinute, _selectedTime!.minute);
      } else {
        await prefs.remove(_prefsKeyReminderHour);
        await prefs.remove(_prefsKeyReminderMinute);
      }
      if (kDebugMode) print("Ayarlar kaydedildi: Daily=$_dailyReminderEnabled, Time=$_selectedTime, Perm=$_permissionsGranted");
    } catch (e, s) {
      if (kDebugMode) print("Ayarlar kaydedilirken hata: $e\n$s");
      _showSnackbar(AppLocalizations.of(context)!.settingsSaveError, isError: true);
    }
  }

  /// Saat seçiciyi gösterir ve seçilen saati işler.
  Future<void> _pickTime() async {
    if (!_dailyReminderEnabled || !_permissionsGranted) return;

    final l10n = AppLocalizations.of(context)!;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: l10n.dailyReminderTime,
      builder: (context, child) => Theme(data: Theme.of(context), child: child!),
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() => _selectedTime = pickedTime);
      await _saveSettings();
      await _notificationService.scheduleDailyReminder(pickedTime, context);
      _showSnackbar(l10n.reminderTimeSet(pickedTime.format(context)));
    }
  }

  /// Günlük hatırlatıcı Switch durumu değiştiğinde çalışır.
  Future<void> _onDailyReminderEnabledChanged(bool newValue) async {
    setState(() => _dailyReminderEnabled = newValue);
    final l10n = AppLocalizations.of(context)!;

    if (newValue) {
      final bool permissionsOk = await _askForPermissions();
      if (!permissionsOk) {
        setState(() => _dailyReminderEnabled = false);
        await _saveSettings();
        return;
      }

      if (_selectedTime == null) {
        _showSnackbar(l10n.selectReminderTime);
        await _pickTime();
        if(_selectedTime == null && mounted) {
          setState(() => _dailyReminderEnabled = false);
          await _saveSettings();
          return;
        }
      } else {
        await _notificationService.scheduleDailyReminder(_selectedTime!, context);
        _showSnackbar(l10n.reminderEnabledMessage(_selectedTime!.format(context)));
      }
    } else {
      await _notificationService.cancelDailyReminder();
      _showSnackbar(l10n.reminderDisabledMessage);
    }
    await _saveSettings();
  }

  /// Ekranda kullanıcıya geri bildirim göstermek için SnackBar.
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        action: SnackBarAction(
          label: 'Kapat',
          textColor: isError ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onSecondaryContainer,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final String timeDisplay = _selectedTime?.format(context) ?? l10n.notSet;
    final bool canSetTime = _dailyReminderEnabled && _permissionsGranted;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.notificationSettings),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          children: [
            // --- Günlük Hatırlatıcı Bölümü ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(l10n.dailyReminder, style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
            ),
            SwitchListTile(
              title: Text(l10n.enableReminder),
              subtitle: Text(_dailyReminderEnabled
                  ? l10n.reminderEnabled
                  : l10n.reminderDisabled),
              value: _dailyReminderEnabled,
              onChanged: _onDailyReminderEnabledChanged, // Yeni mantıkla çalışır
              activeColor: colorScheme.primary,
              secondary: Icon(
                _dailyReminderEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                color: _dailyReminderEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            ),
            ListTile(
              leading: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.access_time_outlined,
                  // Sadece switch açık ve izin varsa renkli göster
                  color: canSetTime ? colorScheme.secondary : colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
              ),
              title: Text(l10n.reminderTime),
              subtitle: Text(timeDisplay),
              // Sadece switch açık ve izin varsa tıklanabilir ve renkli göster
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: canSetTime ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withOpacity(0.4)),
              enabled: canSetTime, // Tıklanabilirlik durumu
              onTap: canSetTime ? _pickTime : null, // Tıklama olayı
              contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
              minLeadingWidth: 10,
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),

            // --- İzin Bilgisi ve Butonu (Opsiyonel ama önerilir) ---
            ListTile(
              leading: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  _permissionsGranted ? Icons.check_circle_outline : Icons.notification_important_outlined,
                  color: _permissionsGranted ? Colors.green.shade600 : colorScheme.error,
                ),
              ),
              minLeadingWidth: 10,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
              title: Text(l10n.notificationPermissions, style: theme.textTheme.bodySmall),
              subtitle: Text(
                _permissionsGranted
                    ? l10n.permissionsGranted
                    : l10n.permissionsRequired,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
              ),
              // Eğer izin verilmemişse, izin istemek için bir buton gösterilebilir
              trailing: !_permissionsGranted
                  ? TextButton(
                onPressed: _askForPermissions,
                child: Text(l10n.grantPermission),
              )
                  : null, // İzin varsa butona gerek yok
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),

            // İnaktivite hatırlatıcısı kaldırıldı.
          ],
        ),
      ),
    );
  }
}