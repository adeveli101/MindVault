// lib/features/journal/screens/home/onboarding_screen.dart
// Tema entegrasyonu için ThemedBackground eklendi (isteğe bağlı)
// kDebugMode kontrolleri eklendi

// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/home/main_screen.dart'; // MainScreen'e yönlendirme için
import 'package:mindvault/features/journal/screens/themes/themed_background.dart'; // Tema arka planı için
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  // static const String routeName = '/onboarding'; // Eğer route kullanıyorsanız kalabilir

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Onboarding'in tamamlandığını işaretler ve ana ekrana geçer.
  Future<void> _completeOnboarding() async {
    // Async işlem öncesi context kontrolü için navigator alalım
    final navigator = Navigator.of(context);
    // SharedPreferences erişimi
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (kDebugMode) { print("Onboarding complete flag set to true."); }

    // mounted kontrolü async gap sonrası önemli
    if (!mounted) return;

    if (kDebugMode) { print("Navigating to MainScreen after onboarding."); }
    // Navigator.pushReplacement yerine pushAndRemoveUntil daha temiz olabilir
    // ama pushReplacement da çalışır.
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()), // MainScreen'e yönlendir
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _isLastPage = index == 2;
                    });
                  },
                  children: [
                    _OnboardingPage(
                      imagePath: 'assets/images/onboarding/welcome.png',
                      title: l10n.onboardingWelcomeTitle,
                      description: l10n.onboardingWelcomeDescription,
                    ),
                    _OnboardingPage(
                      imagePath: 'assets/images/onboarding/privacy.png',
                      title: l10n.onboardingPrivacyTitle,
                      description: l10n.onboardingPrivacyDescription,
                      iconData: Icons.lock_person_rounded,
                    ),
                    _OnboardingPage(
                      imagePath: 'assets/images/onboarding/start.png',
                      title: l10n.onboardingStartTitle,
                      description: l10n.onboardingStartDescription,
                      iconData: Icons.auto_stories_rounded,
                    ),
                  ],
                ),
              ),
              _buildBottomSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedOpacity(
            opacity: _isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: _isLastPage
                ? const SizedBox(width: 60)
                : TextButton(
                    onPressed: _isLoading ? null : _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant
                    ),
                    child: Text(l10n.skip),
                  ),
          ),
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: WormEffect(
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            onDotClicked: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut
              );
            },
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (_isLastPage) {
                setState(() { _isLoading = true; });
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _isLoading && _isLastPage
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3
                    )
                  )
                : Icon(
                    _isLastPage ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                    size: 24
                  ),
          ),
        ],
      ),
    );
  }
  // Yükleme durumu için state değişkeni (isteğe bağlı)
  bool _isLoading = false;
}


// _OnboardingPage widget'ı büyük ölçüde aynı kalabilir, temayı zaten kullanıyor.
class _OnboardingPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final IconData? iconData;

  const _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context); // Tek seferde alalım
    final l10n = AppLocalizations.of(context)!;

    // Resim yolunu kontrol et (hata ayıklama için)
    // Örnek: Hata durumunda yer tutucu gösterme
    Widget imageWidget;
    try {
      // Bu kısım assets eklenince düzgün çalışacaktır.
      imageWidget = Image.asset(
        imagePath,
        height: mediaQuery.size.height * 0.35,
        fit: BoxFit.contain,
        // Hata durumunda ne olacağını belirlemek için errorBuilder eklenebilir
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) { print("Onboarding image error: $error"); }
          return Icon(Icons.image_not_supported_outlined, size: 50, color: colorScheme.outline);
        },
      );
    } catch (e) {
      if (kDebugMode) { print("Onboarding image load failed: $e"); }
      imageWidget = Icon(Icons.image_not_supported_outlined, size: 50, color: colorScheme.outline);
    }


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          if (iconData != null) ...[
            Icon(iconData, size: 50, color: colorScheme.secondary),
            const SizedBox(height: 20),
          ],

          // Resim
          imageWidget, // Hata kontrolü eklenmiş widget
          const SizedBox(height: 40),

          // Başlık
          Text( title, textAlign: TextAlign.center, style: textTheme.headlineMedium?.copyWith( color: colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // Açıklama
          Text( description, textAlign: TextAlign.center, style: textTheme.bodyLarge?.copyWith( color: colorScheme.onSurfaceVariant, height: 1.5)),
        ],
      ),
    );
  }
}