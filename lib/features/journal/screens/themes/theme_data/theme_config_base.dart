// lib/features/journal/screens/themes/theme_data/theme_config_base.dart

import 'package:flutter/material.dart';

/// Tüm temalar tarafından kullanılabilen global sabitler ve yardımcı fonksiyonlar.
class ThemeConfigBase {
  // === BİRLEŞTİRİLMİŞ Boyut ve Aralık Sabitleri ===
  static const double globalBodySizeSmall = 21.0;
  static const double globalLetterSpacingSmall = 0.3;

  static const double globalBodySizeMedium = 24.0;
  static const double globalLetterSpacingMedium = 0.4;

  static const double globalBodySizeLarge = 27.0;
  static const double globalLetterSpacingLarge = 0.5;
  // =====================================================

  // --- GENEL YARDIMCI FONKSİYONLAR ---

  /// Tüm temalar için ortak kullanılabilecek TextTheme oluşturucu.
  static TextTheme buildTextTheme({
    required TextTheme baseTextTheme,
    required String decorativeFontFamily,
    required double bodyFontSize,
    required double bodyLetterSpacing,
    Color? baseColor,
    bool bodyItalic = false,
    bool decorativeBold = false,
  }) {
    final coloredTheme = baseTextTheme.apply(
      bodyColor: baseColor,
      displayColor: baseColor,
      decorationColor: baseColor,
    );
    final bodyStyleLarge = coloredTheme.bodyLarge?.copyWith(
      fontSize: bodyFontSize,
      letterSpacing: bodyLetterSpacing,
      fontStyle: bodyItalic ? FontStyle.italic : FontStyle.normal,
      height: 1.7,
    );
    final bodyStyleMedium = coloredTheme.bodyMedium?.copyWith(
      fontStyle: bodyItalic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: 0.25,
      height: 1.6,
    );
    final bodyStyleSmall = coloredTheme.bodySmall?.copyWith(
      fontStyle: bodyItalic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: 0.4,
      height: 1.5,
    );
    final labelStyleLarge = coloredTheme.labelLarge?.copyWith(
      fontStyle: bodyItalic ? FontStyle.italic : FontStyle.normal,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
    final labelStyleMedium = coloredTheme.labelMedium?.copyWith(
      fontStyle: bodyItalic ? FontStyle.italic : FontStyle.normal,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    );
    final labelStyleSmall = coloredTheme.labelSmall?.copyWith(
      fontStyle: bodyItalic ? FontStyle.italic : FontStyle.normal,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    );
    final decorativeStyle = TextStyle(
      fontFamily: decorativeFontFamily,
      color: baseColor,
      fontWeight: decorativeBold ? FontWeight.w700 : FontWeight.normal,
    );
    final headingStyle = decorativeStyle.copyWith(fontWeight: FontWeight.w700);

    return coloredTheme.copyWith(
      displayLarge: headingStyle.copyWith(fontSize: 57, letterSpacing: -0.25),
      displayMedium: headingStyle.copyWith(fontSize: 45),
      displaySmall: headingStyle.copyWith(fontSize: 36),
      headlineLarge: headingStyle.copyWith(fontSize: 32),
      headlineMedium: decorativeStyle.copyWith(fontSize: 26),
      headlineSmall: headingStyle.copyWith(fontSize: 24),
      titleLarge: decorativeStyle.copyWith(fontSize: 22),
      titleMedium: headingStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: headingStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: bodyStyleLarge,
      bodyMedium: bodyStyleMedium,
      bodySmall: bodyStyleSmall,
      labelLarge: labelStyleLarge,
      labelMedium: labelStyleMedium,
      labelSmall: labelStyleSmall,
    );
  }

  /// Genel AppBarTheme oluşturucu.
  static AppBarTheme buildAppBarTheme({
    required Color foregroundColor,
    required String fontFamily,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? backgroundColor = Colors.transparent,
    double elevation = 0,
  }) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: elevation,
      foregroundColor: foregroundColor,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        color: foregroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      iconTheme: IconThemeData(color: foregroundColor, size: 20),
      actionsIconTheme: IconThemeData(color: foregroundColor, size: 20),
    );
  }

  /// Genel InputDecorationTheme oluşturucu.
  static InputDecorationTheme buildInputDecorationTheme({
    required Color themeColor,
    required Color fillColor,
    required bool isFilled,
    required double borderRadius,
    required TextStyle labelAndHintStyle,
    bool isDense = false,
    InputBorder? border,
  }) {
    final effectiveBorder = border ??
        (isFilled
            ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        )
            : const UnderlineInputBorder(borderSide: BorderSide.none));
    return InputDecorationTheme(
      filled: isFilled,
      fillColor: fillColor,
      border: effectiveBorder,
      enabledBorder: effectiveBorder,
      focusedBorder: effectiveBorder,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 12.0, horizontal: 5.0),
      isDense: isDense,
      labelStyle: labelAndHintStyle.copyWith(color: themeColor),
      hintStyle: labelAndHintStyle.copyWith(color: themeColor.withOpacity(0.6)),
    );
  }

  /// Genel ElevatedButtonThemeData oluşturucu.
  static ElevatedButtonThemeData buildElevatedButtonTheme({
    required Color backgroundColor,
    required Color foregroundColor,
    required double borderRadius,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        minimumSize: const Size(80, 36),
      ),
    );
  }

  /// Genel TextButtonThemeData oluşturucu.
  static TextButtonThemeData buildTextButtonTheme({required Color primaryColor}) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryColor),
    );
  }

  /// Genel CardTheme oluşturucu.
  static CardTheme buildCardTheme({
    required Color color,
    required double elevation,
    required double borderRadius,
  }) {
    return CardTheme(
      elevation: elevation,
      color: color,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius)),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
    );
  }
}