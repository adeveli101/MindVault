// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked_themes/stacked_themes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:mindvault/features/journal/providers/locale_provider.dart';

import 'package:mindvault/features/journal/bloc_auth/rate_limiter.dart';
import 'package:mindvault/features/journal/notifications/notification_service.dart';
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';
import 'package:mindvault/features/journal/subscription/subscription_service.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_service.dart';
import 'package:mindvault/firebase_options.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/features/journal/repository/mindvault_repository.dart';
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_bloc.dart';
import 'package:mindvault/features/journal/screens/home/main_screen.dart';
import 'package:mindvault/features/journal/screens/settings/lock/lock_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (kDebugMode) {
    print('Arka Plan Bildirim Tıklaması: Payload: ${notificationResponse.payload}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialise();

  MindVaultRepository? mindVaultRepository;
  AuthService? authService;
  bool onboardingComplete = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) print("Firebase Initialized.");

    await initializeDateFormatting('tr_TR', null);
    if (kDebugMode) print("Intl Initialized for tr_TR.");

    try {
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      if (kDebugMode) print("Timezone Initialized: $currentTimeZone");

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

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
        }
      );
      if (kDebugMode) print("FlutterLocalNotificationsPlugin initialized for Android.");
    } catch(e, s) {
      if (kDebugMode) {
        print("Yerel Bildirimler başlatılırken HATA oluştu: $e");
        print(s);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    if (kDebugMode) print("Onboarding Complete: $onboardingComplete");

    mindVaultRepository = MindVaultRepository();
    await mindVaultRepository.init();

    final rateLimiter = RateLimiter(prefs);
    authService = AuthService(rateLimiter: rateLimiter);
    if (kDebugMode) print("Repository and AuthService Initialized.");

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => LocaleProvider(prefs),
          ),
          RepositoryProvider<MindVaultRepository>.value(value: mindVaultRepository),
          RepositoryProvider<AuthService>.value(value: authService),
          RepositoryProvider<NotificationService>(create: (_) => NotificationService()),
          RepositoryProvider<SubscriptionService>(create: (context) => SubscriptionService(prefs)),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<JournalBloc>(
              create: (context) => JournalBloc(
                repository: context.read<MindVaultRepository>(),
              )..add(const LoadJournalEntries()),
            ),
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                authService: context.read<AuthService>(),
              ),
              lazy: false,
            ),
            BlocProvider<SubscriptionBloc>(
              create: (context) => SubscriptionBloc(
                context.read<SubscriptionService>(),
              )..add(LoadSubscriptionStatus()),
            ),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      print("Uygulama Başlatılırken KRİTİK HATA: $error");
      print(stackTrace);
    }
    await mindVaultRepository?.close();
    runApp(InitializationErrorScreen(error: error));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return ThemeBuilder(
          themes: ThemeConfig.materialThemes,
          builder: (context, regularTheme, darkTheme, themeMode) {
            return MaterialApp(
              title: 'Mind Vault',
              debugShowCheckedModeBanner: false,
              theme: regularTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              locale: localeProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('tr'),
              ],
              home: const HomeGate(),
            );
          },
        );
      },
    );
  }
}

class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
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