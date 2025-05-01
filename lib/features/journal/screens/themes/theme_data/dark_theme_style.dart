// lib/features/journal/screens/themes/theme_data/styles/dark_theme_style.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class DarkThemeStyle {
  // --- Bu Stile Özel Sabitler ---
  static const String _bgPath = 'assets/pages/dark/dark_page.jpg'; // Görselin yolu

  // Renkler (Görselden Esinlenilmiş - Koyu Zemin, Altın Vurgu)
  static const Color _primary = Color(0xFFD4AF37); // Altın Rengi (Vurgu)
  static const Color _secondary = Color(0xFFB0BEC5); // Açık Gri/Gümüş (İkincil)
  static const Color _onPrimary = Color(0xFF1A1A1A); // Altın üzerine Koyu Gri/Siyah
  static const Color _surface = Color(0xFF212121); // Koyu Gri Yüzey
  static const Color _surfaceContainer = Color(0xFF303030); // Biraz daha açık container
  static const Color _onSurface = Color(0xFFE0E0E0); // Metin rengi (Kırık Beyaz)
  static const Color _onSurfaceVariant = Color(0xFF9E9E9E); // İkincil metin/ikon (Gri)
  static const Color _scaffoldBg = Color(0xFF121212); // Çok Koyu Gri/Siyah Arkaplan
  static const Color _outline = Color(0xFF757575); // Kenarlıklar (Gri)

  // --- Varyant Tanımları ---
  static final AppThemeData small = _create(
    type: NotebookThemeType.defaultDarkSmall, // Enum adı orijinal kalabilir
    name: "Altın Vurgu (Küçük)", // İsim güncellendi
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.defaultDarkMedium,
    name: "Altın Vurgu (Orta)", // İsim güncellendi
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.defaultDarkLarge,
    name: "Altın Vurgu (Büyük)", // İsim güncellendi
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
    final Brightness brightness = Brightness.dark;
    // Font Seçimi (Elegant Koyu Tema İçin)
    final TextTheme baseText = GoogleFonts.cabinTextTheme(ThemeData(brightness: brightness).textTheme); // Temiz sans-serif
    final String decorativeFont = GoogleFonts.playfairDisplay().fontFamily!; // Şık serif başlık

    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true, // Orijinal tema ücretsizdi
      materialTheme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        colorScheme: ColorScheme( // Koyu tema renk paleti (Altın Vurgulu)
          brightness: brightness,
          primary: _primary, // Altın
          onPrimary: _onPrimary, // Koyu
          secondary: _secondary, // Açık Gri
          onSecondary: _onPrimary, // Koyu
          error: Colors.redAccent.shade100, // Açık hata rengi
          onError: Colors.black,
          surface: _surface, // Koyu Gri
          onSurface: _onSurface, // Kırık Beyaz
          surfaceContainer: _surfaceContainer,
          onSurfaceVariant: _onSurfaceVariant, // Gri
          outline: _outline, // Gri Kenarlık
        ),
        textTheme: ThemeConfigBase.buildTextTheme(
          baseTextTheme: baseText, // Lato
          decorativeFontFamily: decorativeFont, // Playfair Display
          baseColor: _onSurface, // Kırık Beyaz metin
          bodyItalic: false,
          decorativeBold: true, // Başlıklar kalın olabilir
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme(
          foregroundColor: _onSurface, // Kırık Beyaz yazı/ikon
          fontFamily: decorativeFont,
          fontSize: 22,
          backgroundColor: _scaffoldBg.withOpacity(0.9), // Hafif transparan
          elevation: 0,
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme(
          themeColor: _primary, // Altın etiket/hint
          fillColor: _surfaceContainer.withOpacity(0.5), // Koyu dolgu
          isFilled: true,
          borderRadius: 4.0, // Hafif köşeli
          // Altın rengi ince bir alt çizgi
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: _primary.withOpacity(0.6), width: 1),
            borderRadius: BorderRadius.circular(4.0),
          ),
          labelAndHintStyle: TextStyle( // Temiz label/hint stili
              fontFamily: baseText.bodyMedium?.fontFamily, // Lato
              color: _primary.withOpacity(0.8),
              fontSize: 16
          ),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme(
          backgroundColor: _primary, // Altın buton
          foregroundColor: _onPrimary, // Koyu yazı
          borderRadius: 8.0, // Hafif yuvarlak köşe
        ),
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _primary), // Altın Text Buton
        cardTheme: ThemeConfigBase.buildCardTheme(
          color: _surfaceContainer, // Koyu kart
          elevation: 1, // Hafif gölge
          borderRadius: 8.0,
        ),
        dividerTheme: DividerThemeData(color: _outline.withOpacity(0.3), thickness: 1),
        iconTheme: IconThemeData(color: _onSurfaceVariant, size: 20), // Gri ikonlar
      ),
    );
  }
}