// lib/screens/main_screen.dart
// Responsive, Sabit Özel Alt Navigasyonlu Tam Kod
// Değişiklikler: Navigasyon Metin Stili güncellendi, ThemeConfig'e uygunluk varsayıldı.

import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/calendar_page.dart';
import 'package:mindvault/features/journal/screens/explore/explore_screen.dart';
// ========== !!! IMPORT YOLLARINI KONTROL ET VE TUTARLI YAP !!! ==========
import 'package:mindvault/features/journal/screens/home/home_screen.dart';
import 'package:mindvault/features/journal/screens/settings/settings_screen.dart';
import 'package:mindvault/features/journal/screens/page_screens/add_edit_journal_screen.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
// ThemeConfig'i import etmeye gerek yok, Theme.of(context) kullanılacak.
// =====================================================================



// SettingsHostScreen import edildiği varsayılıyor veya yukarıdaki gibi tanımlı.

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  // --- Navigasyon Çubuğu ve FAB Ayarları (Önceki değerler korunuyor) ---
  static const double kBottomNavHeight = 65.0;
  static const double kBottomNavBottomMargin = 32.0;
  static const double kFabSize = 56.0;
  static const double kFabBottomOffset = 95.0; // FAB yukarıda

  // Gösterilecek ekranların listesi
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ExploreScreen(),
    const CalendarPage(),
    SettingsHostScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Alt çubuktan bir öğeye tıklandığında çağrılır
  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  /// PageView kaydırıldığında çağrılır
  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.05; // Yan boşluklar %5

    // PageView içeriğinin alt navigasyonun arkasında kalmaması için gereken boşluk
    final double pageViewBottomPadding = kBottomNavHeight + kBottomNavBottomMargin + 10;

    // Temayı al (ThemeConfig ile ayarlandığı varsayılıyor)
    final theme = Theme.of(context);
    final textTheme = theme.textTheme; // ThemeConfig'den gelen TextTheme
    final colorScheme = theme.colorScheme; // ThemeConfig'den gelen ColorScheme

    return ThemedBackground( // ThemedBackground temanın arka planını uygular
      child: Scaffold(
        backgroundColor: Colors.transparent, // ThemedBackground üzerine şeffaf
        body: Stack(
          children: [
            // Ana İçerik Alanı (PageView)
            Padding(
              padding: EdgeInsets.only(bottom: pageViewBottomPadding),
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: _widgetOptions,
              ),
            ),

            // Özel Alt Navigasyon Çubuğu
            _buildCustomBottomNav(context, horizontalPadding, textTheme, colorScheme),

            // Floating Action Button (Koşullu ve Ortalanmış)
            if (_selectedIndex == 0)
              Positioned(
                left: screenWidth / 2 - kFabSize / 2, // Yatayda ortala
                bottom: kFabBottomOffset, // Alt konumu ayarla (yukarıda)
                child: FloatingActionButton(
                  // FAB stili temadan alınır (floatingActionButtonTheme)
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditJournalScreen()),
                    );
                  },
                  tooltip: 'Yeni Günlük Girişi',
                  elevation: 4.0,
                  child: const Icon(Icons.add_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Özel Alt Navigasyon Çubuğu Oluşturucu ---
  Widget _buildCustomBottomNav(BuildContext context, double horizontalPadding, TextTheme textTheme, ColorScheme colorScheme) {
    // Konumlandırma ve genel container yapısı aynı
    return Positioned(
      bottom: kBottomNavBottomMargin,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Container(
        height: kBottomNavHeight,
        decoration: BoxDecoration(
          color: Colors.transparent, // Arka plan şeffaf
          borderRadius: BorderRadius.circular(kBottomNavHeight / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kBottomNavHeight / 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Navigasyon öğeleri oluşturulurken textTheme ve colorScheme gönderilir
              _buildNavItem(context, Icons.notes_rounded, Icons.notes_outlined, 'Günlük', 0, textTheme, colorScheme),
              _buildNavItem(context, Icons.search_rounded, Icons.search_outlined, 'Keşfet', 1, textTheme, colorScheme),
              _buildNavItem(context, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Takvim', 2, textTheme, colorScheme),
              _buildNavItem(context, Icons.settings_rounded, Icons.settings_outlined, 'Ayarlar', 3, textTheme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // --- Navigasyon Öğesi Oluşturucu ---
  Widget _buildNavItem(
      BuildContext context,
      IconData activeIcon,
      IconData inactiveIcon,
      String label,
      int index,
      TextTheme textTheme, // Temadan gelen TextTheme alındı
      ColorScheme colorScheme // Temadan gelen ColorScheme alındı
      ) {
    final bool isSelected = _selectedIndex == index;

    // İkon Rengi (Seçime göre değişmeye devam ediyor)
    final Color selectedIconColor = colorScheme.primary; // Seçili ikon rengi
    final Color unselectedIconColor = colorScheme.primary.withOpacity(0.8);   // Seçili olmayan ikon rengi
    final Color iconColor = isSelected ? selectedIconColor : unselectedIconColor;

    // İkon Boyutu (Seçime göre değişmeye devam ediyor)
    final double iconSize = isSelected ? 24 : 24;

    // ****** DEĞİŞİKLİK: Metin Stili isteğe göre ayarlandı ******
    // Belirtilen stil kullanılıyor, seçili/seçili olmayan ayrımı yok.
    final TextStyle labelStyle = textTheme.bodySmall?.copyWith( // Temanın bodyLarge stili temel alınıyor
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,// İtalik
      // Renk de sabit olarak ayarlanıyor
      color: colorScheme.onSurface.withOpacity(1),
    ) ?? const TextStyle( // Null gelme ihtimaline karşı fallback
      fontStyle: FontStyle.italic,
      color: Colors.grey, // Varsayılan renk
      fontSize: 10, // bodyLarge null ise varsayılan boyut
    );


    return Flexible(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(kBottomNavHeight / 2),
        // Tıklama efekti rengi ikon rengine göre ayarlanabilir
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: iconColor, // İkon rengi seçime göre değişiyor
                size: iconSize,   // İkon boyutu seçime göre değişiyor
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: labelStyle, // ****** YENİ SABİT METİN STİLİ UYGULANDI ******
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}