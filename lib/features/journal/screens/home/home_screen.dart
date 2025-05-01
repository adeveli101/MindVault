// lib/features/journal/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
// *** TUTARLI IMPORT KULLANIN! Paket adınızı ve yolları kontrol edin. ***
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/home/settings_theme_screen.dart';
import 'package:mindvault/features/journal/screens/page_screens/add_edit_journal_screen.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında günlükleri yükle
    // Eğer Bloc zaten başlangıçta yükleniyorsa bu satır gereksiz olabilir.
    context.read<JournalBloc>().add(const LoadJournalEntries());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, theme),
        floatingActionButton: _buildFab(context, colorScheme),
        body: _buildBody(context),
      ),
    );
  }

  // --- AppBar Oluşturucu ---
  AppBar _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Günlüğüm', // Veya Uygulama Adı
        style: theme.textTheme.titleLarge, // Temadan stil alır
      ),
      centerTitle: true,
      actions: [
        // Yenile Butonu (İsteğe Bağlı)
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.secondary),
          tooltip: 'Yenile',
          onPressed: () =>
              context.read<JournalBloc>().add(const LoadJournalEntries()),
        ),
        // Ayarlar Butonu
        IconButton(
          icon: Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
          tooltip: 'Ayarlar',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsThemeScreen()),
            );
          },
        ),
      ],
    );
  }

  // --- Floating Action Button Oluşturucu ---
  Widget _buildFab(BuildContext context, ColorScheme colorScheme) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditJournalScreen()),
        );
      },
      tooltip: 'Yeni Günlük Girişi',
      // Temanın FAB temasını veya ElevatedButton temasını kullanabilir
      child: const Icon(Icons.add_rounded),
    );
  }

  // --- Body Oluşturucu (BlocBuilder ile) ---
  Widget _buildBody(BuildContext context) {
    return BlocConsumer<JournalBloc, JournalState>(
      // listener ile işlem başarı/hata mesajları gösterilebilir (isteğe bağlı)
      listener: (context, state) {
        if (state is JournalFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Hata: ${state.errorMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
        // İsteğe bağlı: Başarı mesajları
        // if (state is JournalOperationSuccess) { ... }
      },
      // builder ile UI'ı state'e göre oluştur
      builder: (context, state) {
        // --- Yükleniyor Durumu ---
        if (state is JournalInitial || state is JournalLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        // --- Yüklendi Durumu ---
        else if (state is JournalLoadSuccess) {
          final entries = state.entries;
          // Liste Boşsa
          if (entries.isEmpty) {
            return _buildEmptyState(context);
          }
          // Liste Doluysa
          else {
            return _buildEntryList(context, entries);
          }
        }
        // --- Hata Durumu (listener zaten gösteriyor ama burada da gösterilebilir) ---
        else if (state is JournalFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Günlükler yüklenemedi.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage, // Daha detaylı hata mesajı
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Tekrar Dene'),
                    onPressed: () => context.read<JournalBloc>().add(const LoadJournalEntries()),
                  )
                ],
              ),
            ),
          );
        }
        // --- Diğer Tanımsız Durumlar ---
        else {
          return const Center(child: Text('Bilinmeyen bir durum oluştu.'));
        }
      },
    );
  }

  /// Liste boş olduğunda gösterilecek widget'ı oluşturur.
  Widget _buildEmptyState(BuildContext context) {
    // ... (Önceki yanıttaki _buildEmptyState kodu buraya gelecek) ...
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon( Icons.auto_stories_outlined, size: 60, color: theme.colorScheme.primary.withOpacity(0.7), ),
            const SizedBox(height: 16),
            Text( 'Henüz günlük girişi yok.', style: theme.textTheme.headlineSmall?.copyWith( color: theme.colorScheme.onSurface.withOpacity(0.8), ), textAlign: TextAlign.center,),
            const SizedBox(height: 8),
            Text( 'Hadi ilk düşüncelerini kaydetmeye başla!', style: theme.textTheme.bodyLarge?.copyWith( color: theme.colorScheme.onSurface.withOpacity(0.6), ), textAlign: TextAlign.center,),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Günlük girişlerinin listesini oluşturan widget.
  Widget _buildEntryList(BuildContext context, List<JournalEntry> entries) {
    final sortedEntries = List<JournalEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 80.0), // FAB için altta boşluk
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        // Silme işlemi için Dismissible ile saralım
        return Dismissible(
          key: Key(entry.id), // Her eleman için benzersiz key
          direction: DismissDirection.endToStart, // Sadece sağdan sola kaydırma
          onDismissed: (direction) {
            // Kaydırılınca silme olayını BLoC'a gönder
            context.read<JournalBloc>().add(DeleteJournalEntry(entry.id));
            // Anlık geri bildirim için SnackBar
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('${entry.title ?? 'Başlıksız Giriş'} silindi.'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                // Geri alma butonu (isteğe bağlı - BLoC'da desteklenmeli)
                // action: SnackBarAction(label: 'Geri Al', onPressed: () => ...),
              ));
          },
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.delete_sweep_outlined,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          child: _buildEntryListItem(context, entry), // Asıl liste elemanı
        );
      },
    );
  }

  /// Tek bir günlük girişi liste elemanını oluşturan widget (Favori/Silme eklendi).
  Widget _buildEntryListItem(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String previewContent = entry.content.split('\n').first;
    if (previewContent.length > 100) {
      previewContent = '${previewContent.substring(0, 100)}...';
    }
    // Başlık yoksa içeriğin bir kısmını başlık gibi kullan
    final displayTitle = entry.title?.isNotEmpty ?? false ? entry.title! : previewContent;
    final displayContent = entry.title?.isNotEmpty ?? false ? previewContent : ""; // Başlık varsa içeriği göster

    return Card(
      // margin: theme.cardTheme.margin ?? const EdgeInsets.symmetric(vertical: 6.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0), // Biraz daha az dikey boşluk
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddEditJournalScreen(existingEntry: entry)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row( // Ana düzen Row olarak değiştirildi
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol Taraf: Mood ve Favori
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(), // Buton boyutunu küçült
                    tooltip: entry.isFavorite ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
                    icon: Icon(
                      entry.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: entry.isFavorite ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    onPressed: () {
                      // Favori durumunu değiştirme olayını gönder
                      context.read<JournalBloc>().add(ToggleFavoriteStatus(
                          entryId: entry.id, currentStatus: entry.isFavorite));
                    },
                  ),
                ],
              ),
              const SizedBox(width: 12), // İkonlarla metin arası boşluk

              // Sağ Taraf: Metin İçeriği
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarih
                    Text(
                      DateFormat('dd MMMM, yyyy', 'tr_TR').format(entry.createdAt), // Saat kaldırıldı
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Başlık (varsa)
                    Text(
                      displayTitle,
                      style: textTheme.titleMedium?.copyWith( // Başlık için stil
                        fontWeight: FontWeight.w600, // Biraz daha kalın
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1, // Başlık tek satır
                      overflow: TextOverflow.ellipsis,
                    ),
                    // İçerik Önizlemesi (Başlık varsa göster)
                    if (displayContent.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        displayContent,
                        style: textTheme.bodyMedium?.copyWith( // bodyLarge yerine bodyMedium
                          color: colorScheme.onSurface.withOpacity(0.75),
                          height: 1.4, // Satır aralığı
                        ),
                        maxLines: 2, // İçerik önizleme satır sayısı
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}