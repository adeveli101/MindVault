import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// mindvault/features/journal/model/journal_entry.dart yolunu kendi projenize göre doğrulayın
import 'package:mindvault/features/journal/model/journal_entry.dart';

class MindVaultTheme {
  // --- Renk Paleti Tohumları ---
  static const Color _lightSeedColor = Color(0xFF6750A4);
  static const Color _darkSeedColor = Color(0xFFD0BCFF);

  // --- Açık Tema (Light Theme) ---
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true); // Material 3'ü etkinleştir
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lightSeedColor,
      brightness: Brightness.light,
      // İstersen dinamik renkleri devre dışı bırakmak için:
      // dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    final textTheme = _buildTextTheme(baseTheme.textTheme, colorScheme.onSurface);

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(baseTheme.appBarTheme, colorScheme, textTheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(baseTheme.elevatedButtonTheme, colorScheme, textTheme),
      textButtonTheme: _buildTextButtonTheme(baseTheme.textButtonTheme, colorScheme, textTheme),
      cardTheme: _buildCardTheme(baseTheme.cardTheme, colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(baseTheme.inputDecorationTheme, colorScheme, textTheme),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(baseTheme.floatingActionButtonTheme, colorScheme),
      dialogTheme: _buildDialogTheme(baseTheme.dialogTheme, colorScheme, textTheme),
      chipTheme: _buildChipTheme(baseTheme.chipTheme, colorScheme, textTheme),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(baseTheme.bottomNavigationBarTheme, colorScheme, textTheme),
      scaffoldBackgroundColor: colorScheme.surface, // M3'te 'background' yerine 'surface' daha yaygın
      // Diğer widget temaları eklenebilir
    );
  }

  // --- Koyu Tema (Dark Theme) ---
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true); // Material 3'ü etkinleştir
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkSeedColor,
      brightness: Brightness.dark,
    );

    final textTheme = _buildTextTheme(baseTheme.textTheme, colorScheme.onSurface);

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(baseTheme.appBarTheme, colorScheme, textTheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(baseTheme.elevatedButtonTheme, colorScheme, textTheme),
      textButtonTheme: _buildTextButtonTheme(baseTheme.textButtonTheme, colorScheme, textTheme),
      cardTheme: _buildCardTheme(baseTheme.cardTheme, colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(baseTheme.inputDecorationTheme, colorScheme, textTheme),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(baseTheme.floatingActionButtonTheme, colorScheme),
      dialogTheme: _buildDialogTheme(baseTheme.dialogTheme, colorScheme, textTheme),
      chipTheme: _buildChipTheme(baseTheme.chipTheme, colorScheme, textTheme),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(baseTheme.bottomNavigationBarTheme, colorScheme, textTheme),
      scaffoldBackgroundColor: colorScheme.surface,
      // Diğer widget temaları eklenebilir
    );
  }

  // --- Metin Teması Oluşturucu (Mevcut haliyle bırakıldı, fontlar aynı) ---
  static TextTheme _buildTextTheme(TextTheme base, Color bodyColor) {
    // GoogleFonts kullanılıyorsa, internet bağlantısı gerektirebilir veya fontları projeye dahil etmek gerekebilir.
    // Font stillerini Material 3 tipografi skalasına (display, headline, title, body, label) göre ayarlamak daha iyi olabilir.
    // Mevcut kodunuzdaki gibi bırakıyorum:
    return base.copyWith(
      displayLarge: GoogleFonts.cinzelDecorative(textStyle: base.displayLarge?.copyWith(color: bodyColor, fontWeight: FontWeight.bold)),
      displayMedium: GoogleFonts.cinzelDecorative(textStyle: base.displayMedium?.copyWith(color: bodyColor, fontWeight: FontWeight.bold)),
      displaySmall: GoogleFonts.cinzelDecorative(textStyle: base.displaySmall?.copyWith(color: bodyColor)),
      headlineLarge: GoogleFonts.cinzel(textStyle: base.headlineLarge?.copyWith(color: bodyColor, fontWeight: FontWeight.bold)),
      headlineMedium: GoogleFonts.cinzel(textStyle: base.headlineMedium?.copyWith(color: bodyColor, fontWeight: FontWeight.bold)),
      headlineSmall: GoogleFonts.cinzel(textStyle: base.headlineSmall?.copyWith(color: bodyColor)),
      titleLarge: GoogleFonts.cabin(textStyle: base.titleLarge?.copyWith(color: bodyColor, fontWeight: FontWeight.bold)),
      titleMedium: GoogleFonts.cabin(textStyle: base.titleMedium?.copyWith(color: bodyColor, fontWeight: FontWeight.bold)),
      titleSmall: GoogleFonts.cabin(textStyle: base.titleSmall?.copyWith(color: bodyColor, fontWeight: FontWeight.w500)),
      bodyLarge: GoogleFonts.cabin(textStyle: base.bodyLarge?.copyWith(color: bodyColor)),
      bodyMedium: GoogleFonts.cabin(textStyle: base.bodyMedium?.copyWith(color: bodyColor)),
      bodySmall: GoogleFonts.cabin(textStyle: base.bodySmall?.copyWith(color: bodyColor.withOpacity(0.8))),
      labelLarge: GoogleFonts.cabin(textStyle: base.labelLarge?.copyWith(color: bodyColor, fontWeight: FontWeight.bold)),
      labelMedium: GoogleFonts.cabin(textStyle: base.labelMedium?.copyWith(color: bodyColor, fontWeight: FontWeight.w500)),
      labelSmall: GoogleFonts.cabin(textStyle: base.labelSmall?.copyWith(color: bodyColor, fontWeight: FontWeight.w500)),
    ).apply(
      bodyColor: bodyColor,
      displayColor: bodyColor,
    );
  }

  // --- AppBar Teması ---
  static AppBarTheme _buildAppBarTheme(AppBarTheme base, ColorScheme colorScheme, TextTheme textTheme) {
    return base.copyWith(
      backgroundColor: colorScheme.surface, // Arka plan
      foregroundColor: colorScheme.onSurface, // İkonlar ve metin
      elevation: 0, // Gölge yok
      scrolledUnderElevation: 4.0, // Kaydırıldığında M3 yüzey rengi efekti için
      surfaceTintColor: colorScheme.surfaceTint, // M3 kaydırma efekti rengi
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant), // İkonlar için biraz farklı bir ton
      actionsIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    );
  }

  // --- ElevatedButton Teması ---
  static ElevatedButtonThemeData _buildElevatedButtonTheme(ElevatedButtonThemeData base, ColorScheme colorScheme, TextTheme textTheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // M3'te biraz daha yuvarlak
        ),
        elevation: 2, // Hafif yükseklik
        shadowColor: colorScheme.shadow.withOpacity(0.5),
      ).copyWith(
        // Farklı durumlar için stil (isteğe bağlı)
        // foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        //   if (states.contains(MaterialState.disabled)) {
        //     return colorScheme.onSurface.withOpacity(0.38);
        //   }
        //   return colorScheme.onPrimary;
        // }),
        // backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        //   if (states.contains(MaterialState.disabled)) {
        //     return colorScheme.onSurface.withOpacity(0.12);
        //   }
        //   return colorScheme.primary;
        // }),
      ),
    );
  }

  // --- TextButton Teması ---
  static TextButtonThemeData _buildTextButtonTheme(TextButtonThemeData base, ColorScheme colorScheme, TextTheme textTheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600), // Biraz daha kalın
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  // --- Card Teması ---
  static CardTheme _buildCardTheme(CardTheme base, ColorScheme colorScheme) {
    return base.copyWith(
      elevation: 1, // Düşük gölge
      // M3'te kartlar genellikle `surfaceContainerLow` veya `surfaceContainer` kullanır
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent, // Kartlar için tint genellikle istenmez
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        // İnce bir kenarlık ekleyebiliriz
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Yatay boşluk arttırıldı
    );
  }

  // --- InputDecoration (TextField vb.) Teması ---
  static InputDecorationTheme _buildInputDecorationTheme(InputDecorationTheme base, ColorScheme colorScheme, TextTheme textTheme) {
    return base.copyWith(
      filled: true,
      // Hafif bir dolgu rengi, surfaceContainerHighest iyi bir seçim olabilir
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.8),
      hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
      labelStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant), // Odaklanmadan önceki label rengi
      floatingLabelStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.primary), // Odaklanınca label rengi
      // Kenarlık stilleri
      border: OutlineInputBorder( // Varsayılan (enabled) kenarlık
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.outline, width: 1.0), // Hafif kenarlık
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.outline, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder( // Odaklanıldığında
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0), // Ana renkle belirginleştir
      ),
      errorBorder: OutlineInputBorder( // Hata durumunda
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder( // Hata durumunda odaklanıldığında
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.error, width: 2.0),
      ),
      disabledBorder: OutlineInputBorder( // Devre dışı bırakıldığında
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.12), width: 1.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // İç boşluk ayarı
    );
  }

  // --- FloatingActionButton Teması ---
  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme(FloatingActionButtonThemeData base, ColorScheme colorScheme) {
    return base.copyWith(
      // Genellikle `primaryContainer` veya `secondaryContainer` tercih edilir
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 4,
      hoverElevation: 6,
      focusElevation: 6,
      highlightElevation: 8,
      shape: RoundedRectangleBorder( // M3'te genellikle biraz daha köşeli (Squircle)
        borderRadius: BorderRadius.circular(16.0),
      ),
    );
  }

  // --- Dialog Teması ---
  static DialogTheme _buildDialogTheme(DialogTheme base, ColorScheme colorScheme, TextTheme textTheme) {
    return base.copyWith(
      backgroundColor: colorScheme.surfaceContainerHigh, // Diyaloglar için belirgin yüzey
      titleTextStyle: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.0), // M3'te diyaloglar daha yuvarlaktır
      ),
      elevation: 6, // Orta yükseklik
      actionsPadding: const EdgeInsets.all(24.0),
    );
  }

  // --- Chip Teması ---
  static ChipThemeData _buildChipTheme(ChipThemeData base, ColorScheme colorScheme, TextTheme textTheme) {
    return base.copyWith(
      backgroundColor: colorScheme.secondaryContainer.withOpacity(0.6), // Hafif arka plan
      labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSecondaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      shape: StadiumBorder( // Veya RoundedRectangleBorder
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      // selectedColor: colorScheme.primaryContainer, // Seçili chip rengi
      // secondarySelectedColor: colorScheme.primary, // Seçili chip üzerindeki ikon/metin rengi
      // checkmarkColor: colorScheme.onPrimaryContainer, // Seçili chip onay işareti
      elevation: 0.5,
      pressElevation: 1,
    );
  }

  // --- BottomNavigationBar Teması ---
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(BottomNavigationBarThemeData base, ColorScheme colorScheme, TextTheme textTheme) {
    return base.copyWith(
      backgroundColor: colorScheme.surfaceContainer, // Yüzey rengi
      selectedItemColor: colorScheme.onSurface, // Seçili ikon/metin rengi
      unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7), // Seçili olmayanlar
      selectedLabelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: textTheme.labelSmall,
      elevation: 2, // Hafif gölge
      type: BottomNavigationBarType.fixed, // Veya shifting
      // showSelectedLabels: true,
      // showUnselectedLabels: true,
    );
  }


  // --- Mood'a Göre Renkler (Fonksiyonlar Korundu) ---

  /// Belirtilen Mood için temsilci bir renk döndürür.
  static Color getColorForMood(Mood? mood, Brightness brightness) {
    final defaultColor = (brightness == Brightness.light)
        ? lightTheme.colorScheme.primaryContainer
        : darkTheme.colorScheme.primaryContainer;

    switch (mood) {
      case Mood.happy: return Colors.amber.shade300;
      case Mood.excited: return Colors.orange.shade400;
      case Mood.grateful: return Colors.lightGreen.shade300;
      case Mood.calm: return Colors.blue.shade200;
      case Mood.neutral: return Colors.grey.shade400;
      case Mood.sad: return Colors.blueGrey.shade300;
      case Mood.anxious: return Colors.deepPurple.shade200;
      case Mood.stressed: return Colors.red.shade300;
      case Mood.tired: return Colors.brown.shade300;
      case Mood.angry: return Colors.red.shade400;
      case Mood.unknown:
      default:
        return defaultColor;
    }
  }

  /// Mood renginin üzerine gelecek uygun metin/ikon rengini belirler.
  static Color getOnColorForMood(Color moodColor) {
    return ThemeData.estimateBrightnessForColor(moodColor) == Brightness.dark
        ? Colors.white
        : Colors.black87; // Saf siyah yerine biraz daha yumuşak bir ton
  }
}

// /// Mood renklerini tema ile birlikte kullanmak için ThemeExtension örneği (Opsiyonel)
// class MoodColors extends ThemeExtension<MoodColors> {
//   final Color happy;
//   final Color excited;
//   // ... diğer moodlar için renkler
//   final Color defaultMood;

//   const MoodColors({
//     required this.happy,
//     required this.excited,
//     required this.defaultMood,
//   });

//   @override
//   ThemeExtension<MoodColors> copyWith({
//     Color? happy,
//     Color? excited,
//     Color? defaultMood,
//   }) {
//     return MoodColors(
//       happy: happy ?? this.happy,
//       excited: excited ?? this.excited,
//       defaultMood: defaultMood ?? this.defaultMood,
//     );
//   }

//   @override
//   ThemeExtension<MoodColors> lerp(ThemeExtension<MoodColors>? other, double t) {
//     if (other is! MoodColors) {
//       return this;
//     }
//     return MoodColors(
//       happy: Color.lerp(happy, other.happy, t)!,
//       excited: Color.lerp(excited, other.excited, t)!,
//       defaultMood: Color.lerp(defaultMood, other.defaultMood, t)!,
//     );
//   }

//   // ThemeData içine eklemek için:
//   // extensions: <ThemeExtension<dynamic>>[
//   //   MoodColors(
//   //     happy: Colors.amber.shade300,
//   //     excited: Colors.orange.shade400,
//   //     defaultMood: colorScheme.primaryContainer,
//   //   ),
//   // ],

//   // Kullanım:
//   // final moodColors = Theme.of(context).extension<MoodColors>()!;
//   // Color color = moodColors.happy;
// }