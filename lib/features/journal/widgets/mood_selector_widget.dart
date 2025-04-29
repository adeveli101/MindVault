// lib/features/journal/widgets/mood_selector_widget.dart (YENİDEN YAZILDI - Tek Butonlu Açılır Kapanır)

import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart'; // Model import
// Tema fonksiyonları için import (Yolu doğrulayın!)
import 'package:mindvault/theme_mindvault.dart';

/// Kullanıcının bir ruh hali seçmesini sağlayan, tek butonla açılıp kapanan, dikey widget.
class MoodSelectorWidget extends StatefulWidget {
  final Mood? initialMood;
  final ValueChanged<Mood?> onMoodSelected;
  final Duration animationDuration;
  final double itemSize; // Butonların boyutu
  final double iconSize; // İkon boyutu
  final double borderRadius; // Köşe yuvarlaklığı
  final double verticalSpacing; // Açılan listedeki ikonlar arası boşluk
  final IconData defaultIcon; // Seçim yokken gösterilecek ikon

  const MoodSelectorWidget({
    super.key,
    this.initialMood,
    required this.onMoodSelected,
    this.animationDuration = const Duration(milliseconds: 250),
    this.itemSize = 42.0,
    this.iconSize = 24.0,
    this.borderRadius = 8.0,
    this.verticalSpacing = 8.0,
    this.defaultIcon = Icons.add_reaction_outlined, // Varsayılan ikon
  });

  @override
  State<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends State<MoodSelectorWidget> {
  Mood? _selectedMood;
  bool _isExpanded = false; // Listenin açık/kapalı durumu

  // Mood ikonları (Aynı)
  final Map<Mood, IconData> _moodIcons = {
    Mood.happy: Icons.sentiment_very_satisfied_rounded,
    Mood.excited: Icons.celebration_rounded,
    Mood.grateful: Icons.volunteer_activism_rounded,
    Mood.calm: Icons.self_improvement_rounded,
    Mood.neutral: Icons.sentiment_neutral_rounded,
    Mood.sad: Icons.sentiment_very_dissatisfied_rounded,
    Mood.anxious: Icons.priority_high_rounded,
    Mood.stressed: Icons.whatshot_rounded,
    Mood.tired: Icons.battery_alert_rounded,
    Mood.angry: Icons.sentiment_dissatisfied_rounded,
  };

  // Tooltip için mood isimleri (Aynı)
  String _getMoodName(Mood mood) {
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

  // Tüm gösterilebilir mood'lar
  late List<Mood> _allDisplayMoods;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
    _allDisplayMoods = Mood.values.where((m) => m != Mood.unknown).toList();
  }

  // initialMood dışarıdan değişirse state'i güncelle
  @override
  void didUpdateWidget(covariant MoodSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMood != oldWidget.initialMood) {
      setState(() {
        _selectedMood = widget.initialMood;
      });
    }
  }

  // Tek bir mood butonu (açılır liste için)
  Widget _buildMoodListItem(Mood mood, ThemeData theme, Brightness brightness) {
// Ana butonda bu mood seçili mi?
    final Color moodColor = MindVaultTheme.getColorForMood(mood, brightness);
    // Açık listede seçili olanı farklı göstermeye gerek yok, ana buton gösteriyor.
    // İsterseniz hafif bir border veya farklı opacity eklenebilir.
    final Color bgColor = moodColor.withOpacity(0.15);
    final Color iconColor = moodColor;
    final IconData iconData = _moodIcons[mood] ?? Icons.sentiment_neutral_rounded;
    final String moodName = _getMoodName(mood);

    return Tooltip(
      message: moodName,
      preferBelow: true, // Tooltip'i altta gösterelim
      child: InkWell(
        onTap: () {
          setState(() {
            // Yeni mood'u seç, listeyi kapat
            _selectedMood = mood;
            _isExpanded = false;
          });
          widget.onMoodSelected(_selectedMood);
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container( // Padding yerine Container ile boyut ve merkezleme
          width: widget.itemSize,
          height: widget.itemSize,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            // Border ekleyebiliriz (isteğe bağlı)
            // border: Border.all(color: moodColor.withOpacity(0.5), width: 1),
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

  // Ana butonu (seçili/varsayılan ikonu gösteren ve açıp kapatan) oluşturan fonksiyon
  Widget _buildMainButton(ThemeData theme, Brightness brightness) {
    final bool isSelected = _selectedMood != null;
    final Mood currentDisplayMood = _selectedMood ?? Mood.neutral; // Renk ve ikon için (neutral varsayılan)
    final IconData currentIcon = isSelected
        ? (_moodIcons[_selectedMood!] ?? widget.defaultIcon)
        : widget.defaultIcon;
    final Color moodColor = isSelected
        ? MindVaultTheme.getColorForMood(currentDisplayMood, brightness)
        : theme.colorScheme.onSurface.withOpacity(0.3); // Seçili değilse nötr renk
    final Color onMoodColor = isSelected
        ? MindVaultTheme.getOnColorForMood(moodColor)
        : theme.colorScheme.onSurface; // Seçili değilse normal ikon rengi

    return Tooltip(
      message: isSelected ? _getMoodName(_selectedMood!) : "Ruh Hali Seç",
      preferBelow: true,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded; // Genişleme durumunu tersine çevir
          });
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedContainer(
          duration: widget.animationDuration,
          width: widget.itemSize,
          height: widget.itemSize,
          decoration: BoxDecoration(
            color: isSelected ? moodColor : Colors.transparent, // Seçili değilse transparan
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isSelected ? moodColor.withOpacity(0.8) : moodColor, // Seçili değilse de border olsun
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: moodColor.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1),
              )
            ] : [],
          ),
          child: Center(
            child: Icon(
              currentIcon,
              size: widget.iconSize,
              color: onMoodColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Ana Buton (Her zaman görünür)
        _buildMainButton(theme, brightness),

        // 2. Açılır Liste (Animasyonlu)
        AnimatedSize( // Yükseklik değişimini anime eder
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          child: AnimatedOpacity( // Görünürlük değişimini anime eder
            duration: widget.animationDuration * 0.6, // Opacity daha hızlı değişsin
            opacity: _isExpanded ? 1.0 : 0.0,
            child: _isExpanded
                ? Padding( // Liste ile ana buton arasına boşluk
              padding: EdgeInsets.only(top: widget.verticalSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _allDisplayMoods
                // Açılır listede o an seçili olanı göstermeyelim (isteğe bağlı)
                // .where((mood) => mood != _selectedMood)
                    .map((mood) {
                  final bool isFirst = _allDisplayMoods.first == mood; // Veya _allDisplayMoods.where(...).first
                  return Padding(
                    padding: EdgeInsets.only(top: isFirst ? 0 : widget.verticalSpacing),
                    child: _buildMoodListItem(mood, theme, brightness),
                  );
                }).toList(),
              ),
            )
                : Container(height: 0), // Kapalıyken yer kaplamasın
          ),
        ),
      ],
    );
  }
}