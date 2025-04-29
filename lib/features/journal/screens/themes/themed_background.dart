// lib/widgets/themed_background.dart (GÜNCELLENDİ)

import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:stacked_themes/stacked_themes.dart'; // stacked_themes import

class ThemedBackground extends StatelessWidget {
  final Widget child;
  // Overlay hâlâ kullanılacaksa bu parametre kalabilir.
  final bool applyOverlay;

  const ThemedBackground({
    super.key,
    required this.child,
    this.applyOverlay = false, // Tam sayfa görseliyle overlay varsayılan olmasın
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = getThemeManager(context);
    final int currentThemeIndex = themeManager.selectedThemeIndex ?? 0;
    final AppThemeData currentAppTheme = ThemeConfig.getAppThemeDataByIndex(currentThemeIndex); //

    // Ana Container: Arka plan rengini buradan alacak
    return Container(
      // Arka plan rengini temadan alıyoruz. Bu renk, görselin
      // dikey olarak yetmediği kısımlarda (üstte ve altta) görünecek.
      color: currentAppTheme.materialTheme.colorScheme.surface, //
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Katman: Ana Arka Plan Görseli (Sayfa)
          Image.asset(
            currentAppTheme.backgroundAssetPath, //
            // Genişliğe sığdır, aspect ratio'yu koru
            fit: BoxFit.fill,
            // alignment: Alignment.topCenter, // <-- KALDIRILDI (Dikeyde ortalanacak)

            // Not: BoxFit.fitWidth kullanıldığında, görselin en/boy oranı
            // ekranın en/boy oranından farklıysa, dikeyde (üstte ve altta)
            // boşluk kalabilir. Bu boşluklar yukarıdaki Container'ın rengiyle dolar.
            // Eğer görselin HER ZAMAN tüm ekranı boşluksuz kaplaması gerekiyorsa
            // (kenarlardan veya üstten/alttan kırpılma pahasına),
            // fit: BoxFit.cover kullanmalısınız.
          ),

          // 2. Katman: Kaplama Görseli (isteğe bağlı)
          // Bu kısım önceki gibi kalabilir veya isteğe bağlı olarak silebilirsiniz.
          if (applyOverlay) //
            Image.asset(
              currentAppTheme.backgroundAssetPath, //
              fit: BoxFit.cover,
              color: currentAppTheme.materialTheme.brightness == Brightness.dark //
                  ? Colors.black.withOpacity(0.15)
                  : null,
              colorBlendMode: currentAppTheme.materialTheme.brightness == Brightness.dark //
                  ? BlendMode.darken
                  : null,
            ),

          // 3. Katman: Asıl İçerik (Scaffold vb.)
          child,
        ],
      ),
    );
  }
}