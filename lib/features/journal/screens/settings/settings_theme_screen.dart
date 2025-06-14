// lib/features/journal/screens/settings/settings_theme_screen.dart
// Tema stilini ve boyutunu ayarlama ekranı.
// ExploreScreen'den gelen başlangıç stilini kabul eder ve uygular.

// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';
import 'package:stacked_themes/stacked_themes.dart';

import 'package:mindvault/features/journal/screens/explore/explore_screen.dart'; // Tüm temaları görme ekranı
import 'package:mindvault/features/journal/screens/themes/themed_background.dart'; // Standart arka plan
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  bool _hasUnsavedChanges = false; // Yeni: Kaydedilmemiş değişiklik var mı?
  late int _previewThemeIndex; // Yeni: Önizleme için tema index'i

  // --- UI Sabitleri ---
  late double _viewportFraction; // PageView'da bir seferde görünen kart oranı
  late double _themeCardHeight; // Stil kartlarının yüksekliği

  // --- Veri ---
  late final List<AppThemeData> baseThemes; // Gösterilecek temel (Medium) tema listesi

  // --- Yaşam Döngüsü Metotları ---
  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _hasUnsavedChanges = false;
    _viewportFraction = 0.85;
    _themeCardHeight = 180.0;

    // Temaları yükle (kullanıcının premium durumuna göre)
    final isPremium = false; // TODO: Premium durumunu al
    baseThemes = ThemeConfig.getAvailableThemes(isPremium);

    // Eğer tema listesi boşsa (beklenmedik durum), hata göster ve geri dön
    if (baseThemes.isEmpty) {
      if (kDebugMode) { print("SettingsThemeScreen UYARI: Tema listesi yüklenemedi."); }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tema listesi yüklenemedi.")));
          Navigator.pop(context);
        }
      });
      _isLoading = false;
      return;
    }

    // Başlangıç state'ini ayarla
    _initializeState();
    _previewThemeIndex = _currentThemeIndex; // Başlangıçta önizleme = mevcut tema

    // PageView başlangıç sayfasını ayarla
    final initialPageIndex = baseThemes.indexWhere((theme) => theme.type == _selectedBaseStyle);
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: initialPageIndex != -1 ? initialPageIndex : 0,
    );

    _pageController.addListener(_updateScrollArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollArrows();
      if (widget.initialBaseStyle != null) {
        Future.delayed(const Duration(milliseconds: 50), () => _scrollToSelectedStyle());
      }
    });

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _restorePreviousTheme();
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

  /// Seçilen stil ve boyuta göre temayı bulur ve önizleme olarak uygular.
  void _updateTheme() {
    // Seçili stil ve boyuta karşılık gelen tam tema index'ini bul
    final newIndex = ThemeConfig.findThemeIndexByStyleAndSize(
        _selectedBaseStyle, _selectedSize);

    // Geçerli bir index bulunduysa
    if (newIndex != -1) {
      final themeManager = getThemeManager(context);
      final currentAppliedIndex = themeManager.selectedThemeIndex ?? 0;
      
      // Sadece mevcut temadan farklıysa yeni temayı önizleme olarak uygula
      if (newIndex != currentAppliedIndex) {
        // Premium tema kontrolü
        final selectedTheme = ThemeConfig.getAppThemeDataByIndex(newIndex);
        final isPremium = context.read<SubscriptionBloc>().state is SubscriptionLoaded && 
                         (context.read<SubscriptionBloc>().state as SubscriptionLoaded).isSubscribed;
        
        if (!selectedTheme.isFree && !isPremium) {
          // Premium tema seçildi, kullanıcıya bilgi ver
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${ThemeConfig.getThemeDisplayName(_selectedBaseStyle)} teması için Premium üyelik gereklidir.'),
              action: SnackBarAction(
                label: 'Premium\'a Geç',
                onPressed: () {
                  // Premium ekranına yönlendir
                  Navigator.pushNamed(context, '/subscription');
                },
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return; // Temayı uygulama
        }
        
        // Önizleme için temayı uygula
        themeManager.selectThemeAtIndex(newIndex);
        if (mounted) {
          setState(() {
            _previewThemeIndex = newIndex;
            _hasUnsavedChanges = true;
          });
        }
        if (kDebugMode) print("Tema önizlemesi güncellendi: Index=$newIndex, Style=$_selectedBaseStyle, Size=$_selectedSize");
      }
    } else {
      // Index bulunamazsa (ThemeConfig hatası olabilir)
      if (kDebugMode) print("Uyarı: _updateTheme içinde tema index'i bulunamadı! Style=$_selectedBaseStyle, Size=$_selectedSize");
    }
  }

  /// Seçilen temayı kalıcı olarak uygular
  void _applySelectedTheme() {
    final themeManager = getThemeManager(context);
    final selectedTheme = ThemeConfig.getAppThemeDataByIndex(_previewThemeIndex);
    final isPremium = context.read<SubscriptionBloc>().state is SubscriptionLoaded && 
                     (context.read<SubscriptionBloc>().state as SubscriptionLoaded).isSubscribed;

    if (!selectedTheme.isFree && !isPremium) {
      // Premium tema seçildi, kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ThemeConfig.getThemeDisplayName(_selectedBaseStyle)} teması için Premium üyelik gereklidir.'),
          action: SnackBarAction(
            label: 'Premium\'a Geç',
            onPressed: () {
              // Premium ekranına yönlendir
              Navigator.pushNamed(context, '/subscription');
            },
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _currentThemeIndex = _previewThemeIndex;
      _hasUnsavedChanges = false;
    });
  }

  /// Ekrandan çıkarken eski temaya geri döner
  void _restorePreviousTheme() {
    if (_hasUnsavedChanges) {
      final themeManager = getThemeManager(context);
      themeManager.selectThemeAtIndex(_currentThemeIndex);
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
  // ignore: unused_element
  String _getBaseStyleName(NotebookThemeType type) {
    String typeName = type.toString().split('.').last;
    typeName = typeName
        .replaceAll('Small', '')
        .replaceAll('Medium', '')
        .replaceAll('Large', '');

    switch (typeName) {
      case 'defaultLight':
        return "Aydınlık";
      case 'defaultDark':
        return "Altın Vurgu";
      case 'classicLeather':
        return "Deri";
      case 'antique':
        return "Antika";
      case 'blueprint':
        return "Mimari";
      case 'scrapbook':
        return "Karalama";
      case 'japanese':
        return "Minimalist";
      case 'watercolor':
        return "Suluboya";
      default:
        return typeName; // Eşleşme yoksa enum ismini döndür
    }
  }

  // --- Ana Build Metodu ---
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          _restorePreviousTheme();
        }
      },
      child: ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(l10n.theme),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: BackButton(
              onPressed: () {
                _restorePreviousTheme();
                Navigator.pop(context);
              },
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildHeader(Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ) ?? const TextStyle()),
                                const SizedBox(height: 8),
                                _buildThemeSelector(context, MediaQuery.of(context).size.width),
                                const SizedBox(height: 16),
                                _buildSeeAllButton(context, Theme.of(context).colorScheme.primary),
                                const SizedBox(height: 24),
                                Center(
                                  child: Text(
                                    l10n.fontSize,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ) ?? const TextStyle(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSizeSelectorSection(
                                  context,
                                  ThemeConfig.getAppThemeDataByIndex(_currentThemeIndex),
                                ),
                                const SizedBox(height: 24),
                                _buildPreviewSection(
                                  context,
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ) ?? const TextStyle(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                ),
                // Uygula butonu
                if (_hasUnsavedChanges)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _applySelectedTheme,
                      icon: const Icon(Icons.check),
                      label: Text(l10n.apply),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
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
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Text(l10n.theme, style: titleStyle));
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
    final isPremium = context.read<SubscriptionBloc>().state is SubscriptionLoaded && 
                     (context.read<SubscriptionBloc>().state as SubscriptionLoaded).isSubscribed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: isLocked && !isPremium
            ? () {
                if (kDebugMode) {
                  print("Kilitli tema tıklandı: ${theme.name}");
                }
                // Premium ekranına yönlendir
                Navigator.pushNamed(context, '/subscription');
              }
            : () {
                if (!isSelected) {
                  setState(() => _selectedBaseStyle = themeType);
                  _updateTheme();
                }
                _animateToPage(index);
              },
        child: Opacity(
          opacity: isLocked && !isPremium && !isSelected ? 0.6 : 1.0,
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
              child: Stack(
                children: [
                  // Tema önizleme resmi
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      theme.backgroundAssetPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Kilit ikonu (eğer kilitli ise ve premium değilse)
                  if (isLocked && !isPremium)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  // Seçili ikonu
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
        label: Text(l10n.seeAllThemes),
        onPressed: () async {
          final selectedStyleResult = await Navigator.push<NotebookThemeType?>(
            context,
            MaterialPageRoute(builder: (_) => const ExploreScreen()),
          );

          if (selectedStyleResult != null && mounted) {
            if (kDebugMode) { print("ExploreScreen'den seçilen stil: $selectedStyleResult"); }
            setState(() {
              _selectedBaseStyle = selectedStyleResult;
            });
            _updateTheme();
          }
        },
        style: OutlinedButton.styleFrom(
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: _buildSizeSelector(context, currentTheme),
    );
  }

  /// SegmentedButton widget'ını oluşturur
  Widget _buildSizeSelector(BuildContext context, AppThemeData currentTheme) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = currentTheme.materialTheme.colorScheme;
    final segments = <ButtonSegment<ThemeSize>>[
      ButtonSegment<ThemeSize>(value: ThemeSize.small, label: Text(l10n.small)),
      ButtonSegment<ThemeSize>(value: ThemeSize.medium, label: Text(l10n.medium)),
      ButtonSegment<ThemeSize>(value: ThemeSize.large, label: Text(l10n.large)),
    ];
    return Center(
      child: SegmentedButton<ThemeSize>(
        segments: segments,
        selected: <ThemeSize>{_selectedSize},
        onSelectionChanged: (Set<ThemeSize> newSelection) {
          if (mounted) {
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Center(child: Text(l10n.preview, style: titleStyle)),
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
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = Theme.of(context);
    final textTheme = currentTheme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sampleTitle,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.sampleText(_selectedSize.toString().split('.').last),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              child: Text(l10n.sampleButton),
            ),
          ),
        ],
      ),
    );
  }
} // _SettingsThemeScreenState sınıfının sonu