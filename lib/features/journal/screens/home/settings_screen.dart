import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stacked_themes/stacked_themes.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart'; // Kendi import yolunuzu kullanın

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mevcut tema yöneticisini al
    final themeManager = getThemeManager(context);
    // Mevcut seçili tema indeksini al (varsayılan 0)
    int currentThemeIndex = themeManager.selectedThemeIndex ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('Tema Seçimi')),
      body: ListView.builder(
        // ThemeConfig'deki tema sayısı kadar öğe oluştur
        itemCount: ThemeConfig.themes.length,
        itemBuilder: (context, index) {
          // O indeksteki tema verisini al
          final themeInfo = ThemeConfig.getAppThemeDataByIndex(index);

          // Ücretli tema ise ve kilidi açılmamışsa farklı göster (Bu kısım için ek mantık gerekir)
          bool isLocked = !themeInfo.isFree /* && !userHasPurchased(themeInfo.type) */; // Satın alma kontrolü eklenmeli

          return ListTile(
            title: Text(themeInfo.name), // Temanın adını göster
            leading: Icon(
              currentThemeIndex == index
                  ? Icons.check_circle // Seçili ise işaretli ikon
                  : Icons.circle_outlined, // Seçili değilse boş ikon
              color: Theme.of(context).colorScheme.primary,
            ),
            trailing: isLocked ? Icon(Icons.lock, color: Colors.grey) : null, // Kilitli ise kilit ikonu
            onTap: isLocked
                ? () {
              // Ücretli ve kilitli tema tıklandığında satın alma işlemi başlatılabilir
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${themeInfo.name} temasını satın almanız gerekiyor.')),
              );
            }
                : () {
              // Kilitli değilse veya ücretsizse, temayı seç
              if (kDebugMode) {
                print('Selecting theme at index: $index');
              }
              // ThemeManager aracılığıyla temayı değiştir!
              themeManager.selectThemeAtIndex(index);
            },
            // Kilitli temaları biraz soluk gösterelim
            enabled: !isLocked,
            tileColor: isLocked ? Colors.grey.withOpacity(0.1) : null,
          );
        },
      ),
    );
  }

// Gerçek uygulamada bu fonksiyon uygulama içi satın alma durumunu kontrol etmeli
// bool userHasPurchased(NotebookThemeType themeType) {
//   // Satın alma durumunu kontrol etme mantığı...
//   return false; // Şimdilik hep kilitli varsayalım
// }
}