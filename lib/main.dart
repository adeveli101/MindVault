// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// SystemChrome için (isteğe bağlı)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/repository/mindvault_repository.dart';
import 'package:mindvault/features/journal/screens/home/home_screen.dart';
import 'package:mindvault/features/journal/screens/home/onboarding_screen.dart';
import 'package:mindvault/firebase_options.dart';
import 'package:mindvault/theme_mindvault.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tarih formatlama için

// --- Kendi Proje Dosyalarınız ---
// (Yolları KONTROL EDİN ve kendi projenize göre güncelleyin!)


// Global olarak Repository ve BLoC örnekleri (main içinde başlatılacak)
// Provider ile yönetmek daha temizdir, bu yüzden bunları global yapmayacağız.
// MindVaultRepository? mindVaultRepository;
// JournalBloc? journalBloc;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Onboarding durumunu kontrol et
  final prefs = await SharedPreferences.getInstance();
  // 'onboarding_complete' anahtarını oku, eğer yoksa (ilk açılış) false döner
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  // Diğer başlatmaları yap (Firebase, Intl, Repository)
  MindVaultRepository? mindVaultRepository; // Nullable yapalım
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('tr_TR', null);

    mindVaultRepository = MindVaultRepository();
    await mindVaultRepository.init();

    if (kDebugMode) {
      print("Firebase, Intl, Repository Initialized Successfully.");
    }

    // Uygulamayı Provider'lar ile çalıştır
    runApp(
      MultiProvider(
        providers: [
          // Repository'yi sağla (nullable kontrolü ile)
          Provider<MindVaultRepository>(
            create: (_) => mindVaultRepository!, // Burada null olmamalı
            dispose: (_, repo) => repo.close(),
          ),
          // JournalBloc'u sağla
          BlocProvider<JournalBloc>(
            create: (context) => JournalBloc(
              repository: context.read<MindVaultRepository>(),
            )..add(const LoadJournalEntries()),
          ),
        ],
        // Onboarding durumuna göre hangi widget'ı göstereceğimizi MyApp içinde belirleyelim
        child: MyApp(showOnboarding: !onboardingComplete),
      ),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      print("FATAL ERROR during App Initialization: $error");
      print(stackTrace);
    }
    runApp(InitializationErrorScreen(error: error));
  }
}

/// Ana Uygulama Widget'ı
class MyApp extends StatelessWidget {
  /// Onboarding ekranının gösterilip gösterilmeyeceğini belirler.
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("MyApp build method called. Show Onboarding: $showOnboarding");
    }
    return MaterialApp(
      title: 'Mind Vault',
      debugShowCheckedModeBanner: false,
      theme: MindVaultTheme.lightTheme,
      darkTheme: MindVaultTheme.darkTheme,
      themeMode: ThemeMode.system,

      // --- Başlangıç Ekranı (Dinamik) ---
      // Eğer onboarding tamamlanmadıysa OnboardingScreen'i, tamamlandıysa HomeScreen'i göster.
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),

      // Rotaları tanımlayabilirsiniz (isteğe bağlı)
      // routes: {
      //   HomeScreen.routeName: (ctx) => const HomeScreen(),
      //   OnboardingScreen.routeName: (ctx) => const OnboardingScreen(),
      //   JournalListScreen.routeName: (ctx) => const JournalListScreen(),
      // },
    );
  }
}


/// Başlatma sırasında hata oluşursa gösterilecek basit bir ekran.
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