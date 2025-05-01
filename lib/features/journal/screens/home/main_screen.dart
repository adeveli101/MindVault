// lib/screens/main_screen.dart (Kaydırmalı Geçiş Eklendi)

import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/home/explore_screen.dart';
// ========== !!! IMPORT YOLLARINI KONTROL ET VE TUTARLI YAP !!! ==========
import 'package:mindvault/features/journal/screens/home/home_screen.dart';
import 'package:mindvault/features/journal/screens/home/settings_screen.dart';
import 'package:mindvault/features/journal/screens/page_screens/add_edit_journal_screen.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  // PageView'ı kontrol etmek için PageController eklendi
  late PageController _pageController;

  // Gösterilecek ekranların listesi (HomeScreen import edildi, diğerleri placeholder)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ExploreScreen(), // Placeholder - Kendi ekranınızı ekleyin
    CalendarScreen(), // Placeholder - Kendi ekranınızı ekleyin
    SettingsHostScreen(), // Placeholder - Kendi ekranınızı ekleyin
  ];

  @override
  void initState() {
    super.initState();
    // PageController'ı başlangıç sayfasıyla başlat
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    // Controller'ı dispose et
    _pageController.dispose();
    super.dispose();
  }

  /// Alt çubuktan bir öğeye tıklandığında çağrılır
  void _onItemTapped(int index) {
    // PageView'ı animasyonlu veya doğrudan o sayfaya götür
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Geçiş animasyon süresi
      curve: Curves.easeInOut, // Geçiş efekti
    );
    // setState ile _selectedIndex'i güncellemeye gerek yok,
    // çünkü onPageChanged bunu zaten yapacak.
    // Ancak anlık tepki için setState de çağrılabilir:
    // setState(() {
    //   _selectedIndex = index;
    // });
  }

  /// PageView kaydırıldığında çağrılır
  void _onPageChanged(int index) {
    // Seçili indeksi güncelle (BottomAppBar'ın doğru ikonu göstermesi için)
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ThemedBackground tüm yapıyı sarar
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Body kısmında artık PageView kullanılıyor
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged, // Sayfa değiştiğinde indeksi güncelle
          children: _widgetOptions, // Gösterilecek sayfalar
          // physics: const BouncingScrollPhysics(), // İsteğe bağlı: Kaydırma fiziği
        ),

        floatingActionButton: _selectedIndex == 0 // Sadece Günlük sekmesinde göster
            ? FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditJournalScreen()),
            );
          },
          tooltip: 'Yeni Günlük Girişi',
          child: const Icon(Icons.add_rounded),
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // Alt Navigasyon Çubuğu (BottomAppBar)
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          color: colorScheme.surfaceContainer.withOpacity(0),
          elevation: 8.0,
          child: SizedBox(
            height: 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildNavItem(context, Icons.notes_rounded,
                    Icons.notes_outlined, 'Günlük', 0),
                _buildNavItem(context, Icons.search_rounded, Icons.search_outlined, 'Keşfet', 1),
                const SizedBox(width: 40), // FAB boşluğu
                _buildNavItem(context, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Takvim', 2),
                _buildNavItem(context, Icons.settings_rounded, Icons.settings_outlined, 'Ayarlar', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BottomAppBar için navigasyon elemanı oluşturucu (öncekiyle aynı)
  Widget _buildNavItem(BuildContext context, IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? Theme.of(context).colorScheme.primary :
    Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9);

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index), // Tıklanınca PageView'ı kaydırır
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(isSelected ? activeIcon : inactiveIcon, color: color, size: 24), // Boyut ayarlandı
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}




class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Takvim'), centerTitle: true, elevation: 0, backgroundColor: Colors.transparent),
      body: const Center(child: Text('Takvim Ekranı İçeriği')),
    );
  }
}

