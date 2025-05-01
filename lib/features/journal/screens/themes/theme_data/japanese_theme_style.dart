// lib/features/journal/screens/themes/theme_data/styles/japanese_theme_style.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class JapaneseThemeStyle {
  // --- Bu Stile Özel Sabitler ---
  static const String _bgPath = 'assets/pages/japanase_minimalist/jpn_minimalist_page1.jpg';

  // Renkler (Minimalist Görselden Esinlenilmiştir - Açık Zemin, Koyu Vurgu)
  static const Color _primary = Color(0xFF424242); // Koyu Gri/Antrasit (Vurgu)
  static const Color _secondary = Color(0xFF9E9E9E); // Orta Gri (İkincil)
  static const Color _onPrimary = Color(0xFFFFFFFF); // Koyu gri üzerine Beyaz
  static const Color _surface = Color(0xFFFDFDFD); // Çok Açık Gri/Beyaz Yüzey
  static const Color _surfaceContainer = Color(0xFFF5F5F5); // Biraz daha koyu container
  static const Color _onSurface = Color(0xFF303030); // Metin Rengi (Koyu Gri - Primary'den biraz açık)
  static const Color _onSurfaceVariant = Color(0xFF757575); // İkincil metin/ikon (Orta Gri)
  static const Color _scaffoldBg = Color(0xFFFFFFFF); // Genel Arka Plan (Beyaz/Çok Açık)
  static const Color _outline = Color(0xFFE0E0E0); // Kenarlıklar (Çok Açık Gri)

  // --- Varyant Tanımları ---
  static final AppThemeData small = _create(
    type: NotebookThemeType.japaneseSmall,
    name: "Minimalist (Küçük)",
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.japaneseMedium,
    name: "Minimalist (Orta)",
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.japaneseLarge,
    name: "Minimalist (Büyük)",
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
    final Brightness brightness = Brightness.light;
    // Font Seçimi (Minimalist ve okunaklı)
    // Noto Sans JP veya M PLUS Rounded 1c iyi seçenekler olabilir. Lato da temizdir.
    final TextTheme baseText = GoogleFonts.cabinCondensedTextTheme(ThemeData(brightness: brightness).textTheme);
    final String decorativeFont = GoogleFonts.cabin().fontFamily!; // Başlık için de aynı font

    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true, // Örnek olarak ücretli
      materialTheme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        colorScheme: ColorScheme( // Minimalist renk paleti
          brightness: brightness,
          primary: _primary,
          onPrimary: _onPrimary,
          secondary: _secondary,
          onSecondary: _onPrimary, // Gri üzerine beyaz
          error: Colors.red.shade700,
          onError: Colors.white,
          surface: _surface, // Açık gri yüzey
          onSurface: _onSurface, // Koyu gri metin
          surfaceContainer: _surfaceContainer, // Biraz koyu container
          onSurfaceVariant: _onSurfaceVariant, // Orta gri ikincil
          outline: _outline, // Açık gri kenarlık
        ),
        textTheme: ThemeConfigBase.buildTextTheme(
          baseTextTheme: baseText, // Noto Sans JP
          decorativeFontFamily: decorativeFont, // Noto Sans JP
          baseColor: _onSurface,
          bodyItalic: false,
          decorativeBold: false, // Minimalist, kalın değil
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme( // AppBar
          foregroundColor: _onSurface, // Koyu gri başlık
          fontFamily: decorativeFont,
          fontSize: 20,
          backgroundColor: _scaffoldBg.withOpacity(0.95), // Neredeyse opak
          elevation: 0, // Gölgesiz
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme( // Input Alanı
          themeColor: _secondary, // Orta gri etiket/hint
          fillColor: Colors.transparent, // Dolgusuz
          isFilled: false,
          borderRadius: 4.0,
          border: UnderlineInputBorder( // Sadece alt çizgi
            borderSide: BorderSide(color: _outline, width: 1), // Açık gri çizgi
          ),
          labelAndHintStyle: TextStyle( // Temiz label/hint
            fontFamily: baseText.bodyMedium?.fontFamily,
            color: _secondary,
            fontSize: 16,
          ),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme( // Butonlar
          backgroundColor: _primary, // Koyu gri buton
          foregroundColor: _onPrimary, // Beyaz yazı
          borderRadius: 6.0, // Hafif yuvarlak
        ),
        // Minimalist temada TextButton daha uygun olabilir
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _primary),
        // OutlinedButton stili de tanımlanabilir
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary, // Koyu gri yazı
              side: BorderSide(color: _outline, width: 1), // Açık gri kenarlık
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            )
        ),
        cardTheme: ThemeConfigBase.buildCardTheme( // Kartlar
          color: _surface, // Yüzey rengiyle aynı veya çok yakın
          elevation: 0, // Gölgesiz
          borderRadius: 8.0,
          // Belki ince bir kenarlık eklenebilir
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(8.0),
          //   side: BorderSide(color: _outline, width: 1)
          // ),
        ),
        dividerTheme: DividerThemeData(color: _outline.withOpacity(0.8), thickness: 1), // Açık gri ayırıcı
        iconTheme: IconThemeData(color: _onSurfaceVariant, size: 20), // Orta gri ikonlar
      ),
    );
  }
}