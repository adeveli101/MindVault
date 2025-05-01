// lib/features/journal/screens/themes/theme_data/light_theme_style.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı kontrol edin. ***
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/theme_config_base.dart';
// *******************************

class LightThemeStyle {
  // Bu stile özel sabitler
  static const String _bgPath = 'assets/pages/light/light_page1.jpg'; // Asset yolunu kontrol edin
  static const Color _primary = Color(0xFF00796B);
  static const Color _secondary = Color(0xFF004D40);
  static const Color _onPrimary = Colors.white;
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceContainer = Color(0xFFE0F2F1); // Eski surfaceContainerHighest yerine
  static const Color _onSurface = Color(0xFF263238);
  static const Color _onSurfaceVariant = Color(0xFF37474F);
  static const Color _scaffoldBg = Color(0xFFFAFAFA);

  // Varyantları tanımla
  static final AppThemeData small = _create(
    type: NotebookThemeType.defaultLightSmall,
    name: "Aydınlık Yazı (Küçük)",
    fontSize: ThemeConfigBase.globalBodySizeSmall,
    letterSpacing: ThemeConfigBase.globalLetterSpacingSmall,
  );
  static final AppThemeData medium = _create(
    type: NotebookThemeType.defaultLightMedium,
    name: "Aydınlık Yazı (Orta)",
    fontSize: ThemeConfigBase.globalBodySizeMedium,
    letterSpacing: ThemeConfigBase.globalLetterSpacingMedium,
  );
  static final AppThemeData large = _create(
    type: NotebookThemeType.defaultLightLarge,
    name: "Aydınlık Yazı (Büyük)",
    fontSize: ThemeConfigBase.globalBodySizeLarge,
    letterSpacing: ThemeConfigBase.globalLetterSpacingLarge,
  );

  // Bu stile özel _create metodu
  static AppThemeData _create({
    required NotebookThemeType type,
    required String name,
    required double fontSize,
    required double letterSpacing,
  }) {
    final Brightness brightness = Brightness.light;
    return AppThemeData(
      type: type,
      name: name,
      backgroundAssetPath: _bgPath,
      isFree: true,
      materialTheme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        colorScheme: ColorScheme( // Renkleri buradan ayarla
          brightness: brightness,
          primary: _primary,
          onPrimary: _onPrimary,
          secondary: _secondary,
          onSecondary: _onPrimary,
          error: Colors.redAccent,
          onError: Colors.white,
          surface: _surface,
          onSurface: _onSurface,
          // surfaceContainerHighest yerine surfaceContainer kullanıldı (M3'e daha uygun)
          surfaceContainer: _surfaceContainer,
          onSurfaceVariant: _onSurfaceVariant,
          // Diğer M3 renklerini de tanımlamak iyi olabilir:
          // tertiary, onTertiary, surfaceBright, surfaceDim, etc.
        ),
        textTheme: ThemeConfigBase.buildTextTheme( // Global helper kullanıldı
          baseTextTheme: GoogleFonts.caveatTextTheme(ThemeData(brightness: brightness).textTheme),
          decorativeFontFamily: GoogleFonts.cinzelDecorative().fontFamily!,
          baseColor: _onSurface,
          bodyItalic: true,
          decorativeBold: true,
          bodyFontSize: fontSize,
          bodyLetterSpacing: letterSpacing,
        ),
        appBarTheme: ThemeConfigBase.buildAppBarTheme(
          foregroundColor: _onSurface,
          fontFamily: GoogleFonts.cinzelDecorative().fontFamily!,
          fontSize: 22,
        ),
        inputDecorationTheme: ThemeConfigBase.buildInputDecorationTheme(
          themeColor: _primary,
          // surfaceContainerHighest yerine surfaceContainer kullanıldı
          fillColor: _surfaceContainer.withOpacity(0.5),
          isFilled: true,
          borderRadius: 8.0,
          border: InputBorder.none,
          labelAndHintStyle: GoogleFonts.cinzelDecorative(
              color: _primary, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        elevatedButtonTheme: ThemeConfigBase.buildElevatedButtonTheme(
          backgroundColor: _primary,
          foregroundColor: _onPrimary,
          borderRadius: 20.0,
        ),
        textButtonTheme: ThemeConfigBase.buildTextButtonTheme(primaryColor: _primary),
        cardTheme: ThemeConfigBase.buildCardTheme(
          color: _surface, elevation: 1, borderRadius: 8.0,
        ),
      ),
    );
  }
}