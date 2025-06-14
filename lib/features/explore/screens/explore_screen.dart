// lib/features/explore/screens/explore_screen.dart
// Farklı uygulama temalarını keşfetme ekranı.
// Kullanıcı bir stil seçip alttaki butona tıklayarak
// Ayarlar ekranına o stil seçili olarak gidebilir.

import 'package:flutter/foundation.dart'; // clamp, kDebugMode için
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Gerekli Proje İçi Import'lar (Yolların doğruluğunu kontrol edin)
import 'package:mindvault/features/journal/screens/settings/settings_theme_screen.dart'; // Ayarlar ekranına yönlendirme için
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/features/journal/subscription/subscription_screen.dart';
import 'package:stacked_themes/stacked_themes.dart'; // Aktif temayı almak için
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';

// MainScreen içindeki sabitler (tutarlılık için veya global bir yerden alınabilir)
const double kBottomNavHeight = 65.0;
const double kBottomNavBottomMargin = 32.0;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // --- State Değişkenleri ---
  late final List<AppThemeData> _originalBaseThemes; // Temaların orijinal sırası (Medium boyutlular)
  late List<AppThemeData> _displayThemes; // Ekranda gösterilen, yeniden sıralanmış liste
  late int _selectedPreviewIndex; // Önizlenen temanın _originalBaseThemes listesindeki index'i
  late NotebookThemeType? _currentAppliedBaseStyle; // Cihazda o an uygulanan temel stil
  bool _isLoading = true; // Veri yüklenirken gösterilecek bayrak
  late ScrollController _scrollController; // Yatay küçük resim listesi için

  // --- UI Sabitleri ---
  static const double _thumbnailWidth = 85.0; // Küçük resim genişliği biraz arttı
  static const double _thumbnailPaddingRight = 12.0; // Sağ boşluk
  static const double _thumbnailTotalWidth = _thumbnailWidth + _thumbnailPaddingRight; // Toplam genişlik
  static const double _listHorizontalPadding = 16.0; // Listenin kenar boşlukları

  // --- Yaşam Döngüsü Metotları ---
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeExploreScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Ekran state'ini ve tema bilgilerini başlatan metot.
  Future<void> _initializeExploreScreen() async {
    // Temaları yükle (sadece Medium boyutları)
    _originalBaseThemes = ThemeConfig.getBaseThemeRepresentations();

    // Temalar boşsa veya widget ağaçtan kaldırıldıysa işlemi bitir
    if (!mounted || _originalBaseThemes.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _displayThemes = [];
        });
      }
      if (kDebugMode) { print("ExploreScreen UYARI: Gösterilecek tema bulunamadı!"); }
      return;
    }

    // Context gerektiren işlemleri build sonrası çalıştır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Widget hala aktif mi?

      try {
        // Mevcut tema yöneticisinden uygulanan temayı al
        final themeManager = getThemeManager(context);
        final currentThemeIndex = themeManager.selectedThemeIndex ?? 0;
        final currentThemeType = ThemeConfig.getThemeTypeByIndex(currentThemeIndex);
        _currentAppliedBaseStyle = ThemeConfig.getBaseStyle(currentThemeType);

        // Başlangıçta seçili önizleme, mevcut uygulanan tema olsun
        _selectedPreviewIndex = _originalBaseThemes.indexWhere(
              (theme) => ThemeConfig.getBaseStyle(theme.type) == _currentAppliedBaseStyle,
        );
        // Eğer bir şekilde bulunamazsa, listenin ilk temasını seç
        if (_selectedPreviewIndex == -1) _selectedPreviewIndex = 0;

      } catch (e, s) {
        // Hata olursa logla ve varsayılanlara dön
        if (kDebugMode) {
          print("ExploreScreen initState HATA: Tema bilgileri alınamadı - $e");
          print(s);
        }
        _currentAppliedBaseStyle = _originalBaseThemes.isNotEmpty
            ? ThemeConfig.getBaseStyle(_originalBaseThemes.first.type)
            : null; // Eğer _originalBaseThemes de boşsa null ata
        _selectedPreviewIndex = 0;
      } finally {
        // Gösterilecek listeyi güncelle (uygulananı başa al) ve yüklemeyi bitir
        _updateDisplayThemes();
        if (mounted) {
          setState(() => _isLoading = false);
        }
        // Uygulanan temaya doğru kaydırma yap (eğer başta değilse)
        _scrollToAppliedThemeIfNeeded(initial: true);
      }
    });
  }

  /// `_displayThemes` listesini, mevcut uygulanan temayı listenin başına
  /// alacak şekilde günceller ve yeniden oluşturur.
  void _updateDisplayThemes() {
    if (_originalBaseThemes.isEmpty) {
      _displayThemes = [];
      return;
    }

    _displayThemes = List.from(_originalBaseThemes); // Orijinal listenin kopyası
    if (_currentAppliedBaseStyle != null) {
      // Uygulanan temanın index'ini bul
      final appliedIndex = _displayThemes.indexWhere(
              (theme) => ThemeConfig.getBaseStyle(theme.type) == _currentAppliedBaseStyle);

      // Eğer bulunduysa ve zaten başta değilse, başa taşı
      if (appliedIndex > 0) {
        final appliedTheme = _displayThemes.removeAt(appliedIndex);
        _displayThemes.insert(0, appliedTheme);
      }
    }
    // Güvenlik: Seçili index'in sınırlar içinde kaldığından emin ol
    if (_selectedPreviewIndex >= _originalBaseThemes.length) {
      _selectedPreviewIndex = 0;
    }
  }

  // --- Kaydırma (Scroll) Yardımcı Metotları ---

  /// Gerekliyse, küçük resim listesini uygulanan temaya (listenin başına) kaydırır.
  void _scrollToAppliedThemeIfNeeded({bool initial = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _currentAppliedBaseStyle == null) return;
      // Uygulanan temanın gösterilen listedeki index'ini bul (normalde 0 olmalı)
      final appliedDisplayIndex = _displayThemes.indexWhere(
              (theme) => ThemeConfig.getBaseStyle(theme.type) == _currentAppliedBaseStyle);
      // Eğer tema başta ama liste kaydırılmışsa, en başa dön
      if (appliedDisplayIndex == 0 && _scrollController.offset > 1.0) {
        _scrollController.animateTo( 0.0, duration: Duration(milliseconds: initial ? 500 : 350), curve: Curves.easeInOutCubic,);
      }
    });
  }

  /// Küçük resim listesini, belirtilen index'teki temanın ortalanacağı şekilde kaydırır.
  void _scrollToThumbnail(int displayIndex) {
    if (!_scrollController.hasClients || displayIndex < 0 || displayIndex >= _displayThemes.length) return;
    // Gerekli hesaplamaları yap
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveViewportWidth = screenWidth - (_listHorizontalPadding * 2);
    final targetCenterOffset = (displayIndex * _thumbnailTotalWidth) + (_thumbnailTotalWidth / 2);
    var scrollToOffset = targetCenterOffset - (effectiveViewportWidth / 2);
    // Kaydırma miktarını limitler içinde tut
    scrollToOffset = scrollToOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
    // Animasyonla kaydır
    _scrollController.animateTo( scrollToOffset, duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic,);
  }

  // --- Diğer Yardımcı Metotlar ---

  /// Tema tipinden (enum) okunabilir bir stil adı (String) döndürür.
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

  /// Seçilen tema stilini argument olarak göndererek SettingsThemeScreen'e yönlendirir.
  void _navigateToSettingsWithStyle(NotebookThemeType selectedStyle) {
    if (kDebugMode) print("SettingsThemeScreen'e gidiliyor, başlangıç stili: $selectedStyle");
    
    // Premium tema kontrolü
    final isPremium = context.read<SubscriptionBloc>().state is SubscriptionLoaded && 
                     (context.read<SubscriptionBloc>().state as SubscriptionLoaded).isSubscribed;
    
    final selectedTheme = _originalBaseThemes.firstWhere(
      (theme) => ThemeConfig.getBaseStyle(theme.type) == selectedStyle,
      orElse: () => _originalBaseThemes.first,
    );
    
    if (!selectedTheme.isFree && !isPremium) {
      // Premium tema seçildi, kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getBaseStyleName(selectedStyle)} teması için Premium üyelik gereklidir.'),
          action: SnackBarAction(
            label: 'Premium\'a Geç',
            onPressed: () {
              Navigator.pushNamed(context, '/subscription');
            },
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsThemeScreen(initialBaseStyle: selectedStyle),
      ),
    );
  }

  /// Bir küçük resme tıklandığında state'i günceller ve listeyi kaydırır.
  void _handleThumbnailTap(AppThemeData tappedThemeData, int tappedDisplayIndex) {
    // Premium tema kontrolü
    final isPremium = context.read<SubscriptionBloc>().state is SubscriptionLoaded && 
                     (context.read<SubscriptionBloc>().state as SubscriptionLoaded).isSubscribed;
    
    if (!tappedThemeData.isFree && !isPremium) {
      // Premium tema seçildi, SubscriptionScreen'i göster
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const SubscriptionScreen(),
      );
      return;
    }

    // Seçilen temanın orijinal listedeki index'ini bul
    final originalIndex = _originalBaseThemes.indexWhere(
            (theme) => ThemeConfig.getBaseStyle(theme.type) == ThemeConfig.getBaseStyle(tappedThemeData.type));

    if (originalIndex != -1) {
      setState(() {
        _selectedPreviewIndex = originalIndex;
      });
      _scrollToThumbnail(tappedDisplayIndex);
    }
  }

  // --- Ana Build Metodu ---
  @override
  Widget build(BuildContext context) {
    // Yükleme Durumu
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    // Hata Durumu (Tema Yoksa)
    if (_displayThemes.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Temalar yüklenemedi.", textAlign: TextAlign.center,),),);
    }

    // Güvenli Index Erişimi ve Seçili Tema Verisi
    final safeSelectedPreviewIndex = _selectedPreviewIndex.clamp(0, _originalBaseThemes.length - 1);
    final AppThemeData selectedPreviewTheme = _originalBaseThemes[safeSelectedPreviewIndex];

    // Ana Ekran Düzeni
    return Scaffold(
      // Arka planı transparan yapıyoruz ki MainScreen'deki arka plan görünsün
      backgroundColor: Colors.transparent,
      // Eğer bu ekran MainScreen'in bir parçasıysa genellikle AppBar gerekmez.
      // Ancak bağımsız olarak da açılabilirse veya başlık isteniyorsa eklenebilir.
      // appBar: AppBar(
      //   title: const Text('Temaları Keşfet'),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   centerTitle: true,
      // ),
      body: Padding(
        // Alt navigasyon çubuğu ve diğer UI elemanları için genel boşluk
        // Not: Eğer MainScreen içinde kullanılıyorsa, MainScreen'deki padding yeterli olabilir.
        // Bağımsız çalışması için buraya da ekliyoruz.
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + kBottomNavHeight + kBottomNavBottomMargin -90, // Toplam alt boşluk
            top: MediaQuery.of(context).padding.top + 20 // Üst sistem çubuğu için boşluk
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bölüm 1: Detaylı Önizleme Alanı
            Expanded(
              flex: 6, // Önizlemeye biraz daha fazla yer verelim
              child: _buildDetailPreview(context, selectedPreviewTheme),
            ),
            const SizedBox(height: 24), // Alanlar arası boşluk

            // Bölüm 2: Yatay Küçük Resim Listesi
            SizedBox(
              height: 115, // Yüksekliği biraz arttıralım
              child: _buildThumbnailList(context),
            ),
            // const SizedBox(height: 10), // Alt boşluk kaldırıldı, genel padding'e dahil
          ],
        ),
      ),
    );
  }

  // --- Widget Oluşturma Yardımcı Metotları ---

  /// Büyük, detaylı tema önizleme kartını oluşturur.
  Widget _buildDetailPreview(BuildContext context, AppThemeData previewTheme) {
    final String styleName = _getBaseStyleName(previewTheme.type);
    final bool isLocked = !previewTheme.isFree;
    final bool isApplied = _currentAppliedBaseStyle != null &&
        ThemeConfig.getBaseStyle(previewTheme.type) == _currentAppliedBaseStyle;
    final isPremium = context.read<SubscriptionBloc>().state is SubscriptionLoaded && 
                     (context.read<SubscriptionBloc>().state as SubscriptionLoaded).isSubscribed;

    // Önizleme kartını, seçilen temanın kendi Material temasıyla sar
    return Theme(
      data: previewTheme.materialTheme,
      child: Builder(
        builder: (themedContext) {
          final theme = Theme.of(themedContext);
          final colorScheme = theme.colorScheme;
          final textTheme = theme.textTheme;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Arka Plan Resmi
                Image.asset(
                  previewTheme.backgroundAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerLowest,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // İçerik Katmanı (Gradient ile)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tema Adı
                      Text(
                        styleName,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.5),
                            )
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Örnek Metinler
                      Text(
                        'Örnek Başlık',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.95),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Seçili tema ile metinler böyle görünecek. Farklı renkler ve fontlar...',
                          style: textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            color: colorScheme.onSurface.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Örnek Buton
                      ElevatedButton.icon(
                        icon: const Icon(Icons.star_outline_rounded, size: 18),
                        label: const Text('Örnek Buton'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Ayarlar Butonu veya Durum Çipi
                      if (!isLocked || isPremium) // Kilitli değilse veya premium ise butonu göster
                        FilledButton.tonalIcon(
                          icon: Icon(
                            isApplied ? Icons.palette_outlined : Icons.settings_rounded,
                            size: 18,
                          ),
                          label: Text(isApplied ? 'Uygulanan Stili Ayarla' : 'Tema Ayarlarına Git'),
                          onPressed: () {
                            _navigateToSettingsWithStyle(ThemeConfig.getBaseStyle(previewTheme.type));
                          },
                        )
                      else // Kilitliyse çip göster
                        const Chip(
                          avatar: Icon(Icons.lock_outline_rounded, size: 16),
                          label: Text('Premium'),
                        ),
                    ],
                  ),
                ),
                // Kilit İkonu
                if (isLocked && !isPremium)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Yatay kaydırılabilir küçük resim (thumbnail) listesini oluşturur.
  Widget _buildThumbnailList(BuildContext context) {
    // Scrollbar ekleyerek taşma durumunda kaydırma çubuğu gösterelim
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: false, // Sadece kaydırırken görünsün
      trackVisibility: false,
      thickness: 4.0, // Biraz daha kalın
      radius: const Radius.circular(4.0),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _displayThemes.length,
        padding: const EdgeInsets.symmetric(horizontal: _listHorizontalPadding),
        itemBuilder: (context, displayIndex) {
          final themeData = _displayThemes[displayIndex];
          final originalIndex = _originalBaseThemes.indexWhere((t) => t.type == themeData.type);
          // Güvenlik kontrolü, eğer originalIndex bulunamazsa -1 döner.
          if (originalIndex == -1) return const SizedBox.shrink(); // Hata durumunda boş widget

          final bool isSelectedForPreview = originalIndex == _selectedPreviewIndex;
          final bool isApplied = _currentAppliedBaseStyle != null &&
              ThemeConfig.getBaseStyle(themeData.type) == _currentAppliedBaseStyle;
          final bool isLocked = !themeData.isFree;

          // Tek bir küçük resim kartını oluşturan metodu çağır
          return _buildThumbnailCard(
            context: context,
            theme: themeData,
            isSelected: isSelectedForPreview,
            isApplied: isApplied,
            isLocked: isLocked,
            onTap: () { _handleThumbnailTap(themeData, displayIndex); },
          );
        },
      ),
    );
  }

  /// Liste içindeki tek bir tema küçük resim kartını oluşturur.
  Widget _buildThumbnailCard({
    required BuildContext context,
    required AppThemeData theme,
    required bool isSelected,
    required bool isApplied,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color outlineColor = Theme.of(context).colorScheme.outlineVariant; // Daha soluk kenarlık
    final Color appliedIndicatorColor = Theme.of(context).colorScheme.tertiary; // Uygulanan için farklı renk

    return Padding(
      padding: const EdgeInsets.only(right: _thumbnailPaddingRight),
      child: Opacity(
        opacity: isLocked && !isApplied ? 0.75 : 1.0, // Kilitli ve uygulanmamışsa soluk
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14), // Daha yuvarlak
          splashColor: primaryColor.withOpacity(0.1), // Tıklama efekti
          highlightColor: primaryColor.withOpacity(0.05),
          child: Container(
            width: _thumbnailWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14), // Daha yuvarlak
              border: Border.all(
                color: isSelected
                    ? primaryColor // Seçili
                    : (isApplied
                    ? appliedIndicatorColor.withOpacity(0.9) // Uygulanmış
                    : outlineColor.withOpacity(0.5)), // Normal veya kilitli
                width: isSelected ? 3.0 : (isApplied ? 2.0 : 1.2), // Farklı kalınlıklar
              ),
              boxShadow: isSelected // Seçiliyken daha belirgin gölge
                  ? [ BoxShadow( color: primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 0, offset: Offset(0,2) )]
                  : [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 0, offset: Offset(0,1) )],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack( fit: StackFit.expand, children: [
              // Arka plan resmi
              Image.asset( theme.backgroundAssetPath, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container( color: theme.materialTheme.colorScheme.surfaceContainerHighest, child: Icon(Icons.hide_image_outlined, size: 24, color: theme.materialTheme.colorScheme.onSurfaceVariant.withOpacity(0.5)),),
              ),
              // Kilit ikonu
              if (isLocked) Positioned( top: 5, right: 5, child: Container( padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), shape: BoxShape.circle), child: const Icon(Icons.lock, size: 11, color: Colors.white) ) ),
              // Uygulandı ikonu
              if (isApplied && !isSelected && !isLocked) Positioned( bottom: 5, left: 5, child: Container( padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: Icon(Icons.check_circle, size: 14, color: appliedIndicatorColor.withOpacity(0.95)) ) )
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPreview(AppThemeData themeData) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Image.asset(
                  themeData.backgroundAssetPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          themeData.isFree ? Icons.lock_open : Icons.lock,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          themeData.isFree ? 'Ücretsiz' : 'Premium',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        themeData.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!themeData.isFree)
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const SubscriptionScreen(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Premium\'a Yükselt'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} // _ExploreScreenState sınıfının sonu