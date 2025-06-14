// lib/features/journal/screens/home/home_screen.dart (Abonelik Butonu Eklendi)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // BlocBuilder için eklendi
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Kendi proje yollarınızı kontrol edin!
import 'package:mindvault/features/journal/screens/home/onboarding_screen.dart';
// Abonelikle ilgili importlar - KENDİ YOLUNUZU KULLANIN!
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart'; // VEYA features/subscription/bloc/...
import 'package:mindvault/features/journal/subscription/subscription_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Mevcut temayı ve renkleri al
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Görüntülenecek tarih
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, EEEE', l10n.localeName).format(now);

    return Stack(
      children: [
        // 1. Ortalanmış Ana İçerik (Değişiklik Yok)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 70,
                  color: colorScheme.primary.withOpacity(0.9),
                ),
                Text(
                  l10n.appTitle,
                  style: textTheme.headlineLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  formattedDate,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 85),
                Text(
                  l10n.homeQuote,
                  style: textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withOpacity(0.75),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // 2. "Why Mind Vault?" İkonu (Sağ Üst - Değişiklik Yok)
        Positioned(
          top: 35.0,
          right: 30.0,
          child: IconButton(
            icon: Icon(
                Icons.info_outline,
                color: colorScheme.primary.withOpacity(0.8),
                size: 31
            ),
            tooltip: l10n.whyMindVault,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          ),
        ),

        // 3. YENİ: Abonelik Durum Göstergesi/Butonu (Sol Üst - ActionChip)
        Positioned(
          top: 35.0, // Bilgi butonuyla aynı hizada veya isteğe göre ayarlayın
          left: 30.0,  // Sol kenardan boşluk
          child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              bool isSubscribed = false;
              bool isLoading = false;
              IconData iconData = Icons.workspace_premium_outlined;
              String labelText = l10n.freemium;
              String tooltipText = l10n.upgradeToPremium;
              Color chipBackgroundColor = colorScheme.secondaryContainer.withOpacity(0.8); // Freemium arka plan
              Color contentColor = colorScheme.onSecondaryContainer; // Freemium içerik rengi
              BorderSide? borderSide = BorderSide(color: colorScheme.secondary.withOpacity(0.6)); // Freemium kenarlık

              if (state is SubscriptionLoaded) {
                isSubscribed = state.isSubscribed;
                if (isSubscribed) {
                  iconData = Icons.workspace_premium_rounded;
                  labelText = l10n.premium;
                  tooltipText = l10n.premiumMember;
                  chipBackgroundColor = Colors.amber.shade700.withOpacity(0.9); // Premium arka plan (altın)
                  contentColor = Colors.white; // Premium içerik rengi
                  borderSide = null; // Premium için kenarlık yok
                }
              } else if (state is SubscriptionLoading || state is SubscriptionInitial) {
                isLoading = true;
              }
              // SubscriptionError durumu için de Freemium görünümü kalabilir veya farklı bir stil uygulanabilir.

              // Yükleniyorsa küçük bir gösterge
              if (isLoading) {
                return Padding(
                  padding: const EdgeInsets.all(12.0), // Chip padding'ine benzer
                  child: SizedBox(
                      width: 16, // Küçük boyut
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: colorScheme.secondary,
                      )
                  ),
                );
              }

              // Yüklenmiyorsa ActionChip'i döndür
              return Tooltip( // ActionChip'in kendi tooltip'i bazen yetersiz kalabilir
                message: tooltipText,
                child: ActionChip(
                  avatar: Icon(
                    iconData,
                    color: contentColor, // İkon rengi
                    size: 18,
                  ),
                  label: Text(
                    labelText,
                    style: TextStyle(
                        color: contentColor, // Metin rengi
                        fontWeight: FontWeight.bold,
                        fontSize: 13 // Biraz küçültebiliriz
                    ),
                  ),
                  onPressed: () {
                    // Her durumda sheet'i açalım
                    showSubscriptionSheet(context);
                  },
                  backgroundColor: chipBackgroundColor,
                  side: borderSide,
                  elevation: isSubscribed ? 3 : 1, // Premium ise hafif gölge
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // İç boşluklar
                  shape: StadiumBorder(), // Yuvarlak kenarlı
                ),
              );
            },
          ),
        ),

        // 4. En Alt Ortadaki Gizlilik Bilgisi Metni (Varsa)
        // Eğer varsa, bu Positioned widget burada kalabilir.
      ],
    );
  }
}