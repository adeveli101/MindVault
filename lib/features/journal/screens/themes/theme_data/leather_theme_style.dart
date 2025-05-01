// lib/features/journal/screens/themes/theme_data/styles/leather_theme_style.dart (Renk Paleti Güncellendi)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class LeatherThemeStyle {
  // --- Bu Stile Özel Sabitler ---
  static const String _bgPath = 'assets/pages/leather/leather_page1.jpg'; // Arka plan resmi

  // === YENİ RENKLER: Koyu Deri Zemin Üzerine Açık Metin ===
  static const Color _primary = Color(0xEEE7E7FF); // Vurgu/Butonlar için Açık Kahve/Bej
  static const Color _secondary = Color(0xFFBCAAA4); // İkincil Açık Kahve/Bej
  static const Color _onPrimary = Color(0xFF3E2723); // Açık kahve üzerine Koyu Kahve yazı
  static const Color _surface = Color(0xFF4E342E); // Ana Yüzey Rengi (Orta/Koyu Kahve)
  static const Color _surfaceContainer = Color(0xFF5D4037); // Container Rengi (Biraz Farklı Kahve)
  static const Color _onSurface = Color(0xFFFFF8E1); // Ana Metin Rengi (Açık Krem/Bej)
  static const Color _onSurfaceVariant = Color(0xFFD7CCC8); // İkincil Metin/İkon (Açık Bej/Gri)
  static const Color _scaffoldBg = Color(0xFF3E2723); // Genel Arka Plan (En Koyu Kahve)
  static const Color _outline = Color(0xFF8D6E63); // Kenarlıklar (Orta Kahve)
  static const Color _onSecondary = Color(0xFF3E2723); // İkincil üzerine Koyu Kahve yazı

  // --- Varyant Tanımları ---
  // İsimler aynı kalabilir veya "Koyu Deri" gibi güncellenebilir
  static final AppThemeData small = _create(
    type: NotebookThemeType.classicLeatherSmall,
    name: "Deri (Küçük)", // İsim güncellendi
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.classicLeatherMedium,
    name: "Deri (Orta)", // İsim güncellendi
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.classicLeatherLarge,
    name: "Deri (Büyük)", // İsim güncellendi
    fontSize: ThemeConfigBase.globalBodySizeLarge,
    letterSpacing: ThemeConfigBase.globalLetterSpacingLarge,
  );

  // --- Bu Stile Özel Tema Oluşturucu (_create - Güncellenmiş Renklerle) ---
  static AppThemeData _create({
    required NotebookThemeType type,
    required String name,
    required double fontSize,
    required double letterSpacing,
  }) {
    // Arka plan koyu olduğu için Brightness.dark kullanmak daha uygun olabilir
    final Brightness brightness = Brightness.dark;
    // Font Seçimi (Orijinaldeki gibi kalabilir veya değiştirilebilir)
    final TextTheme baseText = GoogleFonts.dancingScriptTextTheme(ThemeData(brightness: brightness).textTheme);
    final String decorativeFont = GoogleFonts.cinzelDecorative().fontFamily!;

    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true, // Orijinal tema ücretsizdi
      materialTheme: ThemeData(
        brightness: brightness, // Karanlık mod
        scaffoldBackgroundColor: _scaffoldBg, // Koyu kahve arka plan
        colorScheme: ColorScheme( // Yeni renk paleti
          brightness: brightness,
          primary: _primary, // Açık kahve vurgu
          onPrimary: _onPrimary, // Koyu kahve yazı
          secondary: _secondary, // Diğer açık kahve/bej
          onSecondary: _onSecondary, // Koyu kahve yazı
          error: Colors.redAccent, // Karanlık moda uygun hata rengi
          onError: Colors.black,
          surface: _surface, // Orta/Koyu kahve yüzey
          onSurface: _onSurface, // Açık krem metin
          surfaceContainer: _surfaceContainer, // Farklı kahve container
          onSurfaceVariant: _onSurfaceVariant, // Açık bej/gri ikincil
          outline: _outline, // Orta kahve kenarlık
        ),
        textTheme: ThemeConfigBase.buildTextTheme(
          baseTextTheme: baseText, // Dancing Script
          decorativeFontFamily: decorativeFont, // Cinzel Decorative
          baseColor: _onSurface, // Ana metin rengi AÇIK KREM
          bodyItalic: false,
          decorativeBold: true,
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme(
          foregroundColor: _onSurface, // Açık renk başlık
          fontFamily: decorativeFont,
          fontSize: 24,
          backgroundColor: _scaffoldBg.withOpacity(0.9), // Hafif transparan koyu kahve
          elevation: 0,
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme( // Input alanı
          themeColor: _primary, // Açık kahve etiket/hint
          fillColor: _surfaceContainer.withOpacity(0.5), // Hafif opak container rengi dolgu
          isFilled: true, // Dolgulu yapalım
          borderRadius: 4.0, // Köşeli
          border: OutlineInputBorder( // İnce kenarlık
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(color: _outline.withOpacity(0.5), width: 1),
          ),
          labelAndHintStyle: GoogleFonts.cinzelDecorative( // Başlık fontuyla etiket
            color: _primary,
            fontSize: 20, // Boyutu ayarla
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme( // Butonlar
          backgroundColor: _primary, // Açık kahve buton
          foregroundColor: _onPrimary, // Koyu kahve yazı
          borderRadius: 4.0, // Köşeli
        ),
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _primary), // Açık kahve Text Buton
        cardTheme: ThemeConfigBase.buildCardTheme( // Kartlar
          color: _surfaceContainer, // Farklı kahve tonu kart arka planı
          elevation: 1, // Hafif gölge
          borderRadius: 6.0, // Hafif yuvarlak
        ),
        dividerTheme: DividerThemeData(color: _outline.withOpacity(0.4), thickness: 1), // Orta kahve ayırıcı
        iconTheme: IconThemeData(color: _onSurfaceVariant, size: 20), // Açık bej/gri ikonlar
      ),
    );
  }
}