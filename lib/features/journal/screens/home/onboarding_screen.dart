// lib/features/journal/screens/home/onboarding_screen.dart
// Tema entegrasyonu için ThemedBackground eklendi (isteğe bağlı)
// kDebugMode kontrolleri eklendi

import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/home/main_screen.dart'; // MainScreen'e yönlendirme için
import 'package:mindvault/features/journal/screens/themes/themed_background.dart'; // Tema arka planı için
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
    final theme = Theme.of(context); // Mevcut temayı al

    // Onboarding ekranını da temalı arka planla saralım
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // ThemedBackground görünsün diye
        body: SafeArea(
          child: Column(
            children: [
              // --- Sayfalar ---
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    // setState build içinde olmadığı için güvenli
                    setState(() {
                      _isLastPage = index == 2; // 3 sayfa varsayımı (0, 1, 2)
                    });
                  },
                  children: const [
                    // Sayfa içerikleri aynı kalabilir, _OnboardingPage widget'ı temayı zaten kullanıyor
                    _OnboardingPage(
                      imagePath: 'assets/images/onboarding_welcome.png',
                      title: 'Mind Vault\'a Hoş Geldiniz!',
                      description: 'Düşüncelerinizi, hislerinizi ve anılarınızı güvenle saklayacağınız kişisel dijital günlüğünüz.',
                    ),
                    _OnboardingPage(
                      imagePath: 'assets/images/onboarding_privacy.png',
                      title: 'Gizliliğiniz Önceliğimiz',
                      description: 'Tüm günlükleriniz güçlü şifreleme ile korunur ve sadece sizin cihazınızda saklanır. Verileriniz asla buluta gönderilmez veya paylaşılmaz.',
                      iconData: Icons.lock_person_rounded,
                    ),
                    _OnboardingPage(
                      imagePath: 'assets/images/onboarding_start.png',
                      title: 'Keşfetmeye Hazır Mısınız?',
                      description: 'Zihninizi serbest bırakın, iç dünyanızı keşfedin ve kişisel gelişiminizi takip edin. Başlamak için dokunun!',
                      iconData: Icons.auto_stories_rounded,
                    ),
                  ],
                ),
              ),

              // --- Alt Kısım: Gösterge ve Butonlar ---
              _buildBottomSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    // Bu kısım büyük ölçüde aynı kalabilir, tema renklerini zaten kullanıyor
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Atla Butonu
          AnimatedOpacity( // Son sayfada kaybolması için animasyon
            opacity: _isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: _isLastPage
                ? const SizedBox(width: 60) // Yer tutucu
                : TextButton(
              onPressed: _isLoading ? null : _completeOnboarding, // Yükleniyorsa deaktif
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant),
              child: const Text('Atla'),
            ),
          ),

          // Sayfa Göstergesi
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: WormEffect(
              dotHeight: 10, dotWidth: 10,
              activeDotColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            onDotClicked: (index) {
              _pageController.animateToPage( index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
            },
          ),

          // İleri / Başla Butonu
          ElevatedButton(
            onPressed: _isLoading ? null : () { // Yükleniyorsa deaktif
              if (_isLastPage) {
                // Yükleme durumunu başlat (opsiyonel ama iyi pratik)
                setState(() { _isLoading = true; });
                _completeOnboarding();
              } else {
                _pageController.nextPage( duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(), padding: const EdgeInsets.all(14),
              backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
            ),
            // Yükleme durumunu butonda göster
            child: _isLoading && _isLastPage // Sadece son sayfada ve yükleniyorsa gösterge
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Icon( _isLastPage ? Icons.check_rounded : Icons.arrow_forward_ios_rounded, size: 24) ,
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

    // Resim yolunu kontrol et (hata ayıklama için)
    // TODO: Assets klasörünüzde resimlerin olduğundan ve pubspec.yaml'da tanımlandığından emin olun.
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