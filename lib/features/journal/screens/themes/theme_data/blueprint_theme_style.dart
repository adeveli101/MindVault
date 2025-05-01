// lib/features/journal/screens/themes/theme_data/styles/blueprint_theme_style.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class BlueprintThemeStyle {
  // --- Bu Stile Özel Sabitler ---
  static const String _bgPath = 'assets/pages/architectural_blueprint_style/arc_blueprint_page1.jpg';

  // Renkler (Blueprint Görselinden Esinlenilmiştir)
  static const Color _primary = Color(0xFFAEC6CF); // Açık Mavi/Gri (Çizgiler, Vurgu)
  static const Color _secondary = Color(0xFF8EAEBB); // Biraz daha koyu mavi/gri
  static const Color _onPrimary = Color(0xFF003366); // Açık renk üzerine Koyu Mavi
  static const Color _surface = Color(0xFF003366); // Koyu Mavi (İçerik alanı)
  static const Color _surfaceContainer = Color(0xFF002855); // Daha koyu container
  static const Color _onSurface = Color(0xFFFFFFFF); // Metin rengi (Beyaz)
  static const Color _onSurfaceVariant = Color(0xFFAEC6CF); // İkincil metin/ikon rengi
  static const Color _scaffoldBg = Color(0xFF002244); // En koyu mavi (Sayfa arka planı)
  static const Color _outline = Color(0xFF8EAEBB);   // Kenarlıklar

  // --- Varyant Tanımları ---
  static final AppThemeData small = _create(
    type: NotebookThemeType.blueprintSmall,
    name: "Mimari (Küçük)",
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.blueprintMedium,
    name: "Mimari (Orta)",
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.blueprintLarge,
    name: "Mimari (Büyük)",
    fontSize: ThemeConfigBase.globalBodySizeLarge,
    letterSpacing: ThemeConfigBase.globalLetterSpacingLarge,
  );

  // --- Bu Stile Özel Tema Oluşturucu (_create) ---
  static AppThemeData _create({
    required NotebookThemeType type,
    required String name,
    required double fontSize,
    required double letterSpacing,
  }) {
    final Brightness brightness = Brightness.dark; // Blueprint genellikle karanlık moddur
    // Font Seçimi (Teknik çizim hissi veren)
    final TextTheme baseText = GoogleFonts.sourceCodeProTextTheme(ThemeData(brightness: brightness).textTheme); // Monospace font
    final String decorativeFont = GoogleFonts.robotoCondensed().fontFamily!; // Temiz, dar başlık fontu

    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true, // Örnek olarak ücretli
      materialTheme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        colorScheme: ColorScheme( // Blueprint renk paleti
          brightness: brightness,
          primary: _primary,
          onPrimary: _onPrimary,
          secondary: _secondary,
          onSecondary: _onPrimary, // Koyu mavi
          error: Colors.red.shade300, // Hata rengi (açık kırmızı)
          onError: Colors.black,
          surface: _surface, // İçerik arka planı
          onSurface: _onSurface, // Metin rengi (beyaz)
          surfaceContainer: _surfaceContainer, // Kart vb. arka planı
          onSurfaceVariant: _onSurfaceVariant, // İkincil metin/ikonlar
          outline: _outline, // Kenarlık rengi
        ),
        textTheme: ThemeConfigBase.buildTextTheme(
          baseTextTheme: baseText, // Source Code Pro
          decorativeFontFamily: decorativeFont, // Roboto Condensed
          baseColor: _onSurface, // Beyaz metin
          bodyItalic: false, // Düz yazı
          decorativeBold: true, // Başlıklar kalın
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme( // AppBar ayarları
          foregroundColor: _onSurface, // Beyaz yazı/ikon
          fontFamily: decorativeFont,
          fontSize: 20, // Daha standart başlık boyutu
          backgroundColor: _scaffoldBg.withOpacity(0.85), // Hafif transparan arka plan
          elevation: 0,
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme( // Input alanı
          themeColor: _primary, // Açık mavi etiket/hint
          fillColor: _surfaceContainer.withOpacity(0.5), // Koyu mavi dolgu
          isFilled: true,
          borderRadius: 2.0, // Keskin köşeler
          border: UnderlineInputBorder( // Alt çizgi kenarlık
            borderSide: BorderSide(color: _outline.withOpacity(0.5), width: 1),
          ),
          // Label/Hint için temel fontu kullanabiliriz veya dekoratif
          labelAndHintStyle: TextStyle(
              fontFamily: baseText.bodyMedium?.fontFamily, // Monospace font
              color: _primary,
              fontSize: 16
          ),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme( // Butonlar
          backgroundColor: _primary, // Açık mavi buton
          foregroundColor: _onPrimary, // Koyu mavi yazı
          borderRadius: 2.0, // Keskin köşeler
        ),
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _primary),
        cardTheme: ThemeConfigBase.buildCardTheme( // Kartlar
          color: _surfaceContainer, // Koyu mavi kart
          elevation: 0, // Gölgesiz
          borderRadius: 2.0, // Keskin köşeler
        ),
        dividerTheme: DividerThemeData(color: _outline.withOpacity(0.4), thickness: 1),
        // İkon teması (varsayılan renk onSurface olur ama belirtebiliriz)
        iconTheme: IconThemeData(color: _onSurfaceVariant, size: 20),
      ),
    );
  }
}