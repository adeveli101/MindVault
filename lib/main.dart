// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_service.dart';
import 'package:mindvault/firebase_options.dart';
// Provider paketi kullanılacaksa
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked_themes/stacked_themes.dart';

// Tema ve Repository importları
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/features/journal/repository/mindvault_repository.dart';

// Journal Bloc importları
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';

// Auth Bloc importları (Kendi dosya yolunuza göre güncelleyin)
import 'package:mindvault/features/journal/bloc_auth/auth_bloc.dart';

// Ekran importları
import 'package:mindvault/features/journal/screens/home/main_screen.dart';
import 'package:mindvault/features/journal/screens/home/onboarding_screen.dart';
import 'package:mindvault/features/journal/screens/settings/lock/lock_screen.dart'; // LockScreen import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialise();

  // Onboarding Durumu
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  // Servisleri başlatma
  MindVaultRepository? mindVaultRepository;
  AuthService? authService; // AuthService nesnesi

  try {
    // Firebase başlatma
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Intl başlatma
    await initializeDateFormatting('tr_TR', null);

    // Repository ve Servisleri oluştur
    mindVaultRepository = MindVaultRepository();
    await mindVaultRepository.init(); // Repository'yi başlat
    authService = AuthService(); // AuthService'i oluştur

    if (kDebugMode) {
      print("Firebase, Intl, Repository, AuthService Initialized Successfully.");
    }

    // Uygulamayı Provider'lar ile çalıştır
    runApp(
      // Önce Repository/Service'leri sağla
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MindVaultRepository>(
            create: (_) => mindVaultRepository!,
            // Uygulama kapanırken repository'yi kapatmak için dispose gerekli olabilir,
            // ancak MultiProvider'da dispose yok. Uygulama kapanırken manuel çağrılabilir
            // veya farklı bir state management (riverpod gibi) düşünülebilir.
            // Şimdilik Bloc içinde dispose yönetimi daha yaygın.
          ),
          RepositoryProvider<AuthService>(
            create: (_) => authService!,
          ),
        ],
        // Sonra Bloc'ları sağla
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
              ), // AuthBloc constructor'ı içinde CheckAuthStatus eklenmişti
              lazy: false, // AuthBloc'un hemen başlaması ve durumu kontrol etmesi için
            ),
          ],
          child: MyApp(showOnboarding: !onboardingComplete), // Onboarding durumunu ilet
        ),
      ),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      print("FATAL ERROR during App Initialization: $error");
      print(stackTrace);
    }
    // Repository başlatıldıysa kapatmayı dene
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
    // stacked_themes için ThemeBuilder
    return ThemeBuilder(
      themes: ThemeConfig.materialThemes,
      builder: (context, regularTheme, darkTheme, themeMode) {
        return MaterialApp(
          title: 'Mind Vault',
          debugShowCheckedModeBanner: false,
          theme: regularTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,

          // Başlangıç ekranını belirleyen yeni bir widget kullanalım
          home: HomeGate(showOnboarding: showOnboarding),
        );
      },
    );
  }
}

/// Onboarding ve Auth durumuna göre ilk ekranı yönlendiren Widget
class HomeGate extends StatelessWidget {
  final bool showOnboarding;
  const HomeGate({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    // Eğer onboarding gösterilmesi gerekiyorsa, kimlik durumuna bakmadan onu göster
    if (showOnboarding) {
      // print("HomeGate: Showing OnboardingScreen."); // Debug
      return const OnboardingScreen();
    } else {
      // Onboarding tamamlanmışsa, AuthBloc durumuna bak
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // print("HomeGate: Auth State Received: $state"); // Debug
          if (state is AuthInitial || state is AuthInProgress) {
            // Kimlik durumu kontrol edilirken veya işlem yapılırken bekleme ekranı
            // print("HomeGate: Showing Loading Screen."); // Debug
            return const Scaffold(
              // Temalı bir bekleme ekranı daha iyi olabilir
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is AuthLocked || state is AuthFailure) {
            // Uygulama kilitliyse veya önceki deneme başarısızsa LockScreen'i göster
            // print("HomeGate: Showing LockScreen."); // Debug
            return const LockScreen();
          } else if (state is AuthUnlocked || state is AuthSetupRequired) {
            // Kilit açılmışsa veya PIN kurulumu gerekliyse (ayarlardan yapılır) MainScreen'i göster
            // print("HomeGate: Showing MainScreen."); // Debug
            return const MainScreen();
          } else {
            // Beklenmedik bir durum için fallback
            // print("HomeGate: Showing Fallback Error Screen."); // Debug
            return const Scaffold(
              body: Center(child: Text("Beklenmedik bir kimlik doğrulama durumu!")),
            );
          }
        },
      );
    }
  }
}


/// Başlatma sırasında hata oluşursa gösterilecek basit bir ekran.
class InitializationErrorScreen extends StatelessWidget {
  final Object error;
  const InitializationErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // Bu widget aynı kalabilir
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