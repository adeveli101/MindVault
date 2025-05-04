// lib/features/explore/screens/explore_screen.dart (Yeniden Yapılandırıldı V2: Uygulanan Sola, Otomatik Kaydırma)
// Bu ekran tema UYGULAMAZ. Sadece stilleri gösterir, uygulananı sola alır,
// tıklanan minik resme kayar ve seçilen stili ayarlamak üzere Ayarlar'a geri döner.

import 'dart:math'; // clamp için eklendi
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ========== !!! Gerekli Import'lar !!! ==========
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:stacked_themes/stacked_themes.dart';
// =================================================

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // --- State Variables ---
  late final List<AppThemeData> _originalBaseThemes; // Temaların orijinal sırası
  late List<AppThemeData> _displayThemes; // Ekranda gösterilecek, yeniden sıralanmış liste
  late int _selectedPreviewIndex; // _originalBaseThemes listesindeki seçili index
  late NotebookThemeType? _currentAppliedBaseStyle;
  bool _isLoading = true;
  late ScrollController _scrollController; // Thumbnail listesi için scroll controller

  // Sabitler
  static const double _thumbnailWidth = 80.0;
  static const double _thumbnailPaddingRight = 12.0;
  static const double _thumbnailTotalWidth = _thumbnailWidth + _thumbnailPaddingRight;
  static const double _listHorizontalPadding = 16.0;


  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState(); // Önce super.initState() çağrılmalı
    _scrollController = ScrollController();
    _initializeExploreScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Controller'ı dispose et
    super.dispose();
  }

  /// Ekran state'ini başlatan asenkron yardımcı metod.
  Future<void> _initializeExploreScreen() async {
    // Temaları yükle (orijinal sırayla sakla)
    _originalBaseThemes = ThemeConfig.getBaseThemeRepresentations();

    if (!mounted || _originalBaseThemes.isEmpty) {
      setState(() {
        _isLoading = false;
        _displayThemes = []; // Boş liste ata
      });
      if (kDebugMode) { print("ExploreScreen UYARI: Gösterilecek tema bulunamadı!"); }
      return;
    }

    // Context gerektiren işlemler için callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Callback çalıştığında widget hala mount edilmiş mi?

      try {
        final themeManager = getThemeManager(context);
        final currentThemeIndex = themeManager.selectedThemeIndex ?? 0;
        final currentThemeType = ThemeConfig.getThemeTypeByIndex(currentThemeIndex);
        _currentAppliedBaseStyle = ThemeConfig.getBaseStyle(currentThemeType);

        // Başlangıçta seçili önizleme, mevcut uygulanan tema olsun
        _selectedPreviewIndex = _originalBaseThemes.indexWhere(
              (theme) => ThemeConfig.getBaseStyle(theme.type) == _currentAppliedBaseStyle,
        );
        if (_selectedPreviewIndex == -1) _selectedPreviewIndex = 0; // Bulamazsa ilkini seç

      } catch (e) {
        if (kDebugMode) { print("ExploreScreen initState HATA: Tema bilgileri alınırken sorun oluştu - $e"); }
        _currentAppliedBaseStyle = ThemeConfig.getBaseStyle(_originalBaseThemes.first.type);
        _selectedPreviewIndex = 0;
      } finally {
        // Gösterilecek listeyi hazırla ve yüklemeyi bitir
        _updateDisplayThemes(); // Uygulanmışı başa alacak
        setState(() => _isLoading = false);
        // Başlangıçta uygulanan temaya scroll yap (eğer varsa ve başta değilse)
        _scrollToAppliedThemeIfNeeded(initial: true);
      }
    });
  }

  /// _displayThemes listesini, uygulanan temayı başa alarak günceller.
  void _updateDisplayThemes() {
    if (_originalBaseThemes.isEmpty) {
      _displayThemes = [];
      return;
    }

    _displayThemes = List.from(_originalBaseThemes); // Kopyasını oluştur
    if (_currentAppliedBaseStyle != null) {
      final appliedIndex = _displayThemes.indexWhere(
              (theme) => ThemeConfig.getBaseStyle(theme.type) == _currentAppliedBaseStyle);

      if (appliedIndex > 0) { // Eğer bulunduysa ve zaten başta değilse
        final appliedTheme = _displayThemes.removeAt(appliedIndex);
        _displayThemes.insert(0, appliedTheme);
      }
    }
    // Eğer seçili önizleme index'i artık geçerli değilse (nadiren olmalı), sıfırla.
    if (_selectedPreviewIndex >= _originalBaseThemes.length) {
      _selectedPreviewIndex = 0;
    }
  }

  /// Gerekliyse, thumbnail listesini uygulanan temaya kaydırır.
  void _scrollToAppliedThemeIfNeeded({bool initial = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _currentAppliedBaseStyle == null) return;

      // Uygulanan temanın _displayThemes listesindeki index'ini bul (artık 0 olmalı)
      final appliedDisplayIndex = _displayThemes.indexWhere(
              (theme) => ThemeConfig.getBaseStyle(theme.type) == _currentAppliedBaseStyle);

      if (appliedDisplayIndex == 0 && _scrollController.offset > 0) { // Eğer başta ve scroll 0'da değilse
        _scrollController.animateTo(
          0.0, // En başa git
          duration: Duration(milliseconds: initial ? 500 : 300),
          curve: Curves.easeInOut,
        );
      }
      // Not: Tıklama ile kaydırma _handleThumbnailTap içinde yapılacak.
    });
  }

  /// Gerekliyse, thumbnail listesini belirtilen index'e (display listesindeki) kaydırır.
  void _scrollToThumbnail(int displayIndex) {
    if (!_scrollController.hasClients || displayIndex < 0) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveViewportWidth = screenWidth - (_listHorizontalPadding * 2);

    // Hedeflenen item'ın ortasının olması gereken offset
    final targetCenterOffset = (displayIndex * _thumbnailTotalWidth) + (_thumbnailTotalWidth / 2);

    // Viewport'un ortasına getirmek için gereken scroll offset'i
    var scrollToOffset = targetCenterOffset - (effectiveViewportWidth / 2);

    // Scroll offset'ini geçerli sınırlar içinde tut (0 ve maxScrollExtent arası)
    scrollToOffset = scrollToOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent
    );

    _scrollController.animateTo(
      scrollToOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // --- Helper Methods ---

  String _getBaseStyleName(NotebookThemeType type) {
    // ... (önceki kodla aynı) ...
    String typeName = type.toString().split('.').last;
    typeName = typeName.replaceAll('Small', '').replaceAll('Medium', '').replaceAll('Large', '');
    if (typeName == 'defaultLight') return "Aydınlık";
    if (typeName == 'defaultDark') return "Altın Vurgu";
    if (typeName == 'classicLeather') return "Deri";
    if (typeName == 'antique') return "Antika";
    if (typeName == 'blueprint') return "Mimari";
    if (typeName == 'scrapbook') return "Karalama";
    if (typeName == 'japanese') return "Minimalist";
    if (typeName == 'watercolor') return "Suluboya";
    return typeName;
  }

  void _navigateToSettingsWithStyle(NotebookThemeType selectedStyle) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, selectedStyle);
    } else {
      if (kDebugMode) { print("Hata: Settings ekranına geri dönülemiyor."); }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar ekranına dönülemedi.')),
      );
    }
  }

  /// Thumbnail'a tıklandığında çalışır.
  void _handleThumbnailTap(AppThemeData tappedThemeData, int tappedDisplayIndex) {
    // Tıklanan temanın orijinal listemizdeki index'ini bul
    final originalIndex = _originalBaseThemes.indexWhere(
            (theme) => theme.type == tappedThemeData.type);

    if (originalIndex != -1 && mounted && _selectedPreviewIndex != originalIndex) {
      setState(() {
        // Seçili önizleme index'ini (orijinal listeye göre) güncelle
        _selectedPreviewIndex = originalIndex;
      });
      // Tıklanan thumbnail'a doğru kaydır (display listesindeki index'e göre)
      _scrollToThumbnail(tappedDisplayIndex);
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Yükleme veya Hata Durumları
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_displayThemes.isEmpty) { // _displayThemes kontrolü
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Temalar yüklenemedi veya bulunamadı.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // _selectedPreviewIndex'in geçerliliğini kontrol et (çok nadir bir durum)
    if (_selectedPreviewIndex < 0 || _selectedPreviewIndex >= _originalBaseThemes.length) {
      _selectedPreviewIndex = 0;
    }
    final AppThemeData selectedPreviewTheme = _originalBaseThemes[_selectedPreviewIndex];

    // Ana İçerik
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bölüm 1: Detaylı Önizleme
          Expanded(
            flex: 5,
            child: _buildDetailPreview(context, selectedPreviewTheme),
          ),
          const SizedBox(height: 16),

          // Bölüm 2: Thumbnail Listesi
          SizedBox(
            height: 110,
            child: _buildThumbnailList(context),
          ),
        ],
      ),
    );
  }

  // --- Widget Building Helper Methods ---

  /// Detaylı önizleme alanını oluşturur (öncekiyle büyük ölçüde aynı).
  Widget _buildDetailPreview(BuildContext context, AppThemeData previewTheme) {
    final String styleName = _getBaseStyleName(previewTheme.type);
    final bool isLocked = !previewTheme.isFree;
    final bool isApplied = _currentAppliedBaseStyle != null &&
        ThemeConfig.getBaseStyle(previewTheme.type) == _currentAppliedBaseStyle;

    return Theme(
      data: previewTheme.materialTheme,
      child: Builder(
        builder: (themedContext) {
          final theme = Theme.of(themedContext);
          final colorScheme = theme.colorScheme;
          final textTheme = theme.textTheme;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 4) ), ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack( /* ... İçerik öncekiyle aynı ... */
              fit: StackFit.expand,
              children: [
                // 1. Arka Plan Resmi
                Image.asset(
                  previewTheme.backgroundAssetPath,
                  fit: BoxFit.fill, // Veya BoxFit.cover
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerLowest, // Hata durumunda düz renk
                    child: Center(child: Icon(Icons.error_outline, color: colorScheme.error, size: 40)),
                  ),
                ),
                // 2. İçerik Alanı (Görsel öğelerin üzerine gelecek)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient( colors: [ Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.05), ], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0],),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 15), // İç boşluklar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tema Stili Adı
                      Text( styleName, style: textTheme.headlineMedium?.copyWith( fontWeight: FontWeight.w600, color: colorScheme.onSurface, shadows: [ Shadow( blurRadius: 2, color: Colors.black.withOpacity(0.3)) ] ), textAlign: TextAlign.center,),
                      const SizedBox(height: 12),
                      // Örnek Metinler
                      Text( 'Örnek Başlık Metni', style: textTheme.titleMedium, textAlign: TextAlign.center,),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text( 'Seçili tema uygulandığında gövde metinleri bu şekilde görünecektir.', style: textTheme.bodyMedium?.copyWith(height: 1.4), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,),
                      ),
                      const Spacer(), // Butonu alta iter
                      // Örnek Buton (Sadece görsel amaçlı)
                      ElevatedButton.icon( icon: const Icon(Icons.star_border_rounded, size: 18), label: const Text('Örnek Buton'), onPressed: () {}, style: ElevatedButton.styleFrom( elevation: 4,),),
                      const SizedBox(height: 12),
                      // --- YENİ İŞLEVSELLİK ---
                      // "Bu Stili Ayarla" Butonu
                      if (!isLocked && !isApplied)
                        FilledButton.icon( icon: const Icon(Icons.settings_brightness_rounded, size: 18), label: const Text('Bu Stili Ayarla'),
                          onPressed: () { _navigateToSettingsWithStyle(ThemeConfig.getBaseStyle(previewTheme.type)); },
                          style: FilledButton.styleFrom( backgroundColor: colorScheme.primaryContainer, foregroundColor: colorScheme.onPrimaryContainer,),)
                      // Tema Zaten Uygulanmışsa Bilgi Mesajı
                      else if (isApplied)
                        const Chip( avatar: Icon(Icons.check_circle_outline, size: 16), label: Text('Bu Stil Uygulanmış'),)
                      // Kilitli Tema Mesajı
                      else // isLocked == true
                        const Chip( avatar: Icon(Icons.lock_outline_rounded, size: 16), label: Text('Premium Tema'),),
                      //------------------------
                    ],
                  ),
                ),
                // Kilit İkonu (Eğer Kilitliyse Sağ Üstte)
                if (isLocked)
                  Positioned( top: 10, right: 10, child: Container( padding: const EdgeInsets.all(5), decoration: BoxDecoration( color: Colors.black.withOpacity(0.5), shape: BoxShape.circle,), child: Icon(Icons.lock, color: Colors.white.withOpacity(0.8), size: 18),)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Thumbnail listesini oluşturur.
  Widget _buildThumbnailList(BuildContext context) {
    // _displayThemes listesi _updateDisplayThemes içinde güncellendi.
    return ListView.builder(
      controller: _scrollController, // ScrollController'ı ata
      scrollDirection: Axis.horizontal,
      itemCount: _displayThemes.length,
      padding: const EdgeInsets.symmetric(horizontal: _listHorizontalPadding),
      itemBuilder: (context, displayIndex) { // Artık bu index, _displayThemes'e göre
        final themeData = _displayThemes[displayIndex];
        final originalIndex = _originalBaseThemes.indexWhere((t) => t.type == themeData.type);

        // Seçili önizleme, _originalBaseThemes listesindeki index'e göre belirlenir.
        final bool isSelectedForPreview = originalIndex == _selectedPreviewIndex;
        final bool isApplied = _currentAppliedBaseStyle != null &&
            ThemeConfig.getBaseStyle(themeData.type) == _currentAppliedBaseStyle;
        final bool isLocked = !themeData.isFree;

        return _buildThumbnailCard(
          context: context,
          theme: themeData,
          isSelected: isSelectedForPreview,
          isApplied: isApplied,
          isLocked: isLocked,
          onTap: () {
            // Tıklama işlevini merkezi fonksiyona yönlendir
            _handleThumbnailTap(themeData, displayIndex);
          },
        );
      },
    );
  }


  /// Tek bir thumbnail kartını oluşturur (öncekiyle büyük ölçüde aynı, onTap değişikliği).
  Widget _buildThumbnailCard({
    required BuildContext context,
    required AppThemeData theme,
    required bool isSelected,
    required bool isApplied,
    required bool isLocked,
    required VoidCallback onTap, // Basit VoidCallback yeterli
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color outlineColor = Theme.of(context).colorScheme.outline;
    final Color appliedIndicatorColor = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(right: _thumbnailPaddingRight),
      child: Opacity(
        opacity: isLocked && !isApplied ? 0.7 : 1.0,
        child: InkWell(
          onTap: onTap, // Dışarıdan gelen onTap'ı kullan
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: _thumbnailWidth, // Sabit genişlik kullan
            decoration: BoxDecoration( /* ... Kenarlık önceki gibi ... */
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : (isApplied ? appliedIndicatorColor.withOpacity(0.7) : outlineColor.withOpacity(0.3)),
                width: isSelected ? 3.0 : (isApplied ? 2.0 : 1.0),
              ),
              boxShadow: isSelected ? [ BoxShadow( color: primaryColor.withOpacity(0.25), blurRadius: 5, spreadRadius: 0 )] : [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack( /* ... İçerik önceki gibi ... */
              fit: StackFit.expand,
              children: [
                // Küçük resim önizlemesi
                Image.asset( theme.backgroundAssetPath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container( color: theme.materialTheme.colorScheme.surfaceVariant, child: Icon(Icons.image_not_supported_outlined, size: 20, color: theme.materialTheme.colorScheme.onSurfaceVariant),),),
                // Kilit ikonu
                if (isLocked) Positioned( top: 4, right: 4, child: Icon(Icons.lock, size: 14, color: Colors.white.withOpacity(0.85), shadows: const [Shadow(blurRadius: 2, color: Colors.black54)]),),
                // Uygulandı ikonu
                if (isApplied && !isSelected && !isLocked) Positioned( bottom: 4, left: 4, child: Icon(Icons.check_circle, size: 15, color: Colors.white.withOpacity(0.9), shadows: const [Shadow(blurRadius: 2, color: Colors.black54)]),)
              ],
            ),
          ),
        ),
      ),
    );
  }
} // _ExploreScreenState sınıfının sonu

