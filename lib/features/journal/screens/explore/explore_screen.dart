// lib/features/explore/screens/explore_screen.dart (Detaylı Önizlemeli Keşfet Ekranı)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ========== !!! IMPORT YOLLARINI KONTROL ET VE TUTARLI YAP !!! ==========
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
// =====================================================================
import 'package:stacked_themes/stacked_themes.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Gösterilecek temsilci temalar (Orta boyutlular)
  late final List<AppThemeData> _availableBaseThemes;
  // Üstte detaylı gösterilen temanın index'i
  late int _selectedPreviewIndex;
  // Mevcut uygulanan temanın temel stili (alttaki listede vurgulamak için)
  late NotebookThemeType _currentAppliedBaseStyle;

  @override
  void initState() {
    super.initState();
    _availableBaseThemes = ThemeConfig.getBaseThemeRepresentations();

    // Eğer tema listesi boşsa hata oluşmasın
    if (_availableBaseThemes.isEmpty) {
      _selectedPreviewIndex = 0; // veya -1 gibi geçersiz bir değer
      _currentAppliedBaseStyle = NotebookThemeType.defaultLightMedium; // Varsayılan
      if (kDebugMode) {
        if (kDebugMode) {
          print("UYARI: Gösterilecek tema bulunamadı!");
        }
      }
      return;
    }

    // Mevcut uygulanan temayı al
    final themeManager = getThemeManager(context);
    final currentThemeIndex = themeManager.selectedThemeIndex ?? 0;
    final currentThemeType = ThemeConfig.getThemeTypeByIndex(currentThemeIndex);
    _currentAppliedBaseStyle = ThemeConfig.getBaseStyle(currentThemeType);

    // Başlangıçta gösterilecek önizleme, mevcut uygulanan tema olsun
    _selectedPreviewIndex = _availableBaseThemes.indexWhere(
          (theme) => theme.type == _currentAppliedBaseStyle,
    );
    // Eğer mevcut tema listede bulunamazsa ilk temayı göster
    if (_selectedPreviewIndex == -1) {
      _selectedPreviewIndex = 0;
    }
  }

  // Tema tipi enum'ından okunabilir bir stil adı döndürür
  String _getBaseStyleName(NotebookThemeType type) {
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

  /// Seçilen temayı uygulama geneline uygular (Orta boyutu)
  void _applyTheme(BuildContext context, AppThemeData themeToApply) {
    final themeManager = getThemeManager(context);
    // Uygulanacak temanın (muhtemelen Medium varyant) ana listedeki indeksini bul
    final themeIndex = ThemeConfig.getIndexByThemeType(themeToApply.type);
    if (themeIndex != -1) {
      themeManager.selectThemeAtIndex(themeIndex);
      // State'i güncelleyerek alttaki listede seçili olanı da güncelle
      if(mounted) {
        setState(() {
          _currentAppliedBaseStyle = themeToApply.type;
        });
      }
      if (kDebugMode) {
        print("${themeToApply.name} teması uygulandı (Index: $themeIndex).");
      }
    } else {
      if (kDebugMode) {
        print("Hata: ${themeToApply.name} (${themeToApply.type}) için index bulunamadı.");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tema uygulanırken bir hata oluştu.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Eğer başlangıçta tema yüklenemediyse boş ekran göster
    if (_availableBaseThemes.isEmpty) {
      return const ThemedBackground(child: Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text("Tema bulunamadı."))));
    }

    // Önizlemede gösterilecek tema
    final AppThemeData selectedPreviewTheme = _availableBaseThemes[_selectedPreviewIndex];

    return ThemedBackground( // Ana uygulamanın temasıyla arka plan
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Temaları Keşfet'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Üst Kısım: Detaylı Önizleme ---
            Expanded(
              flex: 3, // Daha fazla yer kaplasın
              child: _buildDetailPreview(context, selectedPreviewTheme),
            ),
            // --- Alt Kısım: Kaydırılabilir Küçük Önizlemeler ---
            _buildThumbnailList(context),
          ],
        ),
      ),
    );
  }

  /// Üstteki detaylı önizleme alanını oluşturur
  Widget _buildDetailPreview(BuildContext context, AppThemeData previewTheme) {
    final String styleName = _getBaseStyleName(previewTheme.type);
    final bool isLocked = !previewTheme.isFree;
    final bool isApplied = previewTheme.type == _currentAppliedBaseStyle;

    // Önizleme içeriğini, önizlenen temanın kendi stilleriyle göstermek için Theme widget'ı kullanıyoruz
    return Theme(
      data: previewTheme.materialTheme, // ÖNİZLENEN TEMAYI UYGULA
      child: Builder( // Yeni temayı context'e yüklemek için Builder
        builder: (themedContext) {
          final theme = Theme.of(themedContext); // Artık önizlenen tema
          final colorScheme = theme.colorScheme;
          final textTheme = theme.textTheme;

          return Container(
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
            decoration: BoxDecoration(
              // Kenarlık veya gölge eklenebilir
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 2),
                ]
            ),
            clipBehavior: Clip.antiAlias, // İçeriği kırp
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Arka Plan Resmi
                Image.asset(
                  previewTheme.backgroundAssetPath,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => Container(
                      color: colorScheme.surface,
                      child: Center(child: Icon(Icons.error_outline, color: colorScheme.error))),
                ),
                // 2. İçerik Alanı (Hafif opak arka planla okunabilirlik)
                Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            colorScheme.surface.withOpacity(0.05), // Üstte daha opak
                            colorScheme.surface.withOpacity(0.05), // Ortada
                            colorScheme.surface.withOpacity(0.05), // Altta daha opak
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight
                      )
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tema Adı
                      Text(
                        styleName,
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      // Örnek Metinler (Temanın kendi font ve rengiyle)
                      Text(
                        'Örnek Başlık Metni',
                        style: textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu tema seçildiğinde gövde metinleri bu şekilde görünecektir. ${textTheme.bodyLarge?.fontFamily} fontu kullanılıyor.',
                        style: textTheme.bodyLarge?.copyWith(height: 1.5), // Satır aralığı
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(), // Aradaki boşluğu doldur
                      // Örnek Buton
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Örnek Buton'),
                        // Stil otomatik olarak themedContext'ten (önizlenen tema) gelir
                      ),
                      const SizedBox(height: 10),
                      // Uygula / Seçili Butonu
                      if (!isLocked)
                        ElevatedButton.icon(
                          icon: Icon(isApplied ? Icons.check_circle : Icons.check_circle_outline, size: 18),
                          label: Text(isApplied ? 'Uygulandı' : 'Bu Temayı Uygula'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isApplied ? colorScheme.secondary : colorScheme.primary,
                            foregroundColor: isApplied ? colorScheme.onSecondary : colorScheme.onPrimary,
                          ),
                          onPressed: isApplied ? null : () { // Zaten uygulanmışsa pasif
                            _applyTheme(context, previewTheme);
                          },
                        )
                      else
                        const Chip(label: Text('Premium Tema'), avatar: Icon(Icons.lock, size: 16)),

                    ],
                  ),
                ),
                // Kilit ikonu (eğer varsa, sağ üstte)
                if (isLocked)
                  Positioned( top: 8, right: 8, child: Icon(Icons.lock, color: colorScheme.onSurface.withOpacity(0.5), size: 20)),

              ],
            ),
          );
        },
      ),
    );
  }

  /// Alttaki kaydırılabilir küçük tema önizleme listesini oluşturur
  Widget _buildThumbnailList(BuildContext context) {
    return Container(
      height: 110, // Liste yüksekliği
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      // Kenarlardan hafif boşluklu başlatmak için padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableBaseThemes.length,
        // Listenin sağına ve soluna boşluk ekle
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          final theme = _availableBaseThemes[index];
          final bool isSelectedForPreview = index == _selectedPreviewIndex;
          final bool isApplied = theme.type == _currentAppliedBaseStyle; // Uygulanan tema mı?
          final bool isLocked = !theme.isFree;

          return _buildThumbnailCard(
            context: context,
            theme: theme,
            isSelected: isSelectedForPreview,
            isApplied: isApplied,
            isLocked: isLocked,
            index: index,
            onTap: (tappedIndex) {
              // Tıklanan thumbnail'i üstte göstermek için state'i güncelle
              if (mounted) {
                setState(() {
                  _selectedPreviewIndex = tappedIndex;
                });
              }
            },
          );
        },
      ),
    );
  }

  /// Alttaki listede gösterilecek tek bir küçük tema kartını oluşturur
  Widget _buildThumbnailCard({
    required BuildContext context,
    required AppThemeData theme,
    required bool isSelected, // Önizleme için seçili mi?
    required bool isApplied, // Uygulanmış tema mı?
    required bool isLocked,
    required int index,
    required ValueChanged<int> onTap,
  }) {
    return Padding(
      // Kartlar arası boşluk
      padding: const EdgeInsets.only(right: 12.0),
      child: Opacity(
        opacity: isLocked && !isApplied ? 0.7 : 1.0, // Kilitli ve uygulanmamış olanlar soluk
        child: InkWell(
          onTap: () => onTap(index), // Tıklanınca index'i bildir
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80, // Sabit genişlik
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                // Önizleme için seçili olanı veya uygulananı vurgula
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isApplied ? Theme.of(context).colorScheme.secondary : Colors.grey.withOpacity(0.3)),
                width: isSelected ? 3 : (isApplied ? 2 : 1),
              ),
              boxShadow: isSelected ? [ BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 4)] : [],
            ),
            clipBehavior: Clip.antiAlias, // Resmi kırp
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Küçük resim önizlemesi
                Image.asset(
                  theme.backgroundAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: theme.materialTheme.colorScheme.onInverseSurface),
                ),
                // Kilit ikonu (küçük)
                if (isLocked)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Icon(Icons.lock, size: 14, color: Colors.white.withOpacity(0.8), shadows: [Shadow(blurRadius: 1)]),
                  ),
                // Uygulanmışsa işaret
                if (isApplied && !isSelected) // Sadece uygulanmış ve önizlemede değilse göster
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: Icon(Icons.check_circle, size: 14, color: Colors.white.withOpacity(0.9), shadows: [Shadow(blurRadius: 1)]),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

} // _SettingsThemeScreenState sınıfının sonu