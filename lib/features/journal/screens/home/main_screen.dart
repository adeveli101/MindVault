// lib/screens/main_screen.dart
// Responsive, Sabit Özel Alt Navigasyonlu ve TabController Yönetimli Tam Kod

import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/calendar_page.dart';
import 'package:mindvault/features/journal/screens/explore/explore_screen.dart';
// ========== !!! IMPORT YOLLARINI KONTROL ET VE TUTARLI YAP !!! ==========
// Varsayılan importlar, projenize göre düzenlemeniz gerekebilir
import 'package:mindvault/features/journal/screens/home/home_screen.dart';
import 'package:mindvault/features/journal/screens/settings/settings_screen.dart'; // SettingsHostScreen'i içerdiği varsayılıyor
import 'package:mindvault/features/journal/screens/page_screens/add_edit_journal_screen.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
// =====================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// *** DEĞİŞİKLİK: SingleTickerProviderStateMixin eklendi ***
class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late TabController _calendarTabController; // *** YENİ: CalendarPage için TabController ***

  // --- Navigasyon Çubuğu ve FAB Ayarları (Önceki değerler korunuyor) ---
  static const double kBottomNavHeight = 65.0;
  static const double kBottomNavBottomMargin = 32.0;
  static const double kFabSize = 56.0;
  static const double kFabBottomOffset = 95.0;

  // *** DEĞİŞİKLİK: _widgetOptions static olmaktan çıkarıldı ve build metodunda oluşturulacak ***
  // Widget listesi artık state'e bağlı (TabController nedeniyle)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // *** YENİ: TabController başlatılıyor (CalendarPage'deki sekme sayısına göre length ayarla - örneğin 2) ***
    _calendarTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _calendarTabController.dispose(); // *** YENİ: TabController dispose ediliyor ***
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

    // Temayı al
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Widget listesi build içinde oluşturuluyor
    final List<Widget> widgetOptions = <Widget>[
      const HomeScreen(),
      const ExploreScreen(),
      CalendarPage(tabController: _calendarTabController), // Controller iletiliyor
      SettingsHostScreen(),
    ];

    // *** YENİ: Koşullu AppBar ***
    // Sadece Takvim sekmesi (_selectedIndex == 2) aktifken AppBar gösterilecek
    final PreferredSizeWidget? currentAppBar = _selectedIndex == 2
        ? AppBar(
      // *** DEĞİŞİKLİK: AppBar Ayarları ***
      backgroundColor: Colors.transparent, // Veya Colors.transparent yapabilirsiniz
      elevation: 0, // Gölgelenmeyi ve alt çizgiyi kaldırır
      // ----------------------------------
      title: Text(
        'Kayıtlar',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      centerTitle: true,
      bottom: TabBar(
        controller: _calendarTabController,
        // *** DEĞİŞİKLİK: TabBar Ayarları ***
        indicatorColor: Colors.transparent, // Gösterge çizgisini kaldırır (önceki adımdan)
        dividerColor: Colors.transparent, // Sekmelerin altındaki ayırıcı çizgiyi kaldırır
        dividerHeight: 0, // Ayırıcı çizgi yüksekliğini sıfırlar (isteğe bağlı, garanti için)
        // -----------------------------------
        labelColor: colorScheme.primary, // Seçili etiket rengi (kalabilir veya isteğe bağlı)
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold, // Seçili etiketi kalın yap
          // fontSize: 15, // İsterseniz boyutunu da ayarlayabilirsiniz
        ),
        unselectedLabelColor: colorScheme.onSurfaceVariant, // Seçili olmayan etiket rengi (kalabilir veya isteğe bağlı)
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal, // Seçili olmayan etiket normal kalsın
          // fontSize: 14, // İsterseniz boyutunu da ayarlayabilirsiniz
        ),
        tabs: const <Widget>[
          Tab(text: 'Liste'),
          Tab(text: 'Takvim'),
        ],
      ),
    )
        : null;// Diğer sayfalarda AppBar olmayacak

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // *** YENİ: Koşullu olarak AppBar atanıyor ***
        appBar: currentAppBar,
        body: Stack(
          children: [
            // Ana İçerik Alanı (PageView)
            Padding(
              // *** ÖNEMLİ: AppBar varsa, PageView'ın üstten başlaması için padding'i ayarlayın ***
              // Eğer AppBar varsa, içeriğin AppBar'ın altında kalmaması için üst padding gerekir.
              // Ancak ThemedBackground tüm alanı kaplıyorsa ve AppBar şeffaf değilse
              // bu padding'e gerek olmayabilir veya farklı bir yaklaşım gerekebilir.
              // Şimdilik sadece alt padding'i bırakıyoruz, gerekirse ayarlama yaparız.
              padding: EdgeInsets.only(bottom: pageViewBottomPadding),
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: widgetOptions,
              ),
            ),

            // Özel Alt Navigasyon Çubuğu
            _buildCustomBottomNav(context, horizontalPadding, textTheme, colorScheme),

            // Floating Action Button (Koşullu ve Ortalanmış)
            if (_selectedIndex == 0) // FAB sadece ilk sayfada (Home) görünür
              Positioned(
                left: screenWidth / 2 - kFabSize / 2,
                bottom: kFabBottomOffset,
                child: FloatingActionButton(
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
  // (Bu kısım önceki kodunuzla aynı, değişiklik yok)
  Widget _buildCustomBottomNav(BuildContext context, double horizontalPadding, TextTheme textTheme, ColorScheme colorScheme) {
    return Positioned(
      bottom: kBottomNavBottomMargin,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Container(
        height: kBottomNavHeight,
        decoration: BoxDecoration(
          color: Colors.transparent, // Hafif yarı saydam arka plan
          borderRadius: BorderRadius.circular(kBottomNavHeight / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Daha belirgin gölge
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kBottomNavHeight / 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
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
  // (Bu kısım önceki kodunuzla aynı, değişiklik yok)
  Widget _buildNavItem(
      BuildContext context,
      IconData activeIcon,
      IconData inactiveIcon,
      String label,
      int index,
      TextTheme textTheme,
      ColorScheme colorScheme
      ) {
    final bool isSelected = _selectedIndex == index;
    final Color selectedIconColor = colorScheme.primary;
    final Color unselectedIconColor = colorScheme.onSurfaceVariant.withOpacity(0.7); // Daha soluk
    final Color iconColor = isSelected ? selectedIconColor : unselectedIconColor;
    final double iconSize = isSelected ? 26 : 24; // Seçiliyken biraz daha büyük
    final FontWeight labelWeight = isSelected ? FontWeight.bold : FontWeight.normal;
    final Color labelColor = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    // Önceki kodunuzdaki gibi özel stil yerine daha standart bir yaklaşım:
    final TextStyle labelStyle = textTheme.bodySmall?.copyWith(
        fontWeight: labelWeight,
        color: labelColor,
        letterSpacing: 0.1
    ) ?? TextStyle( // Fallback
      fontWeight: labelWeight,
      color: labelColor,
      fontSize: 10,
    );

    return Expanded( // Expanded ile daha iyi esneklik
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(kBottomNavHeight / 4), // Daha hafif köşe yuvarlama
        splashColor: selectedIconColor.withOpacity(0.1),
        highlightColor: selectedIconColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Dikey padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: iconColor,
                size: iconSize,
              ),
              const SizedBox(height: 4), // İkon ve metin arası boşluk
              Text(
                label,
                style: labelStyle,
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