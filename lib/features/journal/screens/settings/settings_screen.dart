// lib/features/settings/screens/settings_host_screen.dart
// Yolların doğruluğundan emin olun!

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // BlocProvider ve BlocBuilder için eklendi
import 'package:mindvault/features/journal/screens/settings/lock/security_settings_screen.dart';
import 'package:mindvault/features/journal/screens/settings/notification/settings_notification_screen.dart';
import 'package:mindvault/features/journal/screens/settings/settings_theme_screen.dart';
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';
import 'package:mindvault/features/journal/subscription/subscription_screen.dart';

class SettingsHostScreen extends StatelessWidget {
  const SettingsHostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Abonelik durumunu almak için SubscriptionBloc'a erişim sağlayalım.
    // Eğer BlocProvider daha üst bir widget ağacında değilse, burada veya main.dart'ta sağlanmalı.
    // Bu örnekte, BlocProvider'ın daha üstte olduğunu varsayıyoruz.
    // İlk yüklemede abonelik durumunu getirmek için bir olay tetikleyebiliriz.
    // Ancak genellikle bu tür veriler uygulama başlarken veya ilgili BLoC ilk kez çağrıldığında yüklenir.
    // SubscriptionScreen'in initState'inde bu zaten yapılıyor.

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceVariantColor = colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: Colors.transparent, // ThemedBackground varsa
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Geri butonu otomatik olarak eklenir (Navigator.push kullanıldığı için)
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Premium / Abonelik Bölümü ---
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            // buildWhen: (previous, current) => previous.runtimeType != current.runtimeType, // Sadece durum tipi değiştiğinde rebuild et
            builder: (context, state) {
              bool isSubscribed = false;
              String title = 'MindVault Premium';
              String subtitle = 'Tüm temalara ve özelliklere erişin';
              IconData leadingIcon = Icons.star_outline_rounded;
              Color iconColor = colorScheme.secondary; // Varsayılan renk
              onTapAction() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              }

              if (state is SubscriptionLoaded) {
                isSubscribed = state.isSubscribed;
                if (isSubscribed) {
                  title = 'Premium Üye';
                  subtitle = 'Tüm özellikler aktif';
                  leadingIcon = Icons.star_rounded;
                  iconColor = Colors.amber.shade700; // Premium için farklı renk
                } else {
                  title = 'Premium\'a Yükselt';
                  subtitle = 'Sınırsız tema ve özellikler için';
                  iconColor = colorScheme.primary; // Yükseltme için dikkat çekici renk
                }
              } else if (state is SubscriptionLoading) {
                subtitle = 'Abonelik durumu yükleniyor...';
              } else if (state is SubscriptionError) {
                subtitle = 'Abonelik durumu alınamadı';
                iconColor = colorScheme.error;
              }
              // Diğer durumlar için (Initial) varsayılan değerler kullanılır.

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: iconColor.withOpacity(0.5), width: isSubscribed ? 1.5 : 1)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Icon(leadingIcon, color: iconColor, size: 28),
                  title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: iconColor)),
                  subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: onSurfaceVariantColor)),
                  trailing: (state is SubscriptionLoading)
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Icon(Icons.arrow_forward_ios_rounded, size: 18, color: onSurfaceVariantColor),
                  onTap: (state is SubscriptionLoading) ? null : onTapAction,
                  tileColor: iconColor.withOpacity(0.05),
                ),
              );
            },
          ),
          const Divider(height: 24),

          // --- Mevcut Ayar Öğeleri ---
          ListTile(
            leading: Icon(Icons.palette_outlined, color: colorScheme.secondary),
            title: const Text('Görünüm ve Tema'),
            subtitle: const Text('Tema, yazı tipi ve boyut ayarları'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: onSurfaceVariantColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsThemeScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.security_outlined, color: colorScheme.secondary),
            title: const Text('Güvenlik'),
            subtitle: const Text('Şifre, biyometrik kilit'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: onSurfaceVariantColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: colorScheme.secondary),
            title: const Text('Bildirimler'),
            subtitle: const Text('Yazma hatırlatıcıları'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: onSurfaceVariantColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsNotificationScreen()),
              );
            },
          ),
          const Divider(),
          // İleride eklenebilecek diğer ayarlar...
          // ListTile(
          //   leading: Icon(Icons.info_outline_rounded, color: colorScheme.secondary),
          //   title: const Text('Hakkında'),
          //   subtitle: const Text('Uygulama sürümü ve lisanslar'),
          //   trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: onSurfaceVariantColor),
          //   onTap: () { /* Hakkında sayfasına git */ },
          // ),
        ],
      ),
    );
  }
}