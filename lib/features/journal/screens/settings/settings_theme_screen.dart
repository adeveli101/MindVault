// lib/features/journal/screens/home/settings_theme_screen.dart (Eksiksiz Son Hali)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/screens/explore/explore_screen.dart';
// ========== !!! IMPORT YOLLARINI KONTROL ET VE TUTARLI YAP !!! ==========
// Paket adınız 'mindvault' ise aşağıdaki gibi olmalı. Değilse düzeltin.
// BU DOSYADAKİ VE DİĞER TÜM DOSYALARDAKİ YOLLAR AYNI OLMALI!
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart'; // Yeni Kayıt Merkezi config
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
// ThemedBackground widget'ınızın doğru yolunu import edin:
// =====================================================================
import 'package:stacked_themes/stacked_themes.dart';

class SettingsThemeScreen extends StatefulWidget {
  const SettingsThemeScreen({super.key});

  @override
  State<SettingsThemeScreen> createState() => _SettingsThemeScreenState();
}

class _SettingsThemeScreenState extends State<SettingsThemeScreen> {
  // --- State Variables ---
  late NotebookThemeType _selectedBaseStyle;
  late ThemeSize _selectedSize;
  late int _currentThemeIndex;
  late PageController _pageController;
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  // --- UI Constants ---
  final double _themeCardHeight = 180;
  final double _viewportFraction = 0.5; // Kart genişliğini/görünürlüğünü ayarlar

  // --- Data ---
  // baseThemes listesi initState içinde ThemeConfig'den alınacak
  late final List<AppThemeData> baseThemes;

  //--------------------------------------------------------------------------
  // Lifecycle Methods
  //--------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    // baseThemes listesini burada başlatmak önemli
    baseThemes = ThemeConfig.getBaseThemeRepresentations();
    // Eğer baseThemes boşsa (ThemeConfig hatası), hata mesajı veya varsayılan atama yapılabilir
    if (baseThemes.isEmpty) {
      if (kDebugMode) {
        if (kDebugMode) {
          print("UYARI: ThemeConfig.getBaseThemeRepresentations() BOŞ döndü! Tema listesi yüklenemedi.");
        }
      }
      // Burada belki bir hata gösterme mekanizması eklenebilir.
    }

    _initializeState(); // Temayı ve seçili stili başlat

    // initialPage hesaplaması _selectedBaseStyle'dan sonra yapılmalı
    final initialPageIndex = baseThemes.indexWhere(
          (theme) => theme.type == _selectedBaseStyle,
      // Eğer _selectedBaseStyle listede yoksa -1 döner, bu durumu handle et
    );

    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: initialPageIndex != -1 ? initialPageIndex : 0,
    );

    _pageController.addListener(_updateScrollArrows);
    // initState içinde doğrudan setState çağırmak yerine bu callback kullanılır
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollArrows());
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateScrollArrows);
    _pageController.dispose();
    super.dispose();
  }

  //--------------------------------------------------------------------------
  // Helper Methods for State Logic
  //--------------------------------------------------------------------------

  /// Sayfa kaydıkça okların görünürlüğünü günceller
  void _updateScrollArrows() {
    // Widget ağaçtan kaldırıldıysa veya controller hazır değilse işlem yapma
    if (!_pageController.hasClients || !mounted) return;

    final currentPage = _pageController.page ?? _pageController.initialPage.toDouble();
    final maxPages = baseThemes.length;

    // Eğer sadece 1 veya daha az tema varsa okları gösterme
    if (maxPages <= 1) {
      if (_showLeftArrow || _showRightArrow) {
        setState(() { _showLeftArrow = false; _showRightArrow = false;});
      }
      return;
    }

    // Yeni ok durumlarını hesapla
    bool newShowLeft = currentPage > 0.1;
    bool newShowRight = currentPage < (maxPages - 1) - 0.1;

    // Sadece değişiklik varsa setState çağır
    if (newShowLeft != _showLeftArrow || newShowRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = newShowLeft;
        _showRightArrow = newShowRight;
      });
    }
  }

  /// Başlangıç tema durumunu ayarlar
  void _initializeState() {
    final themeManager = getThemeManager(context);
    _currentThemeIndex = themeManager.selectedThemeIndex ?? 0;

    // Yeni ThemeConfig helper'larını kullan
    final currentThemeType = ThemeConfig.getThemeTypeByIndex(_currentThemeIndex);
    _selectedBaseStyle = ThemeConfig.getBaseStyle(currentThemeType);
    _selectedSize = ThemeConfig.getThemeSize(currentThemeType);

    // Başlangıçta _selectedBaseStyle'ın baseThemes listesinde olduğundan emin ol
    // Eğer değilse (örn. hatalı index veya liste), varsayılan bir stile ayarla
    if (!baseThemes.any((theme) => theme.type == _selectedBaseStyle) && baseThemes.isNotEmpty) {
      _selectedBaseStyle = baseThemes.first.type; // Listenin ilk temasını seç
      // Seçili stili varsayılana ayarladıktan sonra temayı da güncellemek iyi olabilir
      _updateTheme();
    }
  }

  /// Seçilen stil ve boyuta göre temayı günceller
  void _updateTheme() {
    // Yeni ThemeConfig helper'larını kullan
    final newIndex = ThemeConfig.findThemeIndexByStyleAndSize(
        _selectedBaseStyle, _selectedSize);
    if (newIndex != -1 && newIndex != _currentThemeIndex) {
      getThemeManager(context).selectThemeAtIndex(newIndex);
      if (mounted) {
        setState(() {
          _currentThemeIndex = newIndex;
        });
      }
    }
  }

  /// Belirtilen sayfaya animasyonla gider
  void _animateToPage(int pageIndex) {
    if (_pageController.hasClients && pageIndex >= 0 && pageIndex < baseThemes.length) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Tema tipi enum'ından okunabilir bir isim döndürür
  String _getBaseStyleName(NotebookThemeType type) {
    String typeName = type.toString().split('.').last;
    if (typeName.contains('Light')) return "Aydınlık";
    if (typeName.contains('Dark')) return "Altın Vurgu";
    if (typeName.contains('Leather')) return "Deri";
    if (typeName.contains('Antique')) return "Antika";
    if (typeName.contains('Blueprint')) return "Mimari";
    if (typeName.contains('Scrapbook')) return "Karalama";
    if (typeName.contains('Japanese')) return "Minimalist";
    if (typeName.contains('Watercolor')) return "Suluboya";
    return typeName.replaceAll('Medium', ''); // Genel fallback
  }

  //--------------------------------------------------------------------------
  // Build Method
  //--------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final AppThemeData currentAppTheme =
    ThemeConfig.getAppThemeDataByIndex(_currentThemeIndex);
    final Color primaryColor =
        currentAppTheme.materialTheme.colorScheme.primary;
    final TextStyle titleStyle =
        Theme.of(context).textTheme.titleLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ) ??
            const TextStyle();
    final screenWidth = MediaQuery.of(context).size.width;

    return ThemedBackground( // !!! ThemedBackground import yolunu KESİN KONTROL EDİN !!!
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(titleStyle), // Başlık
                  const SizedBox(height: 8),
                  _buildThemeSelector(context, screenWidth), // Tema Seçici
                  const SizedBox(height: 16),
                  _buildSeeAllButton(context, primaryColor), // Tümünü Gör
                  const SizedBox(height: 32),
                  _buildSizeSelectorSection(context, currentAppTheme), // Boyut Seçici
                  const SizedBox(height: 32),
                  _buildPreviewSection(context, titleStyle), // Önizleme
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // Widget Building Helper Methods (Eksiksiz)
  //--------------------------------------------------------------------------

  /// Bölüm 1: Başlığı Oluşturur
  Widget _buildHeader(TextStyle titleStyle) {
    return Center(child: Text('Tema Stili', style: titleStyle));
  }

  /// Bölüm 2: Ortalanmış, 3/4 Genişlikte PageView ve Okları Oluşturur
  Widget _buildThemeSelector(BuildContext context, double screenWidth) {
    return Center(
      child: SizedBox(
        width: screenWidth * 0.75,
        height: _themeCardHeight + 32, // Oklar için pay dahil
        child: Stack(
          alignment: Alignment.center,
          children: [
            // PageView (Eğer baseThemes boşsa hata vermemesi için kontrol eklenebilir)
            baseThemes.isEmpty
                ? const Center(child: Text('Temalar yüklenemedi.')) // Veya bir yükleniyor göstergesi
                : PageView.builder(
              controller: _pageController,
              itemCount: baseThemes.length,
              scrollDirection: Axis.horizontal,
              padEnds: false, // Ortalamayı iyileştirir
              itemBuilder: (context, index) {
                // Her bir tema kartını oluşturan metodu çağır
                return _buildThemeSelectorCard(context, index);
              },
            ),
            // Sol Ok
            Positioned(
              left: 4, // İçeri alındı
              child: AnimatedOpacity(
                opacity: _showLeftArrow ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showLeftArrow,
                  child: _buildScrollArrow(
                    context,
                    Icons.arrow_back_ios_new_rounded,
                        () {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    },
                  ),
                ),
              ),
            ),
            // Sağ Ok
            Positioned(
              right: 4, // İçeri alındı
              child: AnimatedOpacity(
                opacity: _showRightArrow ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showRightArrow,
                  child: _buildScrollArrow(
                    context,
                    Icons.arrow_forward_ios_rounded,
                        () {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PageView içindeki tek bir tema kartını oluşturur (Preview ve Lock ikonları ile)
  Widget _buildThemeSelectorCard(BuildContext context, int index) {
    // index'in geçerli olduğundan emin olalım (baseThemes boş değilse)
    if (index < 0 || index >= baseThemes.length) {
      return const SizedBox.shrink(); // Boş veya hatalı index için boş widget
    }

    final theme = baseThemes[index];
    final themeType = theme.type;
    final bool isSelected = themeType == _selectedBaseStyle;
    final bool isLocked = !theme.isFree;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: isLocked
            ? () { if (kDebugMode) {
              print("Kilitli tema tıklandı: ${theme.name}");
            } }
            : () {
          if (!isSelected) {
            setState(() => _selectedBaseStyle = themeType);
            _updateTheme();
          }
          _animateToPage(index);
        },
        child: Opacity(
          opacity: isLocked && !isSelected ? 0.6 : 1.0,
          child: SizedBox(
            height: _themeCardHeight,
            child: Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(isSelected ? 0.95 : 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor.withOpacity(0.4),
                  width: isSelected ? 3.5 : 1.5,
                ),
                boxShadow: isSelected
                    ? [ BoxShadow( color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 2)) ]
                    : [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1)) ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Resim, Preview Butonu ve Kilit İkonu Alanı
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: _buildMiniThemePreview(context, theme),
                      ),
                      // Preview Butonu (Sol Üst)
                      Positioned(
                        top: 4, left: 4,
                        child: Container(
                          decoration: BoxDecoration( color: Colors.black.withOpacity(0.5), shape: BoxShape.circle,),
                          child: Material(
                            color: Colors.transparent, shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${theme.name} önizlemesi açılacak...')), );
                                if (kDebugMode) {
                                  print("Önizleme butonu tıklandı: ${theme.name}");
                                }
                              },
                              child: Padding( padding: const EdgeInsets.all(5.0), child: Icon( Icons.visibility_outlined, size: 18, color: Colors.white.withOpacity(0.9),), ),
                            ),
                          ),
                        ),
                      ),
                      // Kilit İkonu (Sağ Üst - Sadece kilitliyse)
                      if (isLocked)
                        Positioned(
                          top: 4, right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration( color: Colors.black.withOpacity(0.6), shape: BoxShape.circle,),
                            child: Icon( Icons.lock, size: 16, color: Colors.white.withOpacity(0.9), ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // İsim Alanı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      _getBaseStyleName(theme.type),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith( fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Theme.of(context).colorScheme.onSurface, ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mini tema kartı içindeki görsel önizlemeyi oluşturur
  Widget _buildMiniThemePreview(BuildContext context, AppThemeData theme) {
    final miniThemeData = theme.materialTheme;
    return Container(
      decoration: BoxDecoration(
        color: miniThemeData.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              theme.backgroundAssetPath,
              fit: BoxFit.fill, // Önceki istek üzerine fill yapıldı
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 24,
                  color: miniThemeData.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.0),
                    miniThemeData.colorScheme.primary.withOpacity(0.25)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kaydırma oklarını oluşturan yardımcı widget
  Widget _buildScrollArrow(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  /// Bölüm 3: Ortalanmış "Tümünü Gör" Butonunu Oluşturur
  Widget _buildSeeAllButton(BuildContext context, Color primaryColor) {
    return Center(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
        label: const Text('Tüm Temaları Gör'),
        onPressed: () {

          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));


        },
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  /// Bölüm 4: Boyut Seçici (SegmentedButton) Bölümünü Oluşturur
  Widget _buildSizeSelectorSection(
      BuildContext context, AppThemeData currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: _buildSizeSelector(context, currentTheme),
    );
  }

  /// SegmentedButton widget'ını oluşturur
  Widget _buildSizeSelector(BuildContext context, AppThemeData currentTheme) {
    final scheme = currentTheme.materialTheme.colorScheme;
    const segments = <ButtonSegment<ThemeSize>>[
      ButtonSegment<ThemeSize>(value: ThemeSize.small, label: Text('Küçük')),
      ButtonSegment<ThemeSize>(value: ThemeSize.medium, label: Text('Orta')),
      ButtonSegment<ThemeSize>(value: ThemeSize.large, label: Text('Büyük')),
    ];
    return Center(
      child: SegmentedButton<ThemeSize>(
        segments: segments,
        selected: <ThemeSize>{_selectedSize},
        onSelectionChanged: (Set<ThemeSize> newSelection) {
          if (mounted) { // setState için kontrol
            setState(() => _selectedSize = newSelection.first);
          }
          _updateTheme();
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.surfaceContainerHighest.withOpacity(0.5)),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected)
                  ? scheme.onPrimary
                  : scheme.onSurface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: scheme.primary.withOpacity(0.3), width: 0.5),
          ),
        ),
        showSelectedIcon: false,
      ),
    );
  }

  /// Bölüm 5: Önizleme Başlığı ve Alanını Oluşturur
  Widget _buildPreviewSection(BuildContext context, TextStyle titleStyle) {
    return Column(
      children: [
        Center(child: Text('Önizleme', style: titleStyle)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: _buildPreviewArea(context),
        ),
      ],
    );
  }

  /// Önizleme Alanını (Arka plansız) Oluşturur
  Widget _buildPreviewArea(BuildContext context) {
    // Mevcut temayı kullanarak renk ve stil almak daha doğru
    final currentTheme = Theme.of(context);
    final textTheme = currentTheme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Örnek Başlık Yazısı',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              // color: colorScheme.onSurface, // Renk zaten temadan gelir
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu alandaki metinler, seçtiğiniz tema stili ve '
                '"${_selectedSize.toString().split('.').last}" '
                'yazı tipi boyutuyla görüntülenmektedir.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.6,
              // color: colorScheme.onSurface, // Renk zaten temadan gelir
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              // Stil temadan otomatik gelir
              // style: ElevatedButton.styleFrom(
              //   padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              // ),
              child: const Text('Örnek Buton'),
            ),
          ),
        ],
      ),
    );
  }
} // _SettingsThemeScreenState sınıfının sonu