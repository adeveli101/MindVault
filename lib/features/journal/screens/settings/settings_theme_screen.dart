// lib/features/journal/screens/settings/settings_theme_screen.dart
// Tema stilini ve boyutunu ayarlama ekranı.
// ExploreScreen'den gelen başlangıç stilini kabul eder ve uygular.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Gerekli importlar (Yolları kontrol edin)
import 'package:mindvault/features/journal/screens/explore/explore_screen.dart'; // Tüm temaları görme ekranı
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart'; // Tema yapılandırması
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart'; // Tema tipleri enum'ı
import 'package:mindvault/features/journal/screens/themes/themed_background.dart'; // Standart arka plan
import 'package:stacked_themes/stacked_themes.dart'; // Tema yönetimi paketi

class SettingsThemeScreen extends StatefulWidget {
  // ***** YENİ: Başlangıç stilini almak için isteğe bağlı parametre *****
  final NotebookThemeType? initialBaseStyle;
  // *******************************************************************

  // Constructor güncellendi: initialBaseStyle parametresini kabul ediyor
  const SettingsThemeScreen({super.key, this.initialBaseStyle});

  @override
  State<SettingsThemeScreen> createState() => _SettingsThemeScreenState();
}

class _SettingsThemeScreenState extends State<SettingsThemeScreen> {
  // --- State Değişkenleri ---
  late NotebookThemeType _selectedBaseStyle; // Kullanıcının seçtiği temel stil (örn: Deri, Antika)
  late ThemeSize _selectedSize; // Kullanıcının seçtiği boyut (Küçük, Orta, Büyük)
  late int _currentThemeIndex; // stacked_themes tarafından uygulanan temanın tam index'i
  late PageController _pageController; // Yatay stil seçici (PageView) için kontrolcü
  bool _showLeftArrow = false; // Stil listesi için sol ok göster/gizle
  bool _showRightArrow = true; // Stil listesi için sağ ok göster/gizle
  bool _isLoading = true; // Başlangıçta tema bilgileri yüklenirken

  // --- UI Sabitleri ---
  final double _themeCardHeight = 180; // Stil kartlarının yüksekliği
  final double _viewportFraction = 0.5; // PageView'da bir seferde görünen kart oranı

  // --- Veri ---
  late final List<AppThemeData> baseThemes; // Gösterilecek temel (Medium) tema listesi

  // --- Yaşam Döngüsü Metotları ---
  @override
  void initState() {
    super.initState();
    // Temaları yükle (sadece medium boyutluları alır)
    baseThemes = ThemeConfig.getBaseThemeRepresentations();

    // Eğer tema listesi boşsa (beklenmedik durum), hata göster ve geri dön
    if (baseThemes.isEmpty) {
      if (kDebugMode) { print("SettingsThemeScreen UYARI: Tema listesi yüklenemedi."); }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tema listesi yüklenemedi.")));
          Navigator.pop(context); // Geri dön
        }
      });
      _isLoading = false; // Yükleme bitti (başarısız)
      return; // initState'ten çık
    }

    // Başlangıç state'ini ayarla (gelen initialBaseStyle'ı dikkate alarak)
    _initializeState();

    // PageView başlangıç sayfasını, seçili stile göre ayarla
    final initialPageIndex = baseThemes.indexWhere((theme) => theme.type == _selectedBaseStyle);
    _pageController = PageController(
      viewportFraction: _viewportFraction, // Kenardaki kartların bir kısmı görünür
      initialPage: initialPageIndex != -1 ? initialPageIndex : 0, // Bulunamazsa ilk sayfa
    );

    // PageView kaydırıldıkça okları güncellemek için listener ekle
    _pageController.addListener(_updateScrollArrows);
    // İlk build sonrası ok durumunu ve gerekirse PageView pozisyonunu ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollArrows();
      // Eğer Explore'dan gelindiyse ve PageView hemen scroll olmadıysa,
      // küçük bir gecikme ile tekrar scroll deneyebiliriz.
      if (widget.initialBaseStyle != null) {
        Future.delayed(const Duration(milliseconds: 50), () => _scrollToSelectedStyle());
      }
    });

    // Yükleme tamamlandı
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateScrollArrows);
    _pageController.dispose();
    super.dispose();
  }

  // --- State ve Yardımcı Metotlar ---

  /// Okların görünürlüğünü PageView pozisyonuna göre günceller.
  void _updateScrollArrows() {
    if (!_pageController.hasClients || !mounted) return;
    final currentPage = _pageController.page ?? _pageController.initialPage.toDouble();
    final maxPages = baseThemes.length;
    // Eğer 1 veya daha az tema varsa okları gösterme
    if (maxPages <= 1) {
      if (_showLeftArrow || _showRightArrow) {
        setState(() { _showLeftArrow = false; _showRightArrow = false; });
      }
      return;
    }
    // Yeni ok durumlarını hesapla (küçük bir toleransla)
    bool newShowLeft = currentPage > 0.1;
    bool newShowRight = currentPage < (maxPages - 1) - 0.1;
    // Sadece durum değiştiyse setState çağır
    if (newShowLeft != _showLeftArrow || newShowRight != _showRightArrow) {
      setState(() { _showLeftArrow = newShowLeft; _showRightArrow = newShowRight; });
    }
  }

  /// Başlangıç state'ini ayarlar: _selectedBaseStyle, _selectedSize, _currentThemeIndex.
  /// ExploreScreen'den gelen `initialBaseStyle` parametresini öncelikli olarak kullanır.
  void _initializeState() {
    try {
      final themeManager = getThemeManager(context);
      // Eğer ExploreScreen'den bir stil gönderildiyse onu temel al
      if (widget.initialBaseStyle != null && baseThemes.any((t) => t.type == widget.initialBaseStyle)) {
        _selectedBaseStyle = widget.initialBaseStyle!;
        // Boyutu, mevcut uygulanan temadan almayı dene
        try {
          final currentAppliedIndex = themeManager.selectedThemeIndex ?? 0;
          final currentAppliedType = ThemeConfig.getThemeTypeByIndex(currentAppliedIndex);
          _selectedSize = ThemeConfig.getThemeSize(currentAppliedType);
        } catch(e) {
          _selectedSize = ThemeSize.medium; // Alınamazsa varsayılan: Orta
          if (kDebugMode) print("Mevcut tema boyutu alınamadı, Medium varsayıldı: $e");
        }
        if (kDebugMode) print("ExploreScreen'den gelen stil ile başlatılıyor: $_selectedBaseStyle, Boyut: $_selectedSize");
        // Temayı hemen uygula (build sonrası çağrılacak)
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateTheme());
        // _currentThemeIndex, _updateTheme içinde ayarlanacak.
        _currentThemeIndex = themeManager.selectedThemeIndex ?? 0; // Geçici atama

      } else {
        // Eğer ExploreScreen'den stil gelmediyse veya geçersizse, mevcut temayı yükle
        if (kDebugMode && widget.initialBaseStyle != null) {if (kDebugMode) {

          print("Uyarı: ExploreScreen'den gelen stil (${widget.initialBaseStyle}) listede bulunamadı.");
        }}

        _currentThemeIndex = themeManager.selectedThemeIndex ?? 0;
        final currentThemeType = ThemeConfig.getThemeTypeByIndex(_currentThemeIndex);
        _selectedBaseStyle = ThemeConfig.getBaseStyle(currentThemeType);
        _selectedSize = ThemeConfig.getThemeSize(currentThemeType);

        // Güvenlik kontrolü: Mevcut stil listede yoksa varsayılana dön
        if (!baseThemes.any((theme) => theme.type == _selectedBaseStyle)) {
          if (kDebugMode) print("Uyarı: Mevcut stil ($_selectedBaseStyle) listede bulunamadı, varsayılana dönülüyor.");
          _selectedBaseStyle = baseThemes.isNotEmpty ? baseThemes.first.type : NotebookThemeType.defaultLightMedium; // Fallback ekle
          _selectedSize = ThemeSize.medium;
          _updateTheme(); // Varsayılanı uygula
        }
      }
    } catch(e,s) {
      // Genel hata durumu: Tamamen varsayılanlara dön
      if (kDebugMode) {
        print("SettingsThemeScreen state başlatılırken HATA: $e");
        print(s);
      }
      _selectedBaseStyle = baseThemes.isNotEmpty ? baseThemes.first.type : NotebookThemeType.defaultLightMedium;
      _selectedSize = ThemeSize.medium;
      _currentThemeIndex = 0; // Veya varsayılan index
      // Hata olsa bile temayı uygulamayı deneyebiliriz
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateTheme());
    }
  }

  /// Seçilen stil ve boyuta göre temayı bulur ve uygular.
  void _updateTheme() {
    // Seçili stil ve boyuta karşılık gelen tam tema index'ini bul
    final newIndex = ThemeConfig.findThemeIndexByStyleAndSize(
        _selectedBaseStyle, _selectedSize);

    // Geçerli bir index bulunduysa
    if (newIndex != -1) {
      final themeManager = getThemeManager(context);
      final currentAppliedIndex = themeManager.selectedThemeIndex ?? 0;
      // Sadece mevcut temadan farklıysa yeni temayı uygula
      if (newIndex != currentAppliedIndex) {
        themeManager.selectThemeAtIndex(newIndex);
        if (mounted) {
          // State'deki index'i de güncelle (UI tutarlılığı için)
          setState(() => _currentThemeIndex = newIndex);
        }
        if (kDebugMode) print("Tema güncellendi: Index=$newIndex, Style=$_selectedBaseStyle, Size=$_selectedSize");
      }
    } else {
      // Index bulunamazsa (ThemeConfig hatası olabilir)
      if (kDebugMode) print("Uyarı: _updateTheme içinde tema index'i bulunamadı! Style=$_selectedBaseStyle, Size=$_selectedSize");
      // Kullanıcıya hata mesajı gösterilebilir
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seçilen tema kombinasyonu bulunamadı.")));
    }
  }

  /// PageView'ı belirtilen index'e (baseThemes listesindeki) animasyonla kaydırır.
  void _animateToPage(int pageIndex) {
    if (_pageController.hasClients && pageIndex >= 0 && pageIndex < baseThemes.length) {
      _pageController.animateToPage(pageIndex, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut,);
    }
  }

  /// PageView'ı o an seçili olan `_selectedBaseStyle`'a kaydırır.
  void _scrollToSelectedStyle() {
    final targetIndex = baseThemes.indexWhere((theme) => theme.type == _selectedBaseStyle);
    if (targetIndex != -1) {
      _animateToPage(targetIndex);
    }
  }

  /// Tema tipinden (enum) okunabilir bir stil adı (String) döndürür.
  String _getBaseStyleName(NotebookThemeType type) {
    // ... (Öncekiyle aynı) ...
    String typeName = type.toString().split('.').last; typeName = typeName.replaceAll('Small', '').replaceAll('Medium', '').replaceAll('Large', ''); switch (typeName) { case 'defaultLight': return "Aydınlık"; case 'defaultDark': return "Altın Vurgu"; case 'classicLeather': return "Deri"; case 'antique': return "Antika"; case 'blueprint': return "Mimari"; case 'scrapbook': return "Karalama"; case 'japanese': return "Minimalist"; case 'watercolor': return "Suluboya"; default: return typeName; }
  }

  // --- Ana Build Metodu ---
  @override
  Widget build(BuildContext context) {
    // Yükleme veya hata durumu
    if (_isLoading || baseThemes.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }

    // Mevcut tema verileri
    final AppThemeData currentAppliedTheme = ThemeConfig.getAppThemeDataByIndex(_currentThemeIndex);
    final Color primaryColor = currentAppliedTheme.materialTheme.colorScheme.primary;
    final TextStyle titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(color: primaryColor, fontWeight: FontWeight.bold,) ?? const TextStyle();
    final screenWidth = MediaQuery.of(context).size.width;

    // Ana Scaffold
    return ThemedBackground( // Arka plan
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar( // AppBar
          title: const Text("Görünüm Ayarları"),
          centerTitle: true, elevation: 0, backgroundColor: Colors.transparent,
          leading: BackButton(onPressed: () => Navigator.pop(context)), // Geri butonu
        ),
        body: SafeArea( // Sistem UI çakışmalarını önle
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView( // İçerik taşarsa kaydırılabilir yap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Öğeleri genişlet
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(titleStyle), // "Tema Stili" başlığı
                  const SizedBox(height: 8),
                  _buildThemeSelector(context, screenWidth), // Yatay stil seçici (PageView)
                  const SizedBox(height: 16),
                  _buildSeeAllButton(context, primaryColor), // "Tüm Temaları Gör" butonu
                  const SizedBox(height: 24),
                  Center(child: Text('Yazı Tipi Boyutu', style: titleStyle)), // "Yazı Tipi Boyutu" başlığı
                  const SizedBox(height: 16),
                  _buildSizeSelectorSection(context, currentAppliedTheme), // Boyut seçici (SegmentedButton)
                  const SizedBox(height: 24),
                  _buildPreviewSection(context, titleStyle), // "Önizleme" başlığı ve alanı
                  const SizedBox(height: 16),
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

  Widget _buildSeeAllButton(BuildContext context, Color primaryColor) {
    return Center(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
        label: const Text('Tüm Temaları Gör'),
        // ***** DEĞİŞİKLİK BURADA BAŞLIYOR *****
        onPressed: () async { // Fonksiyonu async yap
          // ExploreScreen'e git ve geri dönecek sonucu bekle (NotebookThemeType?)
          final selectedStyleResult = await Navigator.push<NotebookThemeType?>(
            context,
            MaterialPageRoute(builder: (_) => const ExploreScreen()),
          );

          // Geri dönüldüğünde ve bir sonuç varsa (kullanıcı bir stil seçtiyse)
          if (selectedStyleResult != null && mounted) {
            if (kDebugMode) { print("ExploreScreen'den seçilen stil: $selectedStyleResult"); }
            // SettingsThemeScreen'in state'ini güncelle
            setState(() {
              // Seçilen temel stili (_selectedBaseStyle) güncelle
              _selectedBaseStyle = selectedStyleResult;
            });
            // Yeni seçilen stil ve mevcut boyut (_selectedSize) ile temayı uygula
            _updateTheme(); // Temayı güncelleyen metodu çağır
          }
          // ***** DEĞİŞİKLİK BURADA BİTİYOR *****
        },
        style: OutlinedButton.styleFrom( /* ... mevcut stil ayarları ... */
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(20),),
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