// lib/features/journal/screens/journal_detail_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/add_edit_journal_screen.dart';
import 'package:mindvault/theme_mindvault.dart';


class JournalDetailScreen extends StatelessWidget {
  /// Rota adı (Statik yönlendirme için opsiyonel)
  static const String routeName = '/journal-detail';

  /// Gösterilecek olan günlük girdisi.
  /// Bu genellikle önceki ekrandan (JournalListScreen) argüman olarak gönderilir.
  final JournalEntry entry;

  const JournalDetailScreen({
    super.key,
    required this.entry,
  });

  // Tarih formatlayıcı
  static final DateFormat _dateTimeFormat = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');

  /// Silme onayı dialog'u (JournalListScreen'deki ile benzer)
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    if (kDebugMode) {
      print("Showing delete confirmation dialog for entry: ${entry.id}");
    }
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Günlüğü Sil?'),
        content: const Text('Bu günlük girdisi kalıcı olarak silinecek. Emin misiniz?'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
        shape: Theme.of(context).dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final Brightness brightness = theme.brightness;

    // Mood'a göre renkler
    final Color moodColor = MindVaultTheme.getColorForMood(entry.mood, brightness);
    final Color onMoodColor = MindVaultTheme.getOnColorForMood(moodColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _dateTimeFormat.format(entry.createdAt), // Başlıkta oluşturma tarihi
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16), // Biraz daha küçük font
        ),
        // AppBar arka planını mood rengine göre ayarla (isteğe bağlı)
        backgroundColor: moodColor.withOpacity(0.8),
        foregroundColor: onMoodColor, // İkon ve metin rengini mood rengine uygun yap
        elevation: 1,
        actions: [
          // Favori durumunu gösterme/değiştirme butonu
          IconButton(
            icon: Icon(
              entry.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: entry.isFavorite ? colorScheme.primary : onMoodColor.withOpacity(0.7),
            ),
            tooltip: entry.isFavorite ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
            onPressed: () {
              if (kDebugMode) {
                print('Toggling favorite from detail screen for entry: ${entry.id}');
              }
              context.read<JournalBloc>().add(ToggleFavoriteStatus(
                entryId: entry.id,
                currentStatus: entry.isFavorite,
              ));
              // Not: Bu event sonrası BLoC listeyi güncelleyecek. Detay ekranındaki
              // entry'nin state'i otomatik güncellenmeyebilir. Ya BLoC'tan güncel
              // entry'yi dinlemek ya da pop sonrası listenin yenilenmesine güvenmek gerekir.
              // Şimdilik basit tutuyoruz.
            },
          ),
          // Düzenleme butonu
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: onMoodColor.withOpacity(0.9)),
            tooltip: 'Düzenle',
            onPressed: () {
              if (kDebugMode) {
                print('Navigating to AddEditJournalScreen for editing entry: ${entry.id}');
              }
              Navigator.pushReplacement( // Detay ekranını kapatıp düzenlemeye git
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditJournalScreen(),
                ),
              );
            },
          ),
          // Silme butonu
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: onMoodColor.withOpacity(0.9)),
            tooltip: 'Sil',
            onPressed: () async {
              final confirmDelete = await _showDeleteConfirmationDialog(context);
              if (confirmDelete == true && context.mounted) { // context hala geçerli mi kontrolü
                if (kDebugMode) {
                  print('Delete confirmed from detail screen for entry: ${entry.id}. Sending DeleteJournalEntry event.');
                }
                context.read<JournalBloc>().add(DeleteJournalEntry(entry.id));
                // Silme işlemi sonrası bu ekrandan geri git
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Uzun içerikler için kaydırma
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood, Tarihler, Etiketler gibi meta veriler
            _buildMetadataSection(context, colorScheme, textTheme, moodColor, onMoodColor),
            const SizedBox(height: 20.0),
            Divider(color: colorScheme.outlineVariant.withOpacity(0.5)),
            const SizedBox(height: 20.0),

            // Günlük İçeriği
            // İçeriği seçilebilir yapmak için SelectableText kullanabiliriz
            SelectableText(
              entry.content,
              style: textTheme.bodyLarge?.copyWith(height: 1.6), // Okunabilirlik için satır aralığı
            ),
            const SizedBox(height: 40.0), // Altta boşluk
          ],
        ),
      ),
    );
  }

  /// Meta verileri (Mood, Tarih, Etiketler) gösteren bölümü oluşturan yardımcı metot.
  Widget _buildMetadataSection(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, Color moodColor, Color onMoodColor) {
    return Wrap( // Farklı meta verileri yan yana veya alt alta sığdırır
      spacing: 16.0, // Yatay boşluk
      runSpacing: 12.0, // Dikey boşluk
      children: [
        // Mood Göstergesi
        if (entry.mood != null && entry.mood != Mood.unknown)
          Chip(
            avatar: Icon(Icons.sentiment_satisfied, size: 18, color: onMoodColor),
            label: Text(entry.mood!.name[0].toUpperCase() + entry.mood!.name.substring(1)),
            labelStyle: textTheme.bodyMedium?.copyWith(color: onMoodColor),
            backgroundColor: moodColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),

        // Oluşturma/Güncelleme Tarihi
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oluşturuldu: ${_dateTimeFormat.format(entry.createdAt)}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (entry.updatedAt != entry.createdAt) // Sadece farklıysa güncelleme tarihini göster
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Güncellendi: ${_dateTimeFormat.format(entry.updatedAt)}',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
                ),
              ),
          ],
        ),

        // Etiketler
        if (entry.tags != null && entry.tags!.isNotEmpty)
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: entry.tags!.map((tag) => Chip(
              label: Text(tag),
              labelStyle: textTheme.labelSmall?.copyWith(color: colorScheme.secondary),
              backgroundColor: colorScheme.secondaryContainer.withOpacity(0.6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              side: BorderSide.none,
            )).toList(),
          ),
      ],
    );
  }
}