// lib/features/journal/widgets/journal_list_item_v2.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart'; // Model yolunu doğrulayın
import 'package:mindvault/theme_mindvault.dart'; // Tema yolunu doğrulayın

class JournalListItem extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;

   JournalListItem({
    super.key,
    required this.entry,
    this.onTap,
    this.onToggleFavorite,
    this.onDelete,
  });

  // Tarih formatı (örn: 29 Nis veya Salı)
  static final DateFormat _dayFormat = DateFormat('dd MMM', 'tr_TR');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'tr_TR');

  // Mood ikonları (MoodSelector'daki ile aynı olabilir veya farklı)
  final Map<Mood, IconData> _moodIcons = {
    Mood.happy: Icons.sentiment_very_satisfied_rounded,
    Mood.excited: Icons.local_fire_department_rounded,
    Mood.grateful: Icons.spa_rounded,
    Mood.calm: Icons.self_improvement_rounded,
    Mood.neutral: Icons.sentiment_neutral_rounded,
    Mood.sad: Icons.sentiment_very_dissatisfied_rounded,
    Mood.anxious: Icons.storm_rounded,
    Mood.stressed: Icons.bolt_rounded,
    Mood.tired: Icons.bedtime_rounded,
    Mood.angry: Icons.whatshot_rounded,
  };


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final Brightness brightness = theme.brightness;

    final Color moodColor = MindVaultTheme.getColorForMood(entry.mood, brightness);
    final Color onMoodColor = MindVaultTheme.getOnColorForMood(moodColor);
    final IconData moodIcon = _moodIcons[entry.mood ?? Mood.unknown] ?? Icons.circle_outlined;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          // Arka planı mood renginin hafif bir tonu yapabiliriz
          // color: moodColor.withOpacity(0.1),
          // Veya daha standart bir container rengi
            color: colorScheme.surfaceContainerHighest, // Veya surfaceContainerHigh
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Satır: Başlık/Önizleme ve Aksiyonlar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    // Başlık varsa başlığı, yoksa içeriğin ilk kısmını göster
                    entry.title?.isNotEmpty == true ? entry.title! : entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600, // Biraz daha kalın
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Aksiyon Menüsü (Favori/Sil)
                if (onToggleFavorite != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
                    tooltip: "Diğer seçenekler",
                    onSelected: (String result) {
                      if (result == 'favorite' && onToggleFavorite != null) {
                        onToggleFavorite!();
                      } else if (result == 'delete' && onDelete != null) {
                        // Silmeden önce onay istemek iyi bir pratik olabilir
                        onDelete!();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      if (onToggleFavorite != null)
                        PopupMenuItem<String>(
                          value: 'favorite',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              entry.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: entry.isFavorite ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                            title: Text(entry.isFavorite ? 'Favoriden Kaldır' : 'Favorilere Ekle'),
                          ),
                        ),
                      if (onToggleFavorite != null && onDelete != null)
                        const PopupMenuDivider(),
                      if (onDelete != null)
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                            title: Text('Sil', style: TextStyle(color: colorScheme.error)),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Alt Satır: Tarih, Saat, Mood İkonu ve Etiketler
            Row(
              children: [
                // Tarih ve Saat Alanı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer, // Hafif farklı arka plan
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6.0),
                      Text(
                        '${_dayFormat.format(entry.updatedAt)} - ${_timeFormat.format(entry.updatedAt)}',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Spacer(), // Ortadaki boşluğu doldur

                // Etiketler (varsa)
                if (entry.tags != null && entry.tags!.isNotEmpty)
                  Flexible( // Taşmayı önlemek için
                    child: Wrap(
                      spacing: 4.0,
                      runSpacing: 2.0,
                      alignment: WrapAlignment.end,
                      children: entry.tags!
                          .take(2) // Çok fazla etiket varsa sadece ilk 2'sini göster
                          .map((tag) => Chip(
                        label: Text(tag),
                        labelStyle: textTheme.labelSmall?.copyWith(color: colorScheme.secondary),
                        backgroundColor: colorScheme.secondaryContainer.withOpacity(0.4),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                      ))
                          .toList(),
                    ),
                  ),

                const SizedBox(width: 8), // Etiketlerle mood ikonu arası boşluk

                // Mood İkonu (renkli)
                if (entry.mood != null && entry.mood != Mood.unknown)
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(brightness == Brightness.light ? 0.8 : 0.6), // Rengi biraz yumuşat
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      moodIcon,
                      size: 18,
                      color: onMoodColor,
                    ),
                  ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}