// lib/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/home/home_screen.dart';
 // Tema için (YOLU KONTROL EDİN!)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false; // Son sayfada olup olmadığımızı takip et

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Onboarding'in tamamlandığını işaretler ve ana ekrana geçer.
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true); // İşaretle

    // Onboarding ekranını yığından kaldırarak ana ekrana geç
    if (mounted) { // Async işlem sonrası context kontrolü
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea( // Sistem UI çakışmalarını önler
        child: Column(
          children: [
            // --- Sayfalar ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    // Son sayfaya gelindiğinde _isLastPage'i güncelle
                    _isLastPage = index == 2; // Toplam 3 sayfa (0, 1, 2)
                  });
                },
                children: const [
                  // --- Sayfa 1: Hoş Geldiniz ---
                  _OnboardingPage(
                    imagePath: 'assets/images/onboarding_welcome.png', // Kendi resim yolunuzu kullanın
                    title: 'Mind Vault\'a Hoş Geldiniz!',
                    description: 'Düşüncelerinizi, hislerinizi ve anılarınızı güvenle saklayacağınız kişisel dijital günlüğünüz.',
                  ),
                  // --- Sayfa 2: Gizlilik Vurgusu ---
                  _OnboardingPage(
                    imagePath: 'assets/images/onboarding_privacy.png', // Kendi resim yolunuzu kullanın
                    title: 'Gizliliğiniz Önceliğimiz',
                    description: 'Tüm günlükleriniz güçlü şifreleme ile korunur ve sadece sizin cihazınızda saklanır. Verileriniz asla buluta gönderilmez veya paylaşılmaz.',
                    iconData: Icons.lock_person_rounded, // Ekstra ikon
                  ),
                  // --- Sayfa 3: Başlangıç ---
                  _OnboardingPage(
                    imagePath: 'assets/images/onboarding_start.png', // Kendi resim yolunuzu kullanın
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
    );
  }

  /// Ekranın alt kısmındaki gösterge ve butonları oluşturan metot.
  Widget _buildBottomSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Atla Butonu (Son sayfada gizlenir) ---
          _isLastPage
              ? const SizedBox(width: 60) // Son sayfada yer tutucu
              : TextButton(
            onPressed: _completeOnboarding,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant), // Atla -> Tamamla
            child: const Text('Atla'),
          ),

          // --- Sayfa Göstergesi ---
          SmoothPageIndicator(
            controller: _pageController,
            count: 3, // Toplam sayfa sayısı
            effect: WormEffect( // Güzel bir efekt seçin (Worm, ExpandingDots, ScrollingDots vb.)
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.outlineVariant,
            ),
            onDotClicked: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
          ),

          // --- İleri / Başla Butonu ---
          ElevatedButton(
            onPressed: () {
              if (_isLastPage) {
                // Son sayfadaysa Onboarding'i tamamla
                _completeOnboarding();
              } else {
                // Değilse sonraki sayfaya geç
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(), // Yuvarlak buton
              padding: const EdgeInsets.all(14),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Icon(
              _isLastPage ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}


/// Onboarding ekranındaki her bir sayfayı temsil eden basit widget.
class _OnboardingPage extends StatelessWidget {
  final String imagePath; // Gösterilecek resmin yolu (assets)
  final String title;
  final String description;
  final IconData? iconData; // Sayfaya özel ikon (opsiyonel)

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Ortala
        children: [
          // İkon (varsa)
          if (iconData != null)
            Icon(iconData, size: 50, color: colorScheme.secondary),
          if (iconData != null)
            const SizedBox(height: 20),

          // Resim (Assets klasörünüzde olmalı)
          // TODO: Assets klasörünü oluşturup resimleri ekleyin ve pubspec.yaml'da tanımlayın.
          Image.asset(
            imagePath,
            height: MediaQuery.of(context).size.height * 0.35, // Ekran yüksekliğine göre boyut
            fit: BoxFit.contain, // Resmin oranını koru
          ),
          const SizedBox(height: 40),

          // Başlık
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          // Açıklama
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5, // Satır aralığı
            ),
          ),
        ],
      ),
    );
  }
}