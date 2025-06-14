// lib/features/subscription/screens/subscription_screen.dart
// Yolların doğruluğundan emin olun!
// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stacked_themes/stacked_themes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Proje İçi Importlar - KENDİ YOLUNUZLA GÜNCELLEYİN!
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
// SubscriptionBloc import'unuzu kontrol edin
import 'package:mindvault/features/journal/subscription/subscription_bloc.dart';


//-------------------------------------------------------------------
// Yardımcı Fonksiyon: Sheet veya Dialog olarak göstermek için
//-------------------------------------------------------------------
Future<void> showSubscriptionSheet(BuildContext context) async {
  final themeManager = getThemeManager(context);
  final AppThemeData currentGlobalThemeData =
      ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    routeSettings: const RouteSettings(name: '/subscription'),
    builder: (BuildContext context) {
      return Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.12,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          children: [
            // Arka plan resmi
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  currentGlobalThemeData.backgroundAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: currentGlobalThemeData.materialTheme.scaffoldBackgroundColor,
                  ),
                ),
              ),
            ),
            // İçerik
            SubscriptionScreen(
              isFullScreen: false,
              onPreviewThemeChanged: (themeData) {
                // Tema önizlemesi için callback
                if (context.mounted) {
                  final themeManager = getThemeManager(context);
                  final themeIndex = ThemeConfig.getIndexByThemeType(themeData.type);
                  themeManager.selectThemeAtIndex(themeIndex);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

//-------------------------------------------------------------------
// Ana Ekran Widget'ı (Tam Sayfa Gösterim İçin)
//-------------------------------------------------------------------
class SubscriptionScreen extends StatefulWidget {
  final bool isFullScreen;
  final ScrollController? externalScrollController;
  final ValueChanged<AppThemeData>? onPreviewThemeChanged;

  const SubscriptionScreen({
    super.key,
    this.isFullScreen = true,
    this.externalScrollController,
    this.onPreviewThemeChanged,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
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
      if (kDebugMode) print("SubscriptionScreen UYARI: Gösterilecek tema listesi boş.");
      return;
    }

    final themeManager = getThemeManager(context);
    final currentAppliedThemeType =
        ThemeConfig.getThemeTypeByIndex(themeManager.selectedThemeIndex ?? 0);
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

  void _applyTheme(AppThemeData themeToApply, ThemeManager themeManager,
      BuildContext blocContext, bool isSubscribed) {
    final l10n = AppLocalizations.of(blocContext)!;
    final newSelectedBaseStyle = ThemeConfig.getBaseStyle(themeToApply.type);

    // Kilitli tema kontrolü
    if (!themeToApply.isFree && !isSubscribed) {
      ScaffoldMessenger.of(blocContext).showSnackBar(
        SnackBar(
          content: Text(
              l10n.themeLocked(_getBaseStyleName(newSelectedBaseStyle))),
          action: SnackBarAction(
            label: l10n.subscribe,
            onPressed: () {
              blocContext.read<SubscriptionBloc>().add(PurchaseSubscription('subs'));
            },
          ),
          backgroundColor: Theme.of(blocContext).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listenWhen: (previous, current) {
        if (current is SubscriptionLoaded) {
          if (current.isSubscribed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.premiumActive),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else if (current is SubscriptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(current.message),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      },
      listener: (context, state) {
        // State changes are handled in listenWhen
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        
        if (state is SubscriptionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SubscriptionError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<SubscriptionBloc>().add(LoadSubscriptionStatus());
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        } else if (state is SubscriptionLoaded) {
          if (state.isSubscribed) {
            return _buildPremiumContent(context);
          } else {
            return _buildSubscriptionContent(context, state.prices);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPremiumContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.premiumActive,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildPremiumFeature(
          context,
          Icons.palette,
          l10n.premiumThemes,
          l10n.premiumThemesDescription,
        ),
        const SizedBox(height: 16),
        _buildPremiumFeature(
          context,
          Icons.star,
          l10n.premiumFeatures,
          l10n.premiumFeaturesDescription,
        ),
        const SizedBox(height: 16),
        _buildPremiumFeature(
          context,
          Icons.support,
          l10n.premiumSupport,
          l10n.premiumSupportDescription,
        ),
      ],
    );
  }

  Widget _buildSubscriptionContent(BuildContext context, Map<String, String?> prices) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.premiumFeatures,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildPremiumFeature(
          context,
          Icons.palette,
          l10n.premiumThemes,
          l10n.premiumThemesDescription,
        ),
        const SizedBox(height: 16),
        _buildPremiumFeature(
          context,
          Icons.star,
          l10n.premiumFeatures,
          l10n.premiumFeaturesDescription,
        ),
        const SizedBox(height: 16),
        _buildPremiumFeature(
          context,
          Icons.support,
          l10n.premiumSupport,
          l10n.premiumSupportDescription,
        ),
        const SizedBox(height: 32),
        if (prices.isNotEmpty) ...[
          _buildSubscriptionOption(
            context,
            title: l10n.premiumWeekly,
            price: (prices['mindvault-sub-weekly'] != null)
                ? '${prices['mindvault-sub-weekly']}${l10n.weeklyPriceSuffix}'
                : l10n.seePriceOnGooglePlay,
            description: l10n.premiumWeeklyDescription,
            onTap: () => context.read<SubscriptionBloc>().add(
              PurchaseSubscription('mindvault-sub-weekly'),
            ),
          ),
          const SizedBox(height: 16),
          _buildSubscriptionOption(
            context,
            title: l10n.premiumMonthly,
            price: (prices['subs'] != null)
                ? '${prices['subs']}${l10n.monthlyPriceSuffix}'
                : l10n.seePriceOnGooglePlay,
            description: l10n.premiumMonthlyDescription,
            onTap: () => context.read<SubscriptionBloc>().add(
              PurchaseSubscription('subs'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.read<SubscriptionBloc>().add(RestorePurchases());
          },
          child: Text(l10n.restorePurchases),
        ),
      ],
    );
  }

  Widget _buildSubscriptionOption(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required VoidCallback onTap,
  }) {
    final themeManager = getThemeManager(context);
    final AppThemeData currentGlobalThemeData =
        ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: currentGlobalThemeData.materialTheme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currentGlobalThemeData.materialTheme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: currentGlobalThemeData.materialTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: currentGlobalThemeData.materialTheme.textTheme.bodyMedium?.copyWith(
                      color: currentGlobalThemeData.materialTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: currentGlobalThemeData.materialTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: currentGlobalThemeData.materialTheme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final themeManager = getThemeManager(context);
    final AppThemeData currentGlobalThemeData =
        ThemeConfig.getAppThemeDataByIndex(themeManager.selectedThemeIndex ?? 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentGlobalThemeData.materialTheme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentGlobalThemeData.materialTheme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentGlobalThemeData.materialTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: currentGlobalThemeData.materialTheme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: currentGlobalThemeData.materialTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: currentGlobalThemeData.materialTheme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: currentGlobalThemeData.materialTheme.textTheme.bodyMedium?.copyWith(
                    color: currentGlobalThemeData.materialTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                final bool isSelectedForPreview = _selectedBaseStyleForPreview ==
                    ThemeConfig.getBaseStyle(themeData.type);
                return _buildThemeSelectorCard(
                  context,
                  themeData,
                  isSelected: isSelectedForPreview,
                  isLocked: !themeData.isFree && !isUserSubscribed,
                  onTap: () {
                    _applyTheme(themeData, themeManager, context, isUserSubscribed);
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
        required bool isSelected,
        required bool isLocked,
        required VoidCallback onTap,
      }) {
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
                  .materialTheme.colorScheme.surfaceContainer
                  .withOpacity(isSelected ? 1.0 : 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? currentGlobalTheme.materialTheme.colorScheme.primary
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
                          theme.backgroundAssetPath,
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
}