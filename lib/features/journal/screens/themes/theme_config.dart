// lib/theme/theme_config.dart

import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Google Fonts kullanıyorsanız
import 'app_theme_data.dart';
import 'notebook_theme_type.dart';

/// Uygulamanın tüm tema tanımlarını ve ilgili yapılandırmaları içerir.
class ThemeConfig {
  // --- Ortak Varlıklar ---
  static const String _baseBackground =
      'assets/pages/book_page-1.jpg'; // Tüm temalar için ortak kağıt

  // --- Tema Tanımları ---

  // 1. Varsayılan Açık Tema (Ücretsiz)
  static final AppThemeData defaultLight = AppThemeData(
    type: NotebookThemeType.defaultLight,
    name: "Varsayılan Aydınlık",
    backgroundAssetPath: _baseBackground,
    isFree: true, // Ücretsiz
    materialTheme: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueGrey, // Nötr bir renk
        brightness: Brightness.light,
        primary: const Color(0xFF546E7A),
        secondary: const Color(0xFF78909C),
        surface: const Color(0xFFFAFAFA), // Ana yüzey rengi (önceki background)
        surfaceContainerHighest: const Color(0xFFECEFF1), // Hafif gri container
        onSurface: const Color(0xFF263238), // Koyu yazı
      ),
      // TextTheme'i burada veya _buildTextTheme ile tanımlayın
      textTheme: _buildTextTheme(baseFont: 'Roboto', headingFont: 'Montserrat'),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Arka planı göstermek için
        elevation: 0,
        foregroundColor: Color(0xFF263238), // AppBar ikon/metin rengi
      ),
      scaffoldBackgroundColor: Colors.transparent, // ThemedBackground'ı göstermek için
      // Diğer widget tema ayarları (CardTheme, ButtonTheme vb.) eklenebilir
    ),
  );

  // 2. Varsayılan Koyu Tema (Ücretsiz)
  static final AppThemeData defaultDark = AppThemeData(
    type: NotebookThemeType.defaultDark,
    name: "Varsayılan Karanlık",
    backgroundAssetPath: _baseBackground, // Aynı kağıt dokusu
    isFree: true, // Ücretsiz
    materialTheme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueGrey, // Nötr bir renk
        brightness: Brightness.dark,
        primary: const Color(0xFF90A4AE), // Daha açık primary
        secondary: const Color(0xFFB0BEC5), // Daha açık secondary
        surface: const Color(0xFF263238), // Koyu ana yüzey (önceki background)
        surfaceContainerHighest: const Color(0xFF455A64), // Biraz daha açık container
        onSurface: const Color(0xFFECEFF1), // Açık yazı
      ),
      // TextTheme'i burada veya _buildTextTheme ile tanımlayın
      textTheme: _buildTextTheme(baseFont: 'Roboto', headingFont: 'Montserrat', baseColor: const Color(0xFFECEFF1)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFFECEFF1),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      // Diğer widget tema ayarları
    ),
  );

  // 3. Klasik Deri (Potansiyel Ücretli)
  static final AppThemeData classicLeather = AppThemeData(
    type: NotebookThemeType.classicLeather,
    name: "Klasik Deri",
    backgroundAssetPath: _baseBackground,
    isFree: false, // Ücretli olacak
    materialTheme: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.brown,
        brightness: Brightness.light,
        primary: const Color(0xFF6D4C41),
        secondary: const Color(0xFF8D6E63),
        surface: const Color(0xFFFDFBF5), // Krem rengi ana yüzey (önceki background)
        surfaceContainerHighest: const Color(0xFFF5EFE6),
        onSurface: const Color(0xFF4E342E),
      ),
      textTheme: _buildTextTheme(baseFont: 'Merriweather', headingFont: 'Cinzel', baseColor: const Color(0xFF4E342E)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF4E342E),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      // Diğer widget tema ayarları
    ),
  );

  // --- Diğer Potansiyel Ücretli Tema Tanımları Buraya Eklenecek ---
  // static final AppThemeData dottedModern = AppThemeData(... isFree: false ...);
  // static final AppThemeData vintageFloralLight = AppThemeData(... isFree: false ...);
  // static final AppThemeData spiralBound = AppThemeData(... isFree: false ...);


  // --- Tema Listeleri ve Yardımcılar ---

  /// Uygulamada kullanılabilen TÜM temaların listesi.
  /// Sıralama önemlidir, `stacked_themes` bu sıraya göre index kullanır.
  /// ÜCRETSİZ temaları listenin başına koymak genellikle iyi bir pratiktir.
  static final List<AppThemeData> themes = [
    defaultLight,       // Index 0 (Varsayılan olabilir)
    defaultDark,        // Index 1
    classicLeather,     // Index 2 (Ücretli)
    // ... diğer ücretli temalar buraya eklenecek
    // dottedModern,    // Index 3 (Ücretli)
    // vintageFloralLight, // Index 4 (Ücretli)
    // spiralBound,     // Index 5 (Ücretli)
  ];

  /// `stacked_themes`'in `ThemeManager`'ına vermek için sadece `ThemeData` listesi.
  static List<ThemeData> get materialThemes => themes.map((t) => t.materialTheme).toList();

  /// Belirli bir index'e karşılık gelen tam `AppThemeData` nesnesini döndürür.
  /// Bu, özel asset yollarına vb. erişmek için kullanılır.
  /// `stacked_themes`'den alınan index ile kullanılır.
  static AppThemeData getAppThemeDataByIndex(int index) {
    if (index >= 0 && index < themes.length) {
      return themes[index];
    }
    // Geçersiz index durumunda varsayılan temayı döndür (genellikle ilk tema)
    return themes.first;
  }

  /// Belirli bir index'e karşılık gelen `NotebookThemeType`'ı döndürür.
  static NotebookThemeType getThemeTypeByIndex(int index) {
    return getAppThemeDataByIndex(index).type;
  }

  /// Belirli bir `NotebookThemeType`'a karşılık gelen index'i döndürür.
  /// Tema seçimi UI'ında mevcut seçimi işaretlemek için kullanışlıdır.
  static int getIndexByThemeType(NotebookThemeType type) {
    final index = themes.indexWhere((theme) => theme.type == type);
    return index != -1 ? index : 0; // Bulunamazsa varsayılan index (0)
  }

  // --- Yardımcı Fonksiyonlar ---

  /// Tutarlı bir TextTheme oluşturur. Google Fonts veya yerel fontları kullanabilir.
  static TextTheme _buildTextTheme({required String baseFont, required String headingFont, Color? baseColor}) {
    // GoogleFonts paketi ekliyse:
    // return GoogleFonts.getTextTheme(baseFont, GoogleFonts.getTextTheme(headingFont)).apply(bodyColor: baseColor, displayColor: baseColor);

    // Yerel fontlar varsayımıyla:
    final baseStyle = TextStyle(fontFamily: baseFont, color: baseColor);
    final headingStyle = TextStyle(fontFamily: headingFont, color: baseColor, fontWeight: FontWeight.w600); // Başlıkları biraz kalın yapalım

    return TextTheme(
      // Başlıklar
      displayLarge: headingStyle.copyWith(fontSize: 48),
      displayMedium: headingStyle.copyWith(fontSize: 36),
      displaySmall: headingStyle.copyWith(fontSize: 28),
      headlineLarge: headingStyle.copyWith(fontSize: 24),
      headlineMedium: headingStyle.copyWith(fontSize: 20),
      headlineSmall: headingStyle.copyWith(fontSize: 18),
      // Gövde Metinleri
      bodyLarge: baseStyle.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: baseStyle.copyWith(fontSize: 14, height: 1.4), // Varsayılan metin
      bodySmall: baseStyle.copyWith(fontSize: 12, height: 1.3),
      // Diğerleri
      labelLarge: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600), // Butonlar vb.
      labelMedium: baseStyle.copyWith(fontSize: 12),
      labelSmall: baseStyle.copyWith(fontSize: 10),
      titleLarge: headingStyle.copyWith(fontSize: 18), // AppBar başlığı vb.
      titleMedium: headingStyle.copyWith(fontSize: 16),
      titleSmall: headingStyle.copyWith(fontSize: 14),
    ).apply(bodyColor: baseColor, displayColor: baseColor); // Genel renk ayarı
  }
}