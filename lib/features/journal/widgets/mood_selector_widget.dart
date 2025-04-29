// lib/features/journal/widgets/mood_selector_widget.dart

import 'package:flutter/material.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/theme_mindvault.dart';



/// Kullanıcının bir ruh hali seçmesini sağlayan widget.
class MoodSelectorWidget extends StatefulWidget {
  /// Başlangıçta seçili olan ruh hali (opsiyonel).
  final Mood? initialMood;
  /// Bir ruh hali seçildiğinde veya seçim kaldırıldığında çağrılır.
  final ValueChanged<Mood?> onMoodSelected;

  const MoodSelectorWidget({
    super.key,
    this.initialMood,
    required this.onMoodSelected,
  });

  @override
  State<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends State<MoodSelectorWidget> {
  // Seçili olan ruh halini takip etmek için state değişkeni
  Mood? _selectedMood;

  // Mood enum'larını ikonlarla eşleştirelim (Örnek ikonlar)
  final Map<Mood, IconData> _moodIcons = {
    Mood.happy: Icons.sentiment_very_satisfied_rounded,
    Mood.excited: Icons.celebration_rounded,
    Mood.grateful: Icons.volunteer_activism_rounded,
    Mood.calm: Icons.self_improvement_rounded, // Veya spa
    Mood.neutral: Icons.sentiment_neutral_rounded,
    Mood.sad: Icons.sentiment_very_dissatisfied_rounded,
    Mood.anxious: Icons.priority_high_rounded,// Flutter 3.19+
    Mood.stressed: Icons.whatshot_rounded, // Veya bolt
    Mood.tired: Icons.battery_alert_rounded, // Veya nights_stay
    Mood.angry: Icons.sentiment_dissatisfied_rounded, // Veya local_fire_department
    // Mood.unknown için ikon tanımlamaya gerek yok, onu göstermeyeceğiz.
  };


  @override
  void initState() {
    super.initState();
    // Başlangıç değerini state'e ata
    _selectedMood = widget.initialMood;
  }

  // Başlangıç değeri değiştiğinde state'i güncelle (düzenleme ekranları için önemli)
  @override
  void didUpdateWidget(covariant MoodSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMood != oldWidget.initialMood) {
      setState(() {
        _selectedMood = widget.initialMood;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    // Gösterilecek mood listesi (unknown hariç)
    final List<Mood> displayMoods = Mood.values.where((m) => m != Mood.unknown).toList();

    return Wrap( // Öğelerin otomatik olarak alt satıra kaymasını sağlar
      spacing: 8.0, // Yatay boşluk
      runSpacing: 8.0, // Dikey boşluk
      alignment: WrapAlignment.center, // Ortala
      children: displayMoods.map((mood) {
        final bool isSelected = _selectedMood == mood;
        final Color moodColor = MindVaultTheme.getColorForMood(mood, brightness);
        final Color onMoodColor = MindVaultTheme.getOnColorForMood(moodColor);
        final IconData iconData = _moodIcons[mood] ?? Icons.sentiment_neutral_rounded; // Eşleşmeyen ikon için varsayılan

        return InkWell(
          onTap: () {
            setState(() {
              // Eğer zaten seçili olana tıklanırsa seçimi kaldır, değilse yenisini seç.
              if (isSelected) {
                _selectedMood = null;
              } else {
                _selectedMood = mood;
              }
            });
            // Callback fonksiyonunu çağırarak seçimi dışarıya bildir.
            widget.onMoodSelected(_selectedMood);
          },
          borderRadius: BorderRadius.circular(20.0), // Tıklama efekti için yuvarlak köşe
          child: AnimatedContainer( // Seçim değişikliğinde animasyonlu geçiş
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isSelected ? moodColor : moodColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: isSelected ? moodColor : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: moodColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ] : [],
            ),
            child: Column( // İkon ve metni dikey hizala
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 28,
                  color: isSelected ? onMoodColor : moodColor,
                ),
                const SizedBox(height: 4),
                Text(
                  mood.name[0].toUpperCase() + mood.name.substring(1), // Enum ismini baş harfi büyük yap
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? onMoodColor : theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}