// lib/features/journal/widgets/mood_selector_widget.dart (Yeni Tema Sistemiyle Uyumlu)

import 'package:flutter/material.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı ve yolu kontrol edin. ***
import 'package:mindvault/features/journal/model/journal_entry.dart'; // Model import
// Eski özel tema importları kaldırıldı.
// ***------------------------------------------------------------***

/// Kullanıcının bir ruh hali seçmesini sağlayan, tek butonla açılıp kapanan, dikey widget.
class MoodSelectorWidget extends StatefulWidget {
  final Mood? initialMood;
  final ValueChanged<Mood?> onMoodSelected;
  final Duration animationDuration;
  final double itemSize;
  final double iconSize;
  final double borderRadius;
  final double verticalSpacing;
  final IconData defaultIcon;

  const MoodSelectorWidget({
    super.key,
    this.initialMood,
    required this.onMoodSelected,
    this.animationDuration = const Duration(milliseconds: 250),
    this.itemSize = 42.0,
    this.iconSize = 24.0,
    this.borderRadius = 8.0,
    this.verticalSpacing = 8.0,
    this.defaultIcon = Icons.add_reaction_outlined,
  });

  @override
  State<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends State<MoodSelectorWidget> {
  Mood? _selectedMood;
  bool _isExpanded = false;

  // Mood ikonları (Modelde veya burada tanımlı olabilir)
  final Map<Mood, IconData> _moodIcons = {
    Mood.happy: Icons.sentiment_very_satisfied_rounded,
    Mood.excited: Icons.celebration_rounded,
    Mood.grateful: Icons.volunteer_activism_rounded,
    Mood.calm: Icons.self_improvement_rounded,
    Mood.neutral: Icons.sentiment_neutral_rounded,
    Mood.sad: Icons.sentiment_very_dissatisfied_rounded,
    Mood.anxious: Icons.sentiment_very_dissatisfied, // Example - customize
    Mood.stressed: Icons.whatshot_rounded,
    Mood.tired: Icons.battery_alert_rounded,
    Mood.angry: Icons.sentiment_dissatisfied_rounded,
    Mood.unknown: Icons.help_outline_rounded,
  };

  // Tooltip için mood isimleri
  String _getMoodName(Mood mood) {
    // Bu fonksiyon aynı kalabilir
    switch (mood) {
      case Mood.happy: return "Mutlu";
      case Mood.excited: return "Heyecanlı";
      case Mood.grateful: return "Minnettar";
      case Mood.calm: return "Sakin";
      case Mood.neutral: return "Nötr";
      case Mood.sad: return "Üzgün";
      case Mood.anxious: return "Endişeli";
      case Mood.stressed: return "Stresli";
      case Mood.tired: return "Yorgun";
      case Mood.angry: return "Kızgın";
      case Mood.unknown: return "Bilinmiyor";
    }
  }

  // Gösterilecek mood listesi
  late List<Mood> _allDisplayMoods;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
    // Unknown hariç tüm mood'ları listele
    _allDisplayMoods = Mood.values.where((m) => m != Mood.unknown).toList();
  }

  @override
  void didUpdateWidget(covariant MoodSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan gelen initialMood değişirse state'i güncelle
    if (widget.initialMood != oldWidget.initialMood) {
      if (mounted) {
        setState(() {
          _selectedMood = widget.initialMood;
        });
      }
    }
  }

  // --- Yeni Tema Entegrasyonu ---

  /// Verilen Mood için tema renk şemasından uygun bir renk döndürür.
  Color _getColorForMood(Mood mood, ColorScheme colorScheme) {
    // Tema renklerini kullanarak mood'lara renk ata
    // Bu eşleştirmeyi kendi isteğinize göre ayarlayabilirsiniz
    switch (mood) {
      case Mood.happy:
        return Colors.amber.shade600; // Veya colorScheme.tertiary?
      case Mood.excited:
        return Colors.orange.shade600;
      case Mood.grateful:
        return Colors.pink.shade300;
      case Mood.calm:
        return colorScheme.secondary; // Temanın ikincil rengi
      case Mood.neutral:
        return colorScheme.onSurfaceVariant; // Temanın varyant rengi (genellikle gri)
      case Mood.sad:
        return Colors.blue.shade600; // Veya colorScheme.secondary?
      case Mood.anxious:
        return Colors.purple.shade300;
      case Mood.stressed:
        return colorScheme.error; // Temanın hata rengi
      case Mood.tired:
        return Colors.brown.shade400;
      case Mood.angry:
        return colorScheme.errorContainer; // Hata konteyner rengi (daha koyu/açık olabilir)
      case Mood.unknown:
        return colorScheme.outline; // Kenarlık rengi (genellikle gri)
    }
  }

  /// Verilen arka plan rengi üzerine okunabilir bir ikon/metin rengi döndürür.
  Color _getOnColorForMood(Color moodColor, BuildContext context) {
    // Mevcut tema parlaklığını al
    // Arka plan renginin parlaklığını tahmin et
    final Brightness colorBrightness = ThemeData.estimateBrightnessForColor(moodColor);

    // Eğer renk parlaklığı tema parlaklığı ile aynıysa (örn. açık tema, açık mood rengi),
    // kontrast için ters parlaklıkta bir renk kullan. Genellikle onPrimary veya onSecondary işe yarar.
    // Eğer farklıysa (örn. açık tema, koyu mood rengi), tema yüzeyindeki renk kullanılabilir.
    // Basit bir yaklaşım:
    return colorBrightness == Brightness.dark ? Colors.white : Colors.black;
    // Veya daha tematik:
    // return colorBrightness == themeBrightness
    //   ? (themeBrightness == Brightness.dark ? Colors.black : Colors.white) // Kontrast renk
    //   : Theme.of(context).colorScheme.onSurface; // Yüzeydeki renk
  }

  // --- Widget Oluşturma Metodları ---

  /// Açılır listedeki tek bir mood butonu oluşturur.
  Widget _buildMoodListItem(Mood mood, ThemeData theme) {
    final colorScheme = theme.colorScheme; // Kolay erişim için
    final Color moodColor = _getColorForMood(mood, colorScheme);
    // Hafif bir arka plan ve mood renginde ikon
    final Color bgColor = moodColor.withOpacity(0.15);
    final Color iconColor = moodColor;
    final IconData iconData = _moodIcons[mood] ?? Icons.sentiment_neutral_rounded;
    final String moodName = _getMoodName(mood);

    return Tooltip(
      message: moodName,
      preferBelow: true,
      child: InkWell(
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedMood = mood;
              _isExpanded = false; // Seçince listeyi kapat
            });
          }
          widget.onMoodSelected(_selectedMood); // Seçimi bildir
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: widget.itemSize,
          height: widget.itemSize,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Center(
            child: Icon(
              iconData,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Ana butonu (seçili/varsayılan ikonu gösteren ve listeyi açıp kapatan) oluşturur.
  Widget _buildMainButton(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedMood != null;

    // Gösterilecek ikon ve renkleri belirle
    final IconData currentIcon;
    final Color buttonBgColor;
    final Color iconFgColor;
    final Color borderColor;
    final String tooltipText;

    if (isSelected) {
      currentIcon = _moodIcons[_selectedMood!] ?? widget.defaultIcon;
      buttonBgColor = _getColorForMood(_selectedMood!, colorScheme); // Seçili mood rengi
      iconFgColor = _getOnColorForMood(buttonBgColor, context); // Üzerindeki ikon rengi
      borderColor = buttonBgColor.withOpacity(0.8); // Sınır için hafif opak renk
      tooltipText = _getMoodName(_selectedMood!);
    } else {
      currentIcon = widget.defaultIcon; // Varsayılan ikon
      buttonBgColor = Colors.transparent; // Seçili değilse arka plan yok
      iconFgColor = colorScheme.onSurfaceVariant; // Seçili değilse ikincil ikon rengi
      borderColor = colorScheme.outline.withOpacity(0.7); // Kenarlık için outline rengi
      tooltipText = "Ruh Hali Seç";
    }

    return Tooltip(
      message: tooltipText,
      preferBelow: true,
      child: InkWell(
        onTap: () {
          if (mounted) {
            setState(() {
              _isExpanded = !_isExpanded; // Genişleme durumunu değiştir
            });
          }
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedContainer( // Renk geçişini anime et
          duration: widget.animationDuration,
          width: widget.itemSize,
          height: widget.itemSize,
          decoration: BoxDecoration(
            color: buttonBgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            // Seçiliyken hafif gölge
            boxShadow: isSelected
                ? [ BoxShadow( color: buttonBgColor.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1)) ]
                : [],
          ),
          child: Center(
            child: Icon(
              currentIcon,
              size: widget.iconSize,
              color: iconFgColor,
            ),
          ),
        ),
      ),
    );
  }

  // --- Ana Build Metodu ---
  @override
  Widget build(BuildContext context) {
    // Mevcut temayı al
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Ana Buton
        _buildMainButton(theme),

        // 2. Açılır Liste (Animasyonlu)
        AnimatedSize(
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: widget.animationDuration * 0.6,
            opacity: _isExpanded ? 1.0 : 0.0,
            // Expanded durumunda listeyi göster, değilse sıfır yükseklikli container
            child: _isExpanded
                ? Padding(
              padding: EdgeInsets.only(top: widget.verticalSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _allDisplayMoods.map((mood) {
                  // Her mood için liste elemanı oluştur
                  final bool isFirst = _allDisplayMoods.first == mood;
                  return Padding(
                    padding: EdgeInsets.only(
                        top: isFirst ? 0 : widget.verticalSpacing),
                    child: _buildMoodListItem(mood, theme),
                  );
                }).toList(),
              ),
            )
                : const SizedBox.shrink(), // Kapalıyken yer kaplamaz
          ),
        ),
      ],
    );
  }
}