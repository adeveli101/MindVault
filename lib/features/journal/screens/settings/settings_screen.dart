import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/settings/lock/security_settings_screen.dart';
import 'package:mindvault/features/journal/screens/settings/settings_theme_screen.dart';
// ========== !!! IMPORT YOLLARINI KONTROL ET VE TUTARLI YAP !!! ==========


class SettingsHostScreen extends StatelessWidget {
  const SettingsHostScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // Bu AppBar MainScreen'deki tarafından gizlenebilir veya kullanılabilir.
        // Eğer MainScreen'de merkezi AppBar yoksa burası görünür.
        title: const Text('Ayarlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.secondary),
            title: const Text('Görünüm ve Tema'),
            subtitle: const Text('Tema, yazı tipi ve boyut ayarları'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsThemeScreen()),
              );
            },
          ),
          const Divider(), // Ayırıcı
          // Diğer ayar öğeleri
          ListTile(
            leading: Icon(Icons.security_outlined, color: Theme.of(context).colorScheme.secondary),
            title: const Text('Güvenlik'),
            subtitle: const Text('Şifre, biyometrik kilit'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.secondary),
            title: const Text('Bildirimler'),
            subtitle: const Text('Yazma hatırlatıcıları'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () { /* TODO */ },
          ),
          ListTile(
            leading: Icon(Icons.cloud_outlined, color: Theme.of(context).colorScheme.secondary),
            title: const Text('Yedekleme & Geri Yükleme'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () { /* TODO */ },
          ),
        ],
      ),
    );
  }
}