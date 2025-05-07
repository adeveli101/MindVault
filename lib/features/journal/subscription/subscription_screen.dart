// lib/features/subscription/screens/subscription_screen.dart
// Yolların doğruluğundan emin olun!
// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stacked_themes/stacked_themes.dart';

// Proje İçi Importlar - KENDİ YOLUNUZLA GÜNCELLEYİN!
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
// SubscriptionBloc import'unuzu kontrol edin
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';


//-------------------------------------------------------------------
// Yardımcı Fonksiyon: Sheet veya Dialog olarak göstermek için
//-------------------------------------------------------------------
Future<void> showSubscriptionSheet(BuildContext context) {
  final subscriptionBloc = BlocProvider.of<SubscriptionBloc>(context);
  final themeManager = getThemeManager(context);
  // Başlangıç tema verisini al (sheet arka planı için)
  final initialThemeData = ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);

  // Sheet içinde önizlenen temayı takip etmek için ValueNotifier
  final ValueNotifier<AppThemeData> previewThemeNotifier = ValueNotifier(initialThemeData);


  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      // ValueListenableBuilder ile önizlenen temayı dinle ve arka planı güncelle
      return ValueListenableBuilder<AppThemeData>(
        valueListenable: previewThemeNotifier,
        builder: (context, previewThemeData, _) {
          // Mevcut global tema (widget stilleri için kullanılabilir)
          final AppThemeData currentGlobalThemeData = ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);

          return BlocProvider.value(
            value: subscriptionBloc,
            child: DraggableScrollableSheet(
              initialChildSize: 0.90,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  clipBehavior: Clip.antiAlias, // Stack içindeki Image'ın taşmasını engelle
                  decoration: const BoxDecoration(
                    // Arka plan artık Stack içinde Image ile sağlanacak
                    // color: previewThemeData.materialTheme.scaffoldBackgroundColor, // <-- KALDIRILDI
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack( // Arka planı ve içeriği üst üste bindir
                    children: [
                      // --- Arka Plan Katmanı ---
                      Positioned.fill(
                        child: Image.asset(
                          previewThemeData.backgroundAssetPath, // Dinamik arka plan
                          fit: BoxFit.fill, // Arka planı kapla
                          errorBuilder: (context, error, stackTrace) => Container( // Hata durumu için renk
                              color: currentGlobalThemeData.materialTheme.scaffoldBackgroundColor
                          ),
                        ),
                      ),
                      // --- İçerik Katmanı ---
                      Column(
                        children: [
                          // Başlık ve Kapat Butonu (Arka planı biraz belirginleştirmek için Container içinde)
                          Container(
                            //color: currentGlobalThemeData.materialTheme.colorScheme.surface.withOpacity(0.8), // Hafif yarı saydam
                            padding: const EdgeInsets.fromLTRB(16, 26, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                IconButton(
                                  icon: Icon(Icons.close,
                                      color: currentGlobalThemeData.materialTheme.colorScheme.onSurface),
                                  onPressed: () => Navigator.pop(sheetContext),
                                ),
                              ],
                            ),
                          ),
                          // Divider(height: 1, color: currentGlobalThemeData.materialTheme.dividerColor.withOpacity(0.5)),
                          Expanded(
                            child: SubscriptionCoreUI(
                              isFullScreen: false,
                              externalScrollController: scrollController,
                              // Callback fonksiyonunu geçerek önizlenen temayı dinle
                              onPreviewThemeChanged: (newPreviewTheme) {
                                previewThemeNotifier.value = newPreviewTheme;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    // Sheet kapandığında ValueNotifier'ı dispose et
    previewThemeNotifier.dispose();
  });
}

//-------------------------------------------------------------------
// Ana Ekran Widget'ı (Tam Sayfa Gösterim İçin)
//-------------------------------------------------------------------
class SubscriptionScreen extends StatefulWidget { // StatefulWidget'a dönüştü
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Önizlenen temanın verisini tutacak state
  AppThemeData? _previewThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Başlangıçta global temayı önizleme olarak ayarla
    if (_previewThemeData == null) {
      final themeManager = getThemeManager(context);
      _previewThemeData = ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeManager = getThemeManager(context);
    // AppBar ve diğer UI elemanları için global temayı kullanmaya devam et
    final AppThemeData currentGlobalThemeData =
    ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);

    // previewThemeData null ise (başlangıçta olabilir), global temayı kullan
    final AppThemeData backgroundThemeToShow = _previewThemeData ?? currentGlobalThemeData;

    final bool isSubscribed =
    (context.watch<SubscriptionBloc>().state is SubscriptionLoaded)
        ? (context.read<SubscriptionBloc>().state as SubscriptionLoaded)
        .isSubscribed
        : false;

    return Scaffold(
      // AppBar'ı global temaya göre stillendir
      appBar: AppBar(
        title: Text(isSubscribed ? 'Premium Temalar' : 'Premium\'a Yükselt'),
        // backgroundColor: currentGlobalThemeData
        //     .materialTheme.appBarTheme.backgroundColor ??
        //     currentGlobalThemeData.materialTheme.colorScheme.surface.withOpacity(0.4),
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      // Scaffold'un arka planını transparan yap, Stack yönetecek
      backgroundColor: Colors.transparent,
      // İçeriği Stack ile sararak dinamik arka plan ekle
      body: Stack(
          children: [
            // --- Arka Plan Katmanı ---
            Positioned.fill(
              child: Image.asset(
                backgroundThemeToShow.backgroundAssetPath, // Önizlenen temanın asset'i
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container( // Hata durumu için renk
                    color: currentGlobalThemeData.materialTheme.scaffoldBackgroundColor
                ),
              ),
            ),
            // --- İçerik Katmanı ---
            // SubscriptionCoreUI'ı doğrudan body olarak kullanma yerine Stack'in üzerine koy
            SubscriptionCoreUI(
              isFullScreen: true,
              // Callback ile önizleme temasını güncelle
              onPreviewThemeChanged: (newPreviewTheme) {
                // Sadece farklı bir tema seçildiğinde setState çağır
                if (mounted && _previewThemeData?.type != newPreviewTheme.type) {
                  setState(() {
                    _previewThemeData = newPreviewTheme;
                  });
                }
              },
            ),
          ]
      ),
    );
  }
}

//-------------------------------------------------------------------
// Çekirdek UI Widget'ı (Hem tam sayfa hem de sheet/dialog için)
//-------------------------------------------------------------------
class SubscriptionCoreUI extends StatefulWidget {
  final bool isFullScreen;
  final ScrollController? externalScrollController;
  // YENİ: Önizlenen tema değiştiğinde dışarıyı bilgilendirmek için callback
  final ValueChanged<AppThemeData>? onPreviewThemeChanged;

  const SubscriptionCoreUI({
    super.key,
    this.isFullScreen = true,
    this.externalScrollController,
    this.onPreviewThemeChanged, // Callback parametresi eklendi
  });

  @override
  State<SubscriptionCoreUI> createState() => _SubscriptionCoreUIState();
}

class _SubscriptionCoreUIState extends State<SubscriptionCoreUI> {
  NotebookThemeType? _selectedBaseStyleForPreview;
  PageController? _pageController;
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  final double _themeCardHeight = 180;
  final double _viewportFraction = 0.45;
  List<AppThemeData> _displayableThemes = [];

  @override
  void initState() {
    super.initState();
    _initializeThemesAndController();

    // Başlangıçta seçili olan temayı dışarıya bildir (eğer callback varsa)
    if (widget.onPreviewThemeChanged != null && _displayableThemes.isNotEmpty && _pageController != null) {
      final initialThemeIndex = _pageController!.initialPage.clamp(0, _displayableThemes.length - 1);
      if(initialThemeIndex >= 0 && initialThemeIndex < _displayableThemes.length){
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted){
            widget.onPreviewThemeChanged!(_displayableThemes[initialThemeIndex]);
          }
        });
      }

    }

    final currentState = context.read<SubscriptionBloc>().state;
    if (currentState is SubscriptionInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SubscriptionBloc>().add(LoadSubscriptionStatus());
      });
    }
  }

  void _initializeThemesAndController() {
    if (!mounted) return;

    _displayableThemes = ThemeConfig.getBaseThemeRepresentations();

    if (_displayableThemes.isEmpty) {
      if (kDebugMode) print("SubscriptionCoreUI UYARI: Gösterilecek tema listesi boş.");
      return;
    }


    final themeManager = getThemeManager(context);
    final currentAppliedThemeType =
    ThemeConfig.getThemeTypeByIndex(themeManager.selectedThemeIndex ?? 0);
    // _selectedBaseStyleForPreview, başlangıçta uygulanan temayla aynı olsun
    _selectedBaseStyleForPreview =
        ThemeConfig.getBaseStyle(currentAppliedThemeType);

    int initialPageIndex = _displayableThemes.indexWhere(
            (theme) => ThemeConfig.getBaseStyle(theme.type) == _selectedBaseStyleForPreview);
    if (initialPageIndex == -1 && _displayableThemes.isNotEmpty) {
      initialPageIndex = 0;
    }

    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: initialPageIndex >= 0 ? initialPageIndex : 0,
    );

    _pageController!.addListener(_updateScrollArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) _updateScrollArrows();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pageController == null && _displayableThemes.isNotEmpty) {
      _initializeThemesAndController();
    }
  }

  @override
  void dispose() {
    _pageController?.removeListener(_updateScrollArrows);
    _pageController?.dispose();
    super.dispose();
  }

  void _updateScrollArrows() {
    if (_pageController == null || !_pageController!.hasClients || !mounted) return;
    final currentPage = _pageController!.page ?? _pageController!.initialPage.toDouble();
    final maxPages = _displayableThemes.length;

    if (maxPages <= (1 / _viewportFraction).floor() || maxPages == 0) {
      if (_showLeftArrow || _showRightArrow) {
        setState(() { _showLeftArrow = false; _showRightArrow = false; });
      }
      return;
    }

    bool newShowLeft = currentPage > 0.1;
    bool newShowRight = _pageController!.position.pixels < (_pageController!.position.maxScrollExtent - 5);

    if (newShowLeft != _showLeftArrow || newShowRight != _showRightArrow) {
      setState(() { _showLeftArrow = newShowLeft; _showRightArrow = newShowRight; });
    }
  }


  String _getBaseStyleName(NotebookThemeType type) {
    String typeName = type.toString().split('.').last;
    typeName = typeName
        .replaceAll('Small', '')
        .replaceAll('Medium', '')
        .replaceAll('Large', '');
    switch (typeName) {
      case 'defaultLight': return "Aydınlık";
      case 'defaultDark': return "Altın Vurgu";
      case 'classicLeather': return "Deri";
      case 'antique': return "Antika";
      case 'blueprint': return "Mimari";
      case 'scrapbook': return "Karalama";
      case 'japanese': return "Minimalist";
      case 'watercolor': return "Suluboya";
      default: return typeName;
    }
  }

  // TEMA UYGULAMA FONKSİYONU GÜNCELLENDİ
  void _applyTheme(AppThemeData themeToApply, ThemeManager themeManager,
      BuildContext blocContext, bool isSubscribed) {

    final newSelectedBaseStyle = ThemeConfig.getBaseStyle(themeToApply.type);

    // Kilitli tema kontrolü
    if (!themeToApply.isFree && !isSubscribed) {
      ScaffoldMessenger.of(blocContext).showSnackBar(
        SnackBar(
          content: Text(
              '${_getBaseStyleName(newSelectedBaseStyle)} teması için Premium üyelik gereklidir.'),
          action: SnackBarAction(
            label: 'Abone Ol',
            onPressed: () {
              blocContext.read<SubscriptionBloc>().add(PurchaseSubscription());
            },
          ),
          backgroundColor: Theme.of(blocContext).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Kilitli temaya tıklanınca önizlemeyi de değiştirmeyelim
      return;
    }

    // Sadece seçili stil önizlemesini güncelle (eğer farklıysa)
    if (mounted && _selectedBaseStyleForPreview != newSelectedBaseStyle) {
      setState(() {
        _selectedBaseStyleForPreview = newSelectedBaseStyle;
      });
      // Yeni seçilen temanın verisini dışarıya bildir
      widget.onPreviewThemeChanged?.call(themeToApply);
    }

    // GLOBAL TEMA DEĞİŞİKLİĞİ YOK!
    // themeManager.selectThemeAtIndex(...) çağrısı kaldırıldı.
  }


  @override
  Widget build(BuildContext context) {
    // Global temayı widget stilleri için alalım
    final themeManager = getThemeManager(context);
    final AppThemeData currentGlobalThemeData =
    ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);
    final Color currentPrimaryColor =
        currentGlobalThemeData.materialTheme.colorScheme.primary;

    if (_displayableThemes.isEmpty || _pageController == null) {
      return Center(
        child: _displayableThemes.isEmpty
            ? const Text("Temalar yüklenemedi.")
            : const CircularProgressIndicator(),
      );
    }

    // BlocConsumer yapısı aynı kalıyor
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listenWhen: (previous, current) {
        if (previous is SubscriptionLoading && current is SubscriptionLoaded && current.isSubscribed) return true;
        if (previous is SubscriptionLoaded && !previous.isSubscribed && current is SubscriptionLoaded && current.isSubscribed) return true;
        return false;
      },
      listener: (context, state) {
        if (state is SubscriptionLoaded && state.isSubscribed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Premium üyeliğiniz aktif! Tüm temalara erişebilirsiniz.'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isSubscribed = (state is SubscriptionLoaded) ? state.isSubscribed : false;
        final String? price = (state is SubscriptionLoaded) ? state.price : null;

        Widget loadingIndicator = const Center(child: CircularProgressIndicator());

        if (state is SubscriptionInitial || (state is SubscriptionLoading && _displayableThemes.isEmpty)) {
          return widget.isFullScreen
              ? Center(key: UniqueKey(), child: const CircularProgressIndicator())
              : loadingIndicator;
        }

        // Ana içerik
        final contentColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hata gösterimi (global temayı kullanır)
            if (widget.isFullScreen && state is SubscriptionError && !isSubscribed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  color: currentGlobalThemeData.materialTheme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      state.message,
                      style: TextStyle(color: currentGlobalThemeData.materialTheme.colorScheme.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            // Abone değilse gösterilecekler (global temayı kullanır)
            if (!isSubscribed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'MindVault Premium',
                  style: currentGlobalThemeData.materialTheme.textTheme.headlineMedium?.copyWith(
                    color: currentPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Tüm temalara ve özelliklere erişim sağlayarak MindVault\'ı kişiselleştirin.',
                  style: currentGlobalThemeData.materialTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,

                      color: currentGlobalThemeData.materialTheme.colorScheme.inverseSurface.withOpacity(0.9),
                      shadows: [Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.2))]
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              if (price != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column( // Card yerine Column
                    children: [

                      // Fiyat Gösterimi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            price, // Fiyatın para birimini içerdiği varsayılıyor (örn: "₺19,99")
                            style: currentGlobalThemeData.materialTheme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: currentGlobalThemeData.materialTheme.colorScheme.onSurface,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.3))]
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0), // Baseline ayarı
                            child: Text(
                              '/aylık', // TODO: Bu bilgiyi dinamik yap (örn. ProductDetails.description'dan?)
                              style: currentGlobalThemeData.materialTheme.textTheme.titleMedium?.copyWith(
                                  color: currentGlobalThemeData.materialTheme.colorScheme.onSurface,
                                  shadows: [Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.2))]
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Abone Ol Butonu
                      ElevatedButton.icon(
                        icon: const Icon(Icons.star_border_rounded, size: 20), // İkon güncellendi
                        label: const Text('Hemen Premium Ol'), // Metin güncellendi
                        onPressed: () { context.read<SubscriptionBloc>().add(PurchaseSubscription()); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentPrimaryColor.withOpacity(0.95), // Hafif opaklık
                          foregroundColor: currentGlobalThemeData.materialTheme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          textStyle: currentGlobalThemeData.materialTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 5, // Gölge artırıldı
                          shadowColor: Colors.black.withOpacity(0.5), // Gölge belirginleştirildi
                        ),
                      ),
                      const SizedBox(height: 12), // Buton altı boşluk
                      // İptal bilgisi metni
                      Text(
                        "Abonelik otomatik yenilenir. İstediğiniz zaman iptal edebilirsiniz.",
                        textAlign: TextAlign.center,
                        style: currentGlobalThemeData.materialTheme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: currentGlobalThemeData.materialTheme.colorScheme.onSurface.withOpacity(0.7),
                            shadows: [Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.1))]
                        ),
                      ),
                    ],
                  ),
                )
              else if (state is! SubscriptionLoading) // Fiyat yoksa ve yüklenmiyorsa
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        'Premium abonelik bilgileri alınamadı.',
                        textAlign: TextAlign.center,
                        style: currentGlobalThemeData.materialTheme.textTheme.bodyLarge?.copyWith(color: currentGlobalThemeData.materialTheme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                        onPressed: () { context.read<SubscriptionBloc>().add(LoadSubscriptionStatus()); },
                        style: OutlinedButton.styleFrom(foregroundColor: currentPrimaryColor, side: BorderSide(color: currentPrimaryColor.withOpacity(0.7))),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
            // Tema seçici başlığı (global temayı kullanır)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                isSubscribed ? 'Tüm Temalar' : 'Tema Stilleri',
                style: currentGlobalThemeData.materialTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: currentPrimaryColor.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Tema Seçici (Kendi UI'ı var)
            _buildThemeSelector(context, isSubscribed, themeManager),
            const SizedBox(height: 24),
            // Alt mesaj (global temayı kullanır)
            if (!isSubscribed && _displayableThemes.any((t) => !t.isFree))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
                child: Text(
                  "✨ Kilitli temaları açmak ve tüm özelliklerden yararlanmak için Premium'a geçin.",
                  textAlign: TextAlign.center,
                  style: currentGlobalThemeData.materialTheme.textTheme.bodyMedium?.copyWith(
                    color: currentGlobalThemeData.materialTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            SizedBox(height: widget.isFullScreen ? 20 : 8),
          ],
        );

        // İçeriği döndür
        if (widget.isFullScreen) {
          // Tam ekranda, arka plan Stack ile yönetildiği için burası transparan olmalı
          // ve içeriği kaydırılabilir yapmalı
          return SafeArea(
              child: Container(
                color: Colors.transparent, // Önemli: Stack'teki arka planın görünmesini sağlar
                child: SingleChildScrollView(
                  controller: widget.externalScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: contentColumn,
                ),
              )
          );
        } else {
          // Sheet modunda, dış Container arka planı yönettiği için burası da transparan olmalı
          return Container(
              color: Colors.transparent, // Önemli: Stack'teki arka planın görünmesini sağlar
              child: Scrollbar(
                controller: widget.externalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: widget.externalScrollController,
                  padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 8),
                  child: contentColumn,
                ),
              )
          );
        }
      },
    );
  }


  // _buildThemeSelector, _buildThemeSelectorCard, _buildScrollArrow metotları öncekiyle aynı kalabilir
  // Sadece _applyTheme'in çağrıldığı yere dikkat edin.

  Widget _buildThemeSelector(
      BuildContext context, bool isUserSubscribed, ThemeManager themeManager) {
    if (_pageController == null || _displayableThemes.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text("Tema seçici yüklenemedi.")));
    }
    return SizedBox(
      height: _themeCardHeight + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _displayableThemes.length,
              itemBuilder: (context, index) {
                final themeData = _displayableThemes[index];
                // Önizleme için seçili olanı _selectedBaseStyleForPreview'a göre belirle
                final bool isSelectedForPreview = _selectedBaseStyleForPreview ==
                    ThemeConfig.getBaseStyle(themeData.type);
                return _buildThemeSelectorCard(
                  context,
                  themeData,
                  isSelected: isSelectedForPreview, // Önizleme seçimi
                  isLocked: !themeData.isFree && !isUserSubscribed,
                  onTap: () {
                    // _applyTheme SADECE önizlemeyi güncelleyecek ve callback yapacak
                    _applyTheme(themeData, themeManager, context, isUserSubscribed);
                    // Sayfayı kaydır
                    if(_pageController!.hasClients) {
                      _pageController!.animateToPage(index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  },
                );
              },
            ),
          ),
          if (_showLeftArrow)
            Positioned(
              left: 0,
              child: _buildScrollArrow(
                context,
                Icons.arrow_back_ios_new_rounded,
                    () {
                  if(_pageController!.hasClients) {
                    _pageController!.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                  }
                },
              ),
            ),
          if (_showRightArrow)
            Positioned(
              right: 0,
              child: _buildScrollArrow(
                context,
                Icons.arrow_forward_ios_rounded,
                    () {
                  if(_pageController!.hasClients) {
                    _pageController!.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeSelectorCard(
      BuildContext context,
      AppThemeData theme, {
        required bool isSelected, // isSelected artık sadece önizleme vurgusu için
        required bool isLocked,
        required VoidCallback onTap,
      }) {
    // Kartın görünümü için global temayı kullan
    final AppThemeData currentGlobalTheme = ThemeConfig.getAppThemeDataByIndex(
        getThemeManager(context).selectedThemeIndex ?? 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(
          horizontal: 6.0, vertical: isSelected ? 2 : 10.0),
      transform:
      isSelected ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: isLocked && !isSelected ? 0.65 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: currentGlobalTheme
                  .materialTheme.colorScheme.surfaceContainer // Global tema rengi
                  .withOpacity(isSelected ? 1.0 : 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? currentGlobalTheme.materialTheme.colorScheme.primary // Global tema birincil rengi
                    : (isLocked
                    ? Colors.grey.shade500
                    : currentGlobalTheme
                    .materialTheme.dividerColor
                    .withOpacity(0.5)),
                width: isSelected ? 3.0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                    color: currentGlobalTheme
                        .materialTheme.colorScheme.primary
                        .withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1)
              ]
                  : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          theme.backgroundAssetPath, // Kartın kendi asset'i
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (ctx, err, st) => Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 40,
                                  color: currentGlobalTheme.materialTheme
                                      .colorScheme.onSurfaceVariant
                                      .withOpacity(0.5))),
                        ),
                      ),
                      if (isLocked)
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Icon(Icons.lock_rounded,
                                color: Colors.white.withOpacity(0.9), size: 36),
                          ),
                        ),
                      // Seçili işareti, sadece önizleme için
                      if (isSelected && !isLocked)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: currentGlobalTheme.materialTheme
                                    .colorScheme.primaryContainer
                                    .withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_circle,
                                  size: 18,
                                  color: currentGlobalTheme.materialTheme
                                      .colorScheme.onPrimaryContainer)),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    _getBaseStyleName(theme.type),
                    textAlign: TextAlign.center,
                    style: currentGlobalTheme
                        .materialTheme.textTheme.labelLarge
                        ?.copyWith(
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? currentGlobalTheme
                          .materialTheme.colorScheme.primary
                          : currentGlobalTheme.materialTheme
                          .colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollArrow(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    // Oklar için global temayı kullan
    final AppThemeData currentGlobalTheme = ThemeConfig.getAppThemeDataByIndex(
        getThemeManager(context).selectedThemeIndex ?? 0);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: currentGlobalTheme
              .materialTheme.colorScheme.surfaceContainerHighest
              .withOpacity(0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 5,
                offset: const Offset(0, 1))
          ],
          border: Border.all(
              color: currentGlobalTheme.materialTheme.dividerColor
                  .withOpacity(0.5),
              width: 0.5)),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 20,
              color: currentGlobalTheme
                  .materialTheme.colorScheme.onSurfaceVariant
                  .withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
} // _SubscriptionCoreUIState sonu