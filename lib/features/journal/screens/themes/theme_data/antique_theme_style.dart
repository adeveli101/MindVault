// lib/features/journal/screens/themes/theme_data/antique_theme_style.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class AntiqueThemeStyle {
  // --- Bu Stile Özel Sabitler ---
  static const String _bgPath = 'assets/pages/antique/antique_page1.jpg';

  // Renkler (Görselden esinlenilmiştir, ayarlanabilir)
  static const Color _primary = Color(0xFF6D4C41); // Koyu Kahve (Kenarlık/Vurgu)
  static const Color _secondary = Color(0xFF8D6E63); // Biraz daha açık kahve
  static const Color _onPrimary = Color(0xFFF5EFE6); // Koyu kahve üzerine açık bej/krem
  static const Color _surface = Color(0xFFF5EFE6); // Ana içerik alanı (kağıt rengi - biraz açık)
  static const Color _surfaceContainer = Color(0xFFEAE0D5); // Hafif koyu container rengi
  static const Color _onSurface = Color(0xFF4E342E); // Metin rengi (koyu sepia/kahve)
  static const Color _onSurfaceVariant = Color(0xFF795548); // İkincil metin/ikon rengi
  static const Color _scaffoldBg = Color(0xFFEDE7DC); // Genel sayfa arkaplanı (hafif koyu kağıt)
  static const Color _outline = Color(0xFFA1887F); // Kenarlıklar için (isteğe bağlı)

  // --- Varyant Tanımları ---
  static final AppThemeData small = _create(
    type: NotebookThemeType.antiqueSmall,
    name: "Antika (Küçük)",
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.antiqueMedium,
    name: "Antika (Orta)",
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.antiqueLarge,
    name: "Antika (Büyük)",
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
    final Brightness brightness = Brightness.light; // Antika tema genellikle aydınlıktır
    // Font Seçimi (Antika havaya uygun)
    final TextTheme baseText = GoogleFonts.imFellEnglishTextTheme(ThemeData(brightness: brightness).textTheme);
    final String decorativeFont = GoogleFonts.imFellEnglishSc().fontFamily!; // Başlıklar için SC

    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true, // Örnek olarak ücretli varsayalım
      materialTheme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        colorScheme: ColorScheme( // Antika renk paleti
          brightness: brightness,
          primary: _primary,
          onPrimary: _onPrimary,
          secondary: _secondary,
          onSecondary: _onPrimary,
          error: Colors.red.shade900, // Uygun bir hata rengi
          onError: Colors.white,
          surface: _surface, // Ana içerik arka planı
          onSurface: _onSurface, // Ana metin rengi
          surfaceContainer: _surfaceContainer, // Kart vb. için arka plan
          onSurfaceVariant: _onSurfaceVariant, // İkincil metin/ikonlar
          outline: _outline, // Kenarlık rengi
          // Diğer renkler (shadow, inverseSurface vb. ayarlanabilir)
        ),
        textTheme: ThemeConfigBase.buildTextTheme( // Global helper ile text tema oluşturma
          baseTextTheme: baseText, // Seçilen font teması
          decorativeFontFamily: decorativeFont, // Başlık fontu
          baseColor: _onSurface, // Ana metin rengi
          bodyItalic: false, // Antika için düz yazı daha uygun olabilir
          decorativeBold: false, // Başlıklar normal ağırlıkta olabilir
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme( // AppBar ayarları
          foregroundColor: _onSurface, // Metin/ikon rengi
          fontFamily: decorativeFont, // Başlık fontu
          fontSize: 24, // Biraz daha büyük başlık
          backgroundColor: _scaffoldBg.withOpacity(0.8), // Hafif transparan sayfa rengi
          elevation: 0, // Gölgesiz
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme( // Input alanı ayarları
          themeColor: _primary, // Etiket/Hint rengi
          fillColor: _surface.withOpacity(0.6), // Hafif opak yüzey rengi dolgu
          isFilled: true,
          borderRadius: 4.0, // Hafif köşeli
          border: OutlineInputBorder( // Hafif kenarlık
              borderRadius: BorderRadius.circular(4.0),
              borderSide: BorderSide(color: _outline.withOpacity(0.5), width: 1)),
          labelAndHintStyle: TextStyle( // Özel label/hint stili
            fontFamily: decorativeFont,
            color: _primary,
            fontSize: 18, // Biraz daha küçük
            fontWeight: FontWeight.normal,
          ),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme( // Buton ayarları
          backgroundColor: _primary, // Koyu kahve buton
          foregroundColor: _onPrimary, // Açık renk yazı
          borderRadius: 4.0, // Köşeli buton
        ),
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _primary), // Text buton rengi
        cardTheme: ThemeConfigBase.buildCardTheme( // Kart ayarları
          color: _surface.withOpacity(0.9), // Hafif transparan yüzey
          elevation: 1, // Çok hafif gölge
          borderRadius: 6.0,
        ),
        // Diğer widget temaları (örn. DialogTheme, dividerColor) buraya eklenebilir
        dividerTheme: DividerThemeData(color: _outline.withOpacity(0.3), thickness: 1),
      ),
    );
  }
}