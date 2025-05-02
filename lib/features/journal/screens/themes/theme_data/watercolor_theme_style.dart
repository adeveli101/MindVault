// lib/features/journal/screens/themes/theme_data/styles/watercolor_theme_style.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class WatercolorThemeStyle {
  // --- Bu Stile Özel Sabitler ---
  static const String _bgPath = 'assets/pages/watercolor/watercolor_page1.jpg';

  // Renkler (Suluboya Görselinden Esinlenilmiştir - Pastel ve Aydınlık)
  static const Color _primary = Color(0xFFBA68C8); // Yumuşak Mor (Vurgu)
  static const Color _secondary = Color(0xFF4DB6AC); // Yumuşak Teal (İkincil)
  static const Color _tertiary = Color(0xFFF06292); // Yumuşak Pembe (Ekstra)
  static const Color _onPrimary = Color(0xFFF06292); // Mor üzerine Beyaz
  static const Color _onSecondary = Color(0xFFFFFFFF); // Teal üzerine Beyaz
  static const Color _onTertiary = Color(0xFFFFFFFF); // Pembe üzerine Beyaz
  static const Color _surface = Color(0xFFFFFFFF); // Beyaz Yüzey (Kağıt)
  static const Color _surfaceContainer = Color(0xFFF5F5F5); // Çok Açık Gri Container
  static const Color _onSurface = Color(0xFF546E7A); // Metin Rengi (Koyu Mavimsi Gri)
  static const Color _onSurfaceVariant = Color(0xFF90A4AE); // İkincil metin/ikon (Orta Gri)
  static const Color _scaffoldBg = Color(0xFFFFFFFF); // Genel Arka Plan (Beyaz)
  static const Color _outline = Color(0xFFCFD8DC); // Kenarlıklar (Açık Gri Mavi)

  // --- Varyant Tanımları ---
  static final AppThemeData small = _create(
    type: NotebookThemeType.watercolorSmall,
    name: "Suluboya (Küçük)",
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.watercolorMedium,
    name: "Suluboya (Orta)",
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.watercolorLarge,
    name: "Suluboya (Büyük)",
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
    // Font Seçimi (Yumuşak, yuvarlak hatlı veya sanatsal)
    final TextTheme baseText = GoogleFonts.quicksandTextTheme(ThemeData(brightness: brightness).textTheme); // Yuvarlak hatlı sans-serif
    final String decorativeFont = GoogleFonts.quicksand().fontFamily!; // Başlık için de aynı font (kalın kullanılabilir)

    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true, // Örnek olarak ücretli
      materialTheme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        colorScheme: ColorScheme( // Suluboya renk paleti
          brightness: brightness,
          primary: _primary,
          onPrimary: _onPrimary,
          secondary: _secondary,
          onSecondary: _onSecondary,
          tertiary: _tertiary, // Ekstra renk
          onTertiary: _onTertiary,
          error: Colors.red.shade400,
          onError: Colors.white,
          surface: _surface, // Beyaz yüzey
          onSurface: _onSurface, // Koyu mavi-gri metin
          surfaceContainer: _surfaceContainer, // Açık gri container
          onSurfaceVariant: _onSurfaceVariant, // Orta gri ikincil
          outline: _outline, // Açık gri-mavi kenarlık
        ),
        textTheme: ThemeConfigBase.buildTextTheme(
          baseTextTheme: baseText, // Quicksand
          decorativeFontFamily: decorativeFont, // Quicksand
          baseColor: _onSurface,
          bodyItalic: false,
          decorativeBold: true, // Başlıklar kalın olsun
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme( // AppBar
          foregroundColor: _primary, // Mor başlık
          fontFamily: decorativeFont,
          fontSize: 22,
          backgroundColor: _surface.withOpacity(0.9), // Hafif transparan beyaz
          elevation: 0.5, // Çok hafif gölge
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme( // Input Alanı
          themeColor: _secondary, // Teal etiket/hint
          fillColor: _surfaceContainer.withOpacity(0.7), // Açık gri dolgu
          isFilled: true,
          borderRadius: 12.0, // Yuvarlak köşeler
          border: InputBorder.none, // Kenarlıksız
          labelAndHintStyle: TextStyle( // Temiz label/hint
            fontFamily: baseText.bodyMedium?.fontFamily,
            color: _secondary,
            fontSize: 16,
          ),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme( // Butonlar
          backgroundColor: _primary, // Mor buton
          foregroundColor: _onPrimary, // Beyaz yazı
          borderRadius: 20.0, // Yuvarlak buton
        ),
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _secondary), // Teal Text Buton
        cardTheme: ThemeConfigBase.buildCardTheme( // Kartlar
          color: _surface, // Beyaz kart
          elevation: 1, // Hafif gölge
          borderRadius: 12.0, // Yuvarlak köşeler
        ),
        dividerTheme: DividerThemeData(color: _outline.withOpacity(0.6), thickness: 1), // Açık gri ayırıcı
        iconTheme: IconThemeData(color: _secondary, size: 20), // Teal ikonlar
      ),
    );
  }
}