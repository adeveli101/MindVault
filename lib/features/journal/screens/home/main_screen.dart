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

  // Widget listesi artık state'e bağlı (TabController nedeniyle)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // CalendarPage'deki sekme sayısına göre length ayarla (örneğin 2)
    _calendarTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _calendarTabController.dispose(); // TabController dispose ediliyor
    super.dispose();
  }

  /// Alt çubuktan bir öğeye tıklandığında çağrılır
  void _onItemTapped(int index) {
    // Eğer zaten o sayfadaysak ve sayfa CalendarPage ise işlem yapma
    // (isteğe bağlı, TabBar'ın kendi kendine yetmesi için)
    // if (_selectedIndex == index && index == 1) return;

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
        // Eğer CalendarPage'e gelindiyse TabController'ı senkronize et (isteğe bağlı)
        // if (index == 1) {
        //   _calendarTabController.index = DefaultTabController.of(context)?.index ?? 0;
        // }
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

    // Widget listesi build içinde oluşturuluyor (Sıralama önemli!)
    final List<Widget> widgetOptions = <Widget>[
      const HomeScreen(),                               // Index 0
      CalendarPage(tabController: _calendarTabController), // Index 1 <--- TAKVİM BURADA
      const ExploreScreen(),                            // Index 2
      SettingsHostScreen(),                             // Index 3
    ];

    // *** DEĞİŞİKLİK: Koşullu AppBar kontrolü index 1'e göre yapılıyor ***
    // Sadece Takvim sekmesi (_selectedIndex == 1) aktifken AppBar gösterilecek
    final PreferredSizeWidget? currentAppBar = _selectedIndex == 1
        ? AppBar(
      backgroundColor: Colors.transparent, // Veya temanıza uygun renk
      elevation: 0,
      title: Text(
        'Kayıtlar', // Veya 'Takvim' gibi daha uygun bir başlık
        style: TextStyle(color: colorScheme.onSurface),
      ),
      centerTitle: true,
      bottom: TabBar(
        controller: _calendarTabController,
        indicatorColor: colorScheme.primary, // Gösterge rengini tema primary yap
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        labelColor: colorScheme.primary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
        ),
        tabs: const <Widget>[
          Tab(text: 'Liste'),
          Tab(text: 'Takvim'),
        ],
      ),
    )
        : null; // Diğer sayfalarda AppBar olmayacak

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: currentAppBar, // Koşullu AppBar atanıyor
        body: Stack(
          children: [
            // Ana İçerik Alanı (PageView)
            Padding(
              // AppBar varsa PageView içeriğinin altından başlamaması için üst padding eklenebilir
              // Ancak ThemedBackground tüm alanı kapladığı için genellikle gerekmez.
              // Sadece alt padding'i bırakıyoruz.
              padding: EdgeInsets.only(bottom: pageViewBottomPadding),
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: widgetOptions, // Doğru sıralanmış widget listesi
              ),
            ),

            // Özel Alt Navigasyon Çubuğu
            _buildCustomBottomNav(context, horizontalPadding, textTheme, colorScheme),

            // Floating Action Button (Koşullu ve Ortalanmış)
            // FAB sadece ilk sayfada (Home - index 0) görünür
            if (_selectedIndex == 0)
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
  Widget _buildCustomBottomNav(BuildContext context, double horizontalPadding, TextTheme textTheme, ColorScheme colorScheme) {
    return Positioned(
      bottom: kBottomNavBottomMargin,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Container(
        height: kBottomNavHeight,
        decoration: BoxDecoration(
          // Arka plan rengini temadan almak daha dinamik olabilir
          color: Colors.transparent, // Hafif yarı saydam yüzey rengi
          borderRadius: BorderRadius.circular(kBottomNavHeight / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
              // *** DEĞİŞİKLİK: Index'ler widgetOptions listesindeki sıraya göre güncellendi ***
              _buildNavItem(context, Icons.notes_rounded,
                  Icons.notes_outlined, 'Ana Sayfa',
                  0, textTheme, colorScheme), // Index 0 -> HomeScreen
              _buildNavItem(context, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Takvim', 1, textTheme, colorScheme), // Index 1 -> CalendarPage <--- DÜZELTİLDİ
              _buildNavItem(context, Icons.search_rounded, Icons.search_outlined, 'Keşfet', 2, textTheme, colorScheme), // Index 2 -> ExploreScreen <--- DÜZELTİLDİ
              _buildNavItem(context, Icons.settings_rounded, Icons.settings_outlined, 'Ayarlar', 3, textTheme, colorScheme), // Index 3 -> SettingsHostScreen
            ],
          ),
        ),
      ),
    );
  }

  // --- Navigasyon Öğesi Oluşturucu ---
  // (Bu kısım önceki kodunuzla aynı, sadece index parametresi önemli)
  Widget _buildNavItem(
      BuildContext context,
      IconData activeIcon,
      IconData inactiveIcon,
      String label,
      int index, // <--- Bu index artık _widgetOptions'daki gerçek sırayı temsil ediyor
      TextTheme textTheme,
      ColorScheme colorScheme
      ) {
    final bool isSelected = _selectedIndex == index;
    final Color selectedIconColor = colorScheme.primary;
    final Color unselectedIconColor = colorScheme.onSurfaceVariant.withOpacity(0.7);
    final Color iconColor = isSelected ? selectedIconColor : unselectedIconColor;
    final double iconSize = isSelected ? 26 : 24;
    final FontWeight labelWeight = isSelected ? FontWeight.bold : FontWeight.w900;
    final Color labelColor = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    final TextStyle labelStyle = textTheme.bodySmall?.copyWith(
        fontWeight: labelWeight,
        color: labelColor,
        letterSpacing: 0.1
    ) ?? TextStyle( // Fallback
      fontWeight: labelWeight,
      color: labelColor,
      fontSize: 10,
    );

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index), // Doğru index ile _onItemTapped çağrılıyor
        borderRadius: BorderRadius.circular(kBottomNavHeight / 4),
        splashColor: selectedIconColor.withOpacity(0.1),
        highlightColor: selectedIconColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: iconColor,
                size: iconSize,
              ),
              const SizedBox(height: 4),
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