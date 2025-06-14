// lib/features/settings/screens/settings_host_screen.dart
// Yolların doğruluğundan emin olun!

// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // BlocProvider ve BlocBuilder için eklendi
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mindvault/features/journal/screens/settings/lock/security_settings_screen.dart';
import 'package:mindvault/features/journal/screens/settings/notification/settings_notification_screen.dart';
import 'package:mindvault/features/journal/screens/settings/settings_theme_screen.dart';
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';
import 'package:mindvault/features/journal/subscription/subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindvault/features/journal/screens/home/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:mindvault/features/journal/providers/locale_provider.dart';

class SettingsHostScreen extends StatefulWidget {
  const SettingsHostScreen({super.key});

  @override
  State<SettingsHostScreen> createState() => _SettingsHostScreenState();
}

class _SettingsHostScreenState extends State<SettingsHostScreen> {

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    
    if (mounted) {
      // Dil değişikliğini kaydet ve uygulamayı yeniden başlat
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent, // ThemedBackground varsa
      appBar: AppBar(
        title: Text(l10n.settings),
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
              String title = l10n.premium;
              String subtitle = l10n.upgradeToPremium;
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
                  title = l10n.premium;
                  subtitle = l10n.premiumActive;
                  leadingIcon = Icons.star_rounded;
                  iconColor = Colors.amber.shade700; // Premium için farklı renk
                } else {
                  title = l10n.upgradeToPremium;
                  subtitle = l10n.upgradeToPremiumDescription;
                  iconColor = colorScheme.primary; // Yükseltme için dikkat çekici renk
                }
              } else if (state is SubscriptionLoading) {
                subtitle = l10n.loading;
              } else if (state is SubscriptionError) {
                subtitle = l10n.error;
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
                  subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  trailing: (state is SubscriptionLoading)
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Icon(Icons.arrow_forward_ios_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
            title: Text(l10n.theme),
            subtitle: Text(l10n.themeDescription),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
            title: Text(l10n.security),
            subtitle: Text(l10n.securityDescription),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
            title: Text(l10n.notifications),
            subtitle: Text(l10n.notificationsDescription),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsNotificationScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.language, color: colorScheme.primary),
            title: Text(l10n.language),
            subtitle: Text(currentLanguage == 'tr' ? 'Türkçe' : 'English'),
            trailing: DropdownButton<String>(
              value: currentLanguage,
              items: [
                DropdownMenuItem(
                  value: 'tr',
                  child: Text('Türkçe'),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  localeProvider.setLocale(value);
                }
              },
            ),
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