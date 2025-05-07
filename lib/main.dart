// lib/main.dart

// Temel Flutter ve Paket Importları
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase için
import 'package:flutter_bloc/flutter_bloc.dart'; // Bloc için
import 'package:flutter_timezone/flutter_timezone.dart';
// flutter_native_timezone yerine güncel paketi kullanın (eğer import hatası alıyorsanız)
// import 'package:flutter_native_timezone_updated_gradle/flutter_native_timezone.dart';
// Eski paketle devam ediyorsanız:
import 'package:intl/date_symbol_data_local.dart'; // Tarih formatlama için
import 'package:mindvault/features/journal/notifications/notification_service.dart';
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';
import 'package:mindvault/features/journal/subscription/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Kayıtlı tercihler için
import 'package:stacked_themes/stacked_themes.dart'; // Tema yönetimi için

// ***** YEREL BİLDİRİM İÇİN YENİ IMPORTLAR *****
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// **********************************************

// Proje İçi Importlar (Kendi dosya yollarınıza göre kontrol edin)
import 'package:mindvault/features/journal/bloc_auth/auth_service.dart';
import 'package:mindvault/firebase_options.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/features/journal/repository/mindvault_repository.dart';
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_bloc.dart';
import 'package:mindvault/features/journal/screens/home/main_screen.dart';
import 'package:mindvault/features/journal/screens/home/onboarding_screen.dart';
import 'package:mindvault/features/journal/screens/settings/lock/lock_screen.dart';
// ***** NotificationService İÇİN YENİ IMPORT *****
// **********************************************

// ***** YEREL BİLDİRİM PLUGIN NESNESİ *****
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
// *****************************************

// ***** ARKA PLAN BİLDİRİM TIKLAMA İŞLEYİCİSİ *****
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (kDebugMode) {
    print('Arka Plan Bildirim Tıklaması: Payload: ${notificationResponse.payload}');
  }
  // TODO: Uygulama açılışında bu payload'ı işleyecek bir mekanizma kurun.
}
// **********************************************

Future<void> main() async {
  // Flutter binding'lerinin hazır olduğundan emin olun
  WidgetsFlutterBinding.ensureInitialized();
  // Tema yöneticisini başlat
  await ThemeManager.initialise();

  // Gerekli servisleri ve ayarları başlatma (try-catch bloğu içinde)
  MindVaultRepository? mindVaultRepository;
  AuthService? authService;
  bool onboardingComplete = false;

  try {
    // 1. Firebase Başlatma
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) print("Firebase Initialized.");

    // 2. Intl (Tarih/Zaman Formatlama) Başlatma
    await initializeDateFormatting('tr_TR', null);
    if (kDebugMode) print("Intl Initialized for tr_TR.");

    // ***** 3. YEREL BİLDİRİM SERVİSİNİ BAŞLATMA *****
    try {
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      if (kDebugMode) print("Timezone Initialized: $currentTimeZone");

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: null,
      );

      await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
          onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
            final String? payload = notificationResponse.payload;
            if (payload != null && kDebugMode) {
              if (kDebugMode) {
                print('Ön Plan Bildirim Tıklaması: Payload: $payload');
              }
            }
            // TODO: Payload'a göre uygulama içi yönlendirme veya işlem yapın.
          }
      );
      if (kDebugMode) { print("FlutterLocalNotificationsPlugin initialized for Android."); }
    } catch(e, s) {
      if (kDebugMode) {
        print("Yerel Bildirimler başlatılırken HATA oluştu: $e");
        print(s);
      }
    }
    // ***** BİLDİRİM BAŞLATMA SONU *****

    // 4. Onboarding Durumunu Kontrol Et
    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    if (kDebugMode) print("Onboarding Complete: $onboardingComplete");

    // 5. Repository ve Servisleri Oluştur/Başlat
    mindVaultRepository = MindVaultRepository();
    await mindVaultRepository.init(); // Hive vb. başlatılır
    authService = AuthService();
    if (kDebugMode) { print("Repository and AuthService Initialized."); }

    // 6. Uygulamayı Çalıştır (Provider'lar ile)
    runApp(
      MultiRepositoryProvider(
        providers: [
          // Mevcut Repository ve Servisler
          RepositoryProvider<MindVaultRepository>.value(value: mindVaultRepository),
          RepositoryProvider<AuthService>.value(value: authService),

          // ***** NotificationService SAĞLAYICISI EKLENDİ *****
          RepositoryProvider<NotificationService>(
            create: (_) => NotificationService(), // NotificationService nesnesi oluşturulup sağlanıyor
          ),
           RepositoryProvider<SubscriptionService>(
      create: (context) => SubscriptionService(prefs),
    ),
          // ***************************************************
        ],
        child: MultiBlocProvider(
          providers: [
            // JournalBloc
            BlocProvider<JournalBloc>(
              create: (context) => JournalBloc(
                repository: context.read<MindVaultRepository>(),
              )..add(const LoadJournalEntries()), // Başlangıçta günlükleri yükle
            ),
            // AuthBloc
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                authService: context.read<AuthService>(),
              ),
              lazy: false, // AuthBloc hemen başlasın
            ),

            BlocProvider<SubscriptionBloc>(
              create: (context) => SubscriptionBloc(
                // SubscriptionService'i RepositoryProvider'dan okuyun
                context.read<SubscriptionService>(),
              )..add(LoadSubscriptionStatus()), // Başlangıçta abonelik durumunu yükle
            ),
            ],
            child: MyApp(showOnboarding: !onboardingComplete),
      ),
    ),
  );
  } catch (error, stackTrace) {
    // Genel Başlatma Hatası
    if (kDebugMode) {
      print("Uygulama Başlatılırken KRİTİK HATA: $error");
      print(stackTrace);
    }
    await mindVaultRepository?.close();
    runApp(InitializationErrorScreen(error: error));
  }
}

/// Ana Uygulama Widget'ı
class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      themes: ThemeConfig.materialThemes,
      builder: (context, regularTheme, darkTheme, themeMode) {
        return MaterialApp(
          title: 'Mind Vault',
          debugShowCheckedModeBanner: false,
          theme: regularTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: HomeGate(showOnboarding: showOnboarding),
        );
      },
    );
  }
}

/// Yönlendirme Widget'ı
class HomeGate extends StatelessWidget {
  final bool showOnboarding;
  const HomeGate({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    if (showOnboarding) {
      return const OnboardingScreen();
    } else {
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthInProgress) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (state is AuthLocked || state is AuthFailure) {
            return const LockScreen();
          } else if (state is AuthUnlocked || state is AuthSetupRequired) {
            return const MainScreen();
          } else {
            return const Scaffold(body: Center(child: Text("Beklenmedik bir kimlik durumu!")));
          }
        },
      );
    }
  }
}

/// Başlatma Hatası Ekranı
class InitializationErrorScreen extends StatelessWidget {
  final Object error;
  const InitializationErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Uygulama Başlatılamadı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Kritik bir hata oluştu ve uygulama açılamıyor. Lütfen daha sonra tekrar deneyin veya geliştirici ile iletişime geçin.\n\nHata: ${error.toString()}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}