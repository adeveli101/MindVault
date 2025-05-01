// lib/features/journal/screens/themes/theme_data/styles/scrapbook_theme_style.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class ScrapbookThemeStyle {
  // --- Bu Stile Özel Sabitler ---
  static const String _bgPath = 'assets/pages/digital_scrapbooking/scrapbook_page1.jpg';

  // Renkler (Scrapbook Görselinden Esinlenilmiştir - Sıcak, canlı, el yapımı hissi)
  static const Color _primary = Color(0xFFE57373); // Kenardaki Kırmızımsı Ton
  static const Color _secondary = Color(0xFF4DB6AC); // Kenardaki Yeşil/Teal Ton
  static const Color _onPrimary = Color(0xFFFFFFFF); // Kırmızı üzerine beyaz
  static const Color _onSecondary = Color(0xFFFFFFFF); // Teal üzerine beyaz
  static const Color _surface = Color(0xFFFFF3E0); // Ana Kağıt Rengi (Açık Bej)
  static const Color _surfaceContainer = Color(0xFFF5EEDC); // Biraz daha koyu bej
  static const Color _onSurface = Color(0xFF5D4037); // Metin Rengi (Koyu Kahve/Gri)
  static const Color _onSurfaceVariant = Color(0xFF8D6E63); // İkincil metin/ikon (Orta Kahve)
  static const Color _scaffoldBg = Color(0xFFFDF8F0); // Genel Arka Plan (Çok Açık Bej)
  static const Color _outline = Color(0xFFBDBDBD); // Kenarlıklar (Açık Gri)

  // --- Varyant Tanımları ---
  static final AppThemeData small = _create(
    type: NotebookThemeType.scrapbookSmall,
    name: "Karalama (Küçük)",
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.scrapbookMedium,
    name: "Karalama (Orta)",
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.scrapbookLarge,
    name: "Karalama (Büyük)",
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
    // Font Seçimi (El yazısı / Karalama hissi veren)
    final TextTheme baseText = GoogleFonts.patrickHandTextTheme(ThemeData(brightness: brightness).textTheme); // Örnek: Patrick Hand
    final String decorativeFont = GoogleFonts.architectsDaughter().fontFamily!; // Örnek: Architects Daughter

    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true, // Örnek olarak ücretli
      materialTheme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        colorScheme: ColorScheme( // Scrapbook renk paleti
          brightness: brightness,
          primary: _primary,
          onPrimary: _onPrimary,
          secondary: _secondary,
          onSecondary: _onSecondary,
          error: Colors.deepOrange.shade700, // Canlı bir hata rengi
          onError: Colors.white,
          surface: _surface, // Bej yüzey
          onSurface: _onSurface, // Koyu kahve metin
          surfaceContainer: _surfaceContainer, // Koyu bej container
          onSurfaceVariant: _onSurfaceVariant, // Orta kahve ikincil metin
          outline: _outline, // Açık gri kenarlık
        ),
        textTheme: ThemeConfigBase.buildTextTheme( // Global helper ile text tema
          baseTextTheme: baseText, // Patrick Hand
          decorativeFontFamily: decorativeFont, // Architects Daughter
          baseColor: _onSurface,
          bodyItalic: false, // El yazısı zaten eğimli olabilir
          decorativeBold: false, // Başlıklar normal olabilir
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme( // AppBar
          foregroundColor: _onSurface, // Koyu kahve başlık
          fontFamily: decorativeFont, // Başlık fontu
          fontSize: 22,
          backgroundColor: _scaffoldBg.withOpacity(0.9), // Hafif transparan
          elevation: 0.5, // Çok hafif gölge
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme( // Input Alanı
          themeColor: _secondary, // Teal etiket/hint
          fillColor: _surface.withOpacity(0.8), // Yüzey rengi dolgu
          isFilled: true,
          borderRadius: 6.0,
          border: OutlineInputBorder( // Bantlanmış gibi hafif border
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(color: _outline.withOpacity(0.7), width: 1),
          ),
          labelAndHintStyle: TextStyle( // Özel label/hint stili
              fontFamily: decorativeFont, // Architects Daughter
              color: _secondary,
              fontSize: 18),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme( // Butonlar
          backgroundColor: _primary, // Kırmızımsı buton
          foregroundColor: _onPrimary, // Beyaz yazı
          borderRadius: 12.0, // Biraz yuvarlak
        ),
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _secondary), // Teal Text Buton
        cardTheme: ThemeConfigBase.buildCardTheme( // Kartlar
          color: _surfaceContainer.withOpacity(0.9), // Koyu bej kart
          elevation: 0.5, // Çok hafif gölge
          borderRadius: 8.0,
        ),
        dividerTheme: DividerThemeData(color: _onSurfaceVariant.withOpacity(0.3), thickness: 1), // Orta kahve ayırıcı
        iconTheme: IconThemeData(color: _onSurfaceVariant, size: 22), // Orta kahve ikonlar
      ),
    );
  }
}