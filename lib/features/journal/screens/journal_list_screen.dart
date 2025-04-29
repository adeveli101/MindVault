// lib/features/journal/screens/journal_list_screen.dart

// ignore_for_file: unused_local_variable

// kDebugMode için
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/screens/add_edit_journal_screen.dart';
import 'package:mindvault/features/journal/widgets/empty_journal_placeholder.dart';
import 'package:mindvault/features/journal/widgets/journal_error_widget.dart';
import 'package:mindvault/features/journal/widgets/journal_list_item.dart';



import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // groupBy için

import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/journal_detail_screen.dart';

import 'package:table_calendar/table_calendar.dart';

class JournalListScreen extends StatefulWidget {
  static const String routeName = '/journal-list';
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>(); // Animasyonlu liste için

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // İlk yükleme event'i
    final currentState = context.read<JournalBloc>().state;
    if (currentState is JournalInitial) {
      context.read<JournalBloc>().add(const LoadJournalEntries());
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
      });
      // Not: Filtreleme şu anda client-side yapılıyor. Daha büyük veri setleri için
      // BLoC/Repository katmanında filtreleme yapmak daha performanslı olabilir.
      // context.read<JournalBloc>().add(FilterJournalEntries(_searchQuery));
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String entryId) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive( // Platforma uygun dialog
        title: const Text('Günlüğü Sil?'),
        content: const Text('Bu günlük girdisi kalıcı olarak silinecek. Emin misiniz?'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  String _formatGroupHeader(DateTime date) {
    // ... (Önceki kodla aynı) ...
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDay = DateTime(date.year, date.month, date.day);

    if (isSameDay(entryDay, today)) {
      return 'Bugün';
    } else if (isSameDay(entryDay, yesterday)) {
      return 'Dün';
    } else {
      return DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(date);
    }
  }

  Future<void> _refreshJournalEntries(BuildContext context) async {
    if (context.read<JournalBloc>().state is! JournalLoading) {
      _searchController.clear(); // Aramayı temizle
      context.read<JournalBloc>().add(const LoadJournalEntries());
      // RefreshIndicator'ın tamamlanması için BLoC'tan sonuç bekleyebiliriz
      // return context.read<JournalBloc>().stream.firstWhere((state) => state is! JournalLoading);
    }
  }

  void _navigateToAddEntry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditJournalScreen()),
    ).then((_) {
      // Ekleme ekranından dönüldüğünde listeyi yenilemek gerekebilir
      // _refreshJournalEntries(context); // Veya BLoC zaten hallediyorsa gerekmez
    });
  }

  void _navigateToDetailOrEdit(BuildContext context, JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JournalDetailScreen(entry: entry)),
    );
    // Alternatif: Direkt düzenlemeye git
    // Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditJournalScreen(entry: entry)));
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: const Text('Mind Vault Günlük'),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Yenile',
                  onPressed: () => _refreshJournalEntries(context),
                ),
              ],
              bottom: PreferredSize( // Arama Çubuğu
                preferredSize: const Size.fromHeight(kToolbarHeight + 10), // Ekstra padding için
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
                    child: SearchBar( // Yeni SearchBar widget'ı (Flutter 3.16+)
                      controller: _searchController,
                      hintText: "Günlüklerde ara...",
                      leading: const Icon(Icons.search),
                      trailing: _searchQuery.isNotEmpty
                          ? [IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )]
                          : null,
                      onChanged: (_) => _onSearchChanged(), // Controller listener zaten var ama burası da kullanılabilir
                      textInputAction: TextInputAction.search,
                      // Diğer SearchBar özellikleri eklenebilir
                    )
                  // TextField( ... önceki kod ... ) // Eski TextField yerine SearchBar
                ),
              ),
            ),
          ];
        },
        body: BlocConsumer<JournalBloc, JournalState>(
          listener: (context, state) {
            if (state is JournalFailure && ModalRoute.of(context)?.isCurrent == true) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text('Hata: ${state.errorMessage}'),
                  backgroundColor: theme.colorScheme.error,
                ));
            }
          },
          builder: (context, state) {
            // --- Yükleme Durumu ---
            if (state is JournalLoading && state is! JournalLoadSuccess) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            // --- Hata Durumu ---
            else if (state is JournalFailure) {
              return Center(
                child: SingleChildScrollView(
                  child: JournalErrorWidget(
                    errorMessage: state.errorMessage,
                    onRetry: () => context.read<JournalBloc>().add(const LoadJournalEntries()),
                  ),
                ),
              );
            }

            // --- Başarı Durumu ---
            else if (state is JournalLoadSuccess) {
              // Filtreleme (Client-side)
              final entriesToShow = _searchQuery.isEmpty
                  ? state.entries
                  : state.entries.where((e) =>
              e.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (e.tags?.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase())) ?? false)
              ).toList();

              if (entriesToShow.isEmpty) {
                return RefreshIndicator.adaptive( // Boşken de yenileme çalışsın
                  onRefresh: () => _refreshJournalEntries(context),
                  child: LayoutBuilder( // RefreshIndicator'ın boşken çalışması için
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: _searchQuery.isNotEmpty
                            ? const Center(child: Text("Arama sonucu bulunamadı."))
                            : const EmptyJournalPlaceholder(),
                      ),
                    ),
                  ),
                );
              }

              // Gruplama
              final groupedEntries = groupBy<JournalEntry, DateTime>(
                entriesToShow,
                    (entry) => DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day),
              );
              final sortedKeys = groupedEntries.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              // Gruplanmış Animasyonlu Liste
              return RefreshIndicator.adaptive(
                onRefresh: () => _refreshJournalEntries(context),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80.0, top: 8.0),
                  itemCount: sortedKeys.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 20, thickness: 0.5, indent: 16, endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                  itemBuilder: (context, groupIndex) {
                    final dateKey = sortedKeys[groupIndex];
                    final entriesInGroup = groupedEntries[dateKey]!;
                    entriesInGroup.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding( // Grup Başlığı
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            _formatGroupHeader(dateKey),
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ),
                        // Gruptaki Öğeler için AnimatedList veya ListView
                        ListView.builder(
                          padding: EdgeInsets.zero, // İç içe ListView için padding sıfırla
                          itemCount: entriesInGroup.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, itemIndex) {
                            final entry = entriesInGroup[itemIndex];
                            // Basit Fade Animasyonu
                            return JournalListItem(
                              key: ValueKey(entry.id),
                              entry: entry,
                              onTap: () => _navigateToDetailOrEdit(context, entry),
                              onToggleFavorite: () => context.read<JournalBloc>().add(ToggleFavoriteStatus(
                                  entryId: entry.id, currentStatus: entry.isFavorite)),
                              onDelete: () async {
                                final confirm = await _showDeleteConfirmationDialog(context, entry.id);
                                if (confirm == true && context.mounted) {
                                  context.read<JournalBloc>().add(DeleteJournalEntry(entry.id));
                                }
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            }
            // --- Diğer Durumlar ---
            else {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton( // Daha sade FAB
        onPressed: () => _navigateToAddEntry(context),
        tooltip: 'Yeni Günlük Ekle',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}