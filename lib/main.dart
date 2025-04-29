// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/repository/mindvault_repository.dart';
import 'package:mindvault/features/journal/screens/home/home_screen.dart';
import 'package:mindvault/features/journal/screens/home/onboarding_screen.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/firebase_options.dart';
import 'package:provider/provider.dart'; // MultiProvider için gerekli
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked_themes/stacked_themes.dart'; // <-- stacked_themes import edildi

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // stacked_themes'i başlat
  await ThemeManager.initialise(); // Bu doğru

  // Onboarding durumunu kontrol et
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  // Tema index'ini SharedPreferences'dan okumaya GEREK YOK

  // Diğer başlatmaları yap (Firebase, Intl, Repository)
  MindVaultRepository? mindVaultRepository;
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
          // Repository'yi sağla
          Provider<MindVaultRepository>(
            create: (_) => mindVaultRepository!,
            dispose: (_, repo) => repo.close(),
          ),
          // JournalBloc'u sağla
          BlocProvider<JournalBloc>(
            create: (context) => JournalBloc(
              repository: context.read<MindVaultRepository>(),
            )..add(const LoadJournalEntries()),
          ),
          // Provider<ThemeService> veya Provider<int> BURADA GEREKLİ DEĞİL
        ],
        child: MyApp(showOnboarding: !onboardingComplete),
      ),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      print("FATAL ERROR during App Initialization: $error");
      print(stackTrace);
    }
    // Hata ekranını göster
    runApp(InitializationErrorScreen(error: error));
  }
}

/// Ana Uygulama Widget'ı
class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  // _convertThemeManagerMode fonksiyonuna artık gerek yok

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("MyApp build method called. Show Onboarding: $showOnboarding");
    }

    // ThemeBuilder widget'ını MaterialApp'ı saracak şekilde kullanıyoruz
    return ThemeBuilder(
      // Bizim tanımladığımız ThemeData listesini veriyoruz
      themes: ThemeConfig.materialThemes,
      // İsteğe bağlı: Durum çubuğu rengini tema ile değiştirmek için
      // statusBarColorBuilder: (theme) => theme?.primaryColor,
      // İsteğe bağlı: Sadece Açık/Koyu mod kullanılacaksa
      // lightTheme: ...,
      // darkTheme: ...,
      // defaultThemeMode: ThemeMode.system,

      // builder fonksiyonu context, regularTheme, darkTheme, themeMode sağlar
      builder: (context, regularTheme, darkTheme, themeMode) {
        // Bu parametreleri doğrudan MaterialApp'a veriyoruz
        return MaterialApp(
          title: 'Mind Vault',
          debugShowCheckedModeBanner: false,

          // Temaları ThemeBuilder'dan al
          theme: regularTheme,
          darkTheme: darkTheme, // Birden çok tema olsa bile darkTheme sağlanabilir
          themeMode: themeMode, // ThemeBuilder bunu yönetir

          // Başlangıç Ekranı (Dinamik)
          home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
        );
      },
    );
  }
}

/// Başlatma sırasında hata oluşursa gösterilecek basit bir ekran.
class InitializationErrorScreen extends StatelessWidget {
  final Object error;
  const InitializationErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // Bu kısım aynı kalabilir
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