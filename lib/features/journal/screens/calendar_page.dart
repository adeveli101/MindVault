// lib/features/journal/screens/calendar_page.dart
// Son Revizyon: Genişleyen/kapanan arama iyileştirmeleri, tek tek filtre kaldırma, hatalar düzeltildi.

// ignore_for_file: use_build_context_synchronously, unused_element

// ==========================================================================
// !!! ÖNEMLİ NOT: Klavye Açıldığında Alt Navigasyonun Yükselmesini Önleme !!!
// Ana Scaffold widget'ında (muhtemelen main_screen.dart)
// `resizeToAvoidBottomInset: false` ayarını yapın.
// ==========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart'; // setEquals için
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindvault/features/journal/screens/widgets/filter_sheet.dart';
import 'package:table_calendar/table_calendar.dart';

// Proje importları
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/page_screens/add_edit_journal_screen.dart';

// Sabitler
const double kBottomNavHeight = 65.0;
const double kBottomNavBottomMargin = 32.0;

class CalendarPage extends StatefulWidget {
  final TabController tabController;
  const CalendarPage({ super.key, required this.tabController });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Takvim State'leri
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<JournalEntry> _lastLoadedEntriesForFallback = [];

  // Arama & Filtre State'leri
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  String _currentSearchQueryForDebounce = ''; // Sadece debounce için
  List<Mood>? _selectedMoodFilters; // UI state'i için (Bloc'tan senkronize edilir)
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // İlk yükleme ve state senkronizasyonu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = context.read<JournalBloc>().state;
      if (currentState is JournalInitial || currentState is JournalFailure) {
        context.read<JournalBloc>().add(const LoadJournalEntries());
      } else if (currentState is JournalLoadSuccess) {
        _lastLoadedEntriesForFallback = currentState.entries;
        _syncFiltersFromState(currentState);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Arama ve Filtreleme Mantığı ---

  /// Arama alanı odak kazandığında veya kaybettiğinde UI durumunu ayarlar.
  void _onSearchFocusChanged() {
    if (!mounted) return; // Önce mounted kontrolü

    // Odak kaybedildiğinde VE metin alanı boşsa arama çubuğunu daralt
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty && _isSearchExpanded) {
      setState(() {
        _isSearchExpanded = false;
      });
    }
    // Odak kazanıldığında genişlet (eğer zaten geniş değilse)
    else if (_searchFocusNode.hasFocus && !_isSearchExpanded) {
      setState(() {
        _isSearchExpanded = true;
      });
    }
    // Diğer durumlarda (odak kaybedildi ama metin dolu vb.) genişleme durumu değişmez.
  }

  /// Arama TextField'ı değiştiğinde BLoC olayını tetikler (debounce ile).
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (_currentSearchQueryForDebounce != query) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) {
          _currentSearchQueryForDebounce = query; // Debounce için güncelle
          context.read<JournalBloc>().add(FilterJournalEntriesByCriteria(
              query: query,
              moods: _selectedMoodFilters // UI state'inden güncel mood'ları al
          ));
        }
      });
    }
  }

  /// Filtreleme alt sayfasını açar ve sonucu işler.
  void _openFilterSheet() async {
    if (!mounted) return;
    // Mevcut filtreleri UI state'inden al
    final currentFilters = _selectedMoodFilters;

    // Odağı kaldırarak klavyeyi kapat (varsa)
    FocusScope.of(context).unfocus();
    // Aramayı daralt (boşsa)
    _dismissSearchIfApplicable(forceCollapse: true);

    final Set<Mood>? selectedMoodsSet = await showModalBottomSheet<Set<Mood>>(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (_) => FilterSheet(initialSelectedMoods: currentFilters),
    );

    if (!mounted) return;

    if (selectedMoodsSet != null) {
      final newMoodFilters = selectedMoodsSet.isNotEmpty ? selectedMoodsSet.toList() : null;
      // BLoC'u tetikle (UI state'i listener ile güncellenecek)
      context.read<JournalBloc>().add(FilterJournalEntriesByCriteria(
          query: _searchController.text.trim(),
          moods: newMoodFilters
      ));
    }
  }

  /// Sadece metin filtresini kaldırır.
  void _removeTextFilter() {
    if (!mounted) return;
    _searchController.clear(); // Bu _onSearchChanged'i tetikler (boş query ile)
    _dismissSearchIfApplicable(forceCollapse: true); // Odak yoksa arama alanını hemen daralt
  }

  /// Sadece belirtilen mood filtresini kaldırır.
  void _removeMoodFilter(Mood moodToRemove) {
    if (!mounted || _selectedMoodFilters == null) return;

    final updatedMoodFilters = List<Mood>.from(_selectedMoodFilters!)..remove(moodToRemove);
    final List<Mood>? finalFilters = updatedMoodFilters.isNotEmpty ? updatedMoodFilters : null;

    // BLoC'u tetikle (UI state'i listener ile güncellenecek)
    context.read<JournalBloc>().add(FilterJournalEntriesByCriteria(
        query: _searchController.text.trim(),
        moods: finalFilters
    ));
  }


  /// Tüm filtreleri (metin ve mood) temizler.
  /// Hata durumunda veya nadir senaryolarda kullanılır. UI'da direkt butonu yok.
  void _clearAllFilters() {
    if (!mounted) return;
    final currentState = context.read<JournalBloc>().state;
    bool needsBlocUpdate = false;

    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      needsBlocUpdate = true;
    }
    if (_selectedMoodFilters != null) {
      _selectedMoodFilters = null;
      needsBlocUpdate = true;
    }
    if (_isSearchExpanded){
      _isSearchExpanded = false;
    }

    setState(() {}); // UI'ı anında güncelle
    FocusScope.of(context).unfocus();
    _currentSearchQueryForDebounce = '';

    // Eğer state zaten temiz değilse BLoC'u tetikle
    if (needsBlocUpdate && currentState is JournalLoadSuccess && currentState.isFiltered) {
      context.read<JournalBloc>().add(const FilterJournalEntriesByCriteria(query: null, moods: null));
    }
  }

  /// BLoC state'inden filtre UI elemanlarını senkronize eder.
  void _syncFiltersFromState(JournalLoadSuccess state) {
    if (!mounted) return;

    final blocQuery = state.currentFilterQuery ?? '';
    final blocMoods = state.currentMoodFilters;

    bool uiNeedsUpdate = false;

    // Metin Alanı Senkronizasyonu
    if (_searchController.text != blocQuery) {
      _currentSearchQueryForDebounce = blocQuery;
      // Listener'ı tetiklemeden değeri güncelle (Widget build sonrası)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted){
          _searchController.value = TextEditingValue(
            text: blocQuery,
            selection: TextSelection.collapsed(offset: blocQuery.length),
          );
        }
      });
      uiNeedsUpdate = true;
    }

    // Genişleme Durumu Senkronizasyonu
    // Sorgu varsa veya odak varsa genişlemiş olmalı
    final bool shouldBeExpanded = blocQuery.isNotEmpty || _searchFocusNode.hasFocus;
    if (_isSearchExpanded != shouldBeExpanded) {
      _isSearchExpanded = shouldBeExpanded;
      uiNeedsUpdate = true;
    }

    // Mood Filtreleri Senkronizasyonu
    final currentFiltersSet = _selectedMoodFilters?.toSet() ?? <Mood>{};
    final blocFiltersSet = blocMoods?.toSet() ?? <Mood>{};
    if (!setEquals(currentFiltersSet, blocFiltersSet)) {
      _selectedMoodFilters = blocMoods; // UI state'ini güncelle
      uiNeedsUpdate = true;
    }

    // Sadece UI state'inde gerçekten bir değişiklik olduysa setState çağır
    if (uiNeedsUpdate) {
      setState(() {});
    }
  }

  /// Ekranın boşluğuna tıklandığında aramayı kapatır (eğer boşsa ve odak yoksa).
  void _dismissSearchIfApplicable({bool forceCollapse = false}) {
    if (!mounted) return;
    // Eğer zorla kapatma isteniyorsa VEYA
    // arama genişlemişse, odak yoksa VE içi boşsa daralt
    if (forceCollapse || (_isSearchExpanded && !_searchFocusNode.hasFocus && _searchController.text.isEmpty)) {
      FocusScope.of(context).unfocus(); // Önce odağı kaldır
      // setState içinde _isSearchExpanded'ı false yapalım (eğer zaten değilse)
      if (_isSearchExpanded) {
        setState(() { _isSearchExpanded = false; });
      }
    }
    // Genel olarak odağı kaldır (klavyeyi kapatır)
    else {
      FocusScope.of(context).unfocus();
    }
  }

  // --- Takvim ve Bottom Sheet Yardımcıları (Değişiklik Yok) ---

  /// Belirli bir gün için girdileri döndürür.
  List<JournalEntry> _getEntriesForDay(DateTime day, List<JournalEntry> allEntries) {
    return allEntries.where((entry) => isSameDay(entry.createdAt, day)).toList();
  }

  /// Seçilen günün girdilerini gösteren BottomSheet'i açar.
  void _showEntriesBottomSheet(BuildContext scaffoldContext, DateTime day, List<JournalEntry> entries) {
    final theme = Theme.of(scaffoldContext);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showModalBottomSheet(
      context: scaffoldContext, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      backgroundColor: colorScheme.surfaceContainerLowest,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          expand: false, initialChildSize: 0.4, maxChildSize: 0.7, minChildSize: 0.25,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(height: 5, width: 40, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(2.5))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
                  child: Text(DateFormat('dd MMMM EEEE, yyyy', 'tr_TR').format(day), style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0), child: Text('Bu tarih için kayıt bulunamadı.', textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))))
                      : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    itemCount: entries.length,
                    itemBuilder: (ctx, index) => _buildJournalEntryCard(ctx, entries[index], theme), // Kart widget'ını kullan
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Gün seçildiğinde çalışır. Bottom Sheet'i gösterir veya mesaj verir.
  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay, List<JournalEntry> allEntries) {
    if (!isSameDay(_selectedDay, selectedDay)) { setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }); } if (!mounted) return;
    _dismissSearchIfApplicable(); // Gün seçildiğinde de aramayı kapat (eğer açıksa)
    final entriesForSelectedDay = _getEntriesForDay(selectedDay, allEntries);
    final currentColorScheme = Theme.of(context).colorScheme;
    if (entriesForSelectedDay.isNotEmpty) { _showEntriesBottomSheet(context, selectedDay, entriesForSelectedDay); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${DateFormat('dd MMMM', 'tr_TR').format(selectedDay)} için kayıt bulunmuyor.'), duration: const Duration(seconds: 2), backgroundColor: currentColorScheme.inverseSurface, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0))); }
  }

  // --- Ana Build Metodu ---
  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final currentColorScheme = currentTheme.colorScheme;
    final double bottomNavBarHeight = kBottomNavHeight + kBottomNavBottomMargin;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final double totalBottomPadding = bottomNavBarHeight + bottomSafeArea + 10.0;

    // Ekranın dışına tıklanınca aramayı daraltmak için GestureDetector
    return GestureDetector(
      onTap: _dismissSearchIfApplicable,
      child: BlocConsumer<JournalBloc, JournalState>(
        listener: (context, state) { /* Hata ve Senkronizasyon (önceki gibi) */
          if (state is JournalFailure) { final messenger = ScaffoldMessenger.maybeOf(context); if (mounted && messenger != null) { messenger.showSnackBar(SnackBar(content: Text('Hata: ${state.errorMessage}'), backgroundColor: currentColorScheme.error)); } /* Hata durumunda filtreleri temizleme isteğe bağlı */ }
          else if (state is JournalLoadSuccess) { _lastLoadedEntriesForFallback = state.entries; _syncFiltersFromState(state); }
        },
        builder: (context, state) {
          // Yükleme ve Hata durumları...
          if (state is JournalLoading && _lastLoadedEntriesForFallback.isEmpty) { return const Center(child: CircularProgressIndicator()); }
          else if (state is JournalFailure && _lastLoadedEntriesForFallback.isEmpty) { return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Hata: ${state.errorMessage}"))); }
          // Başarılı Yükleme Durumu
          else if (state is JournalLoadSuccess) {
            return Column( // Filtre alanı + TabView
              children: [
                // Filtre Kontrolleri (Genişleyen Arama + Filtre Butonu)
                _buildFilterControls(context, state, currentTheme),
                // Aktif Filtre Etiketleri (Ayrı bir alanda gösteriliyor)
                _buildActiveFiltersDisplay(context, state, currentTheme),
                // Sekmeler
                Expanded(
                  child: TabBarView(
                    controller: widget.tabController,
                    children: [
                      // Sekme 1: Filtrelenmiş Liste
                      _buildFilteredEntryList(context, state, currentTheme, totalBottomPadding),
                      // Sekme 2: Takvim
                      _buildCalendarView(context, state.entries, currentTheme, totalBottomPadding),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator()); // Fallback
          }
        },
      ),
    );
  }


  /// Üstteki arama ve filtre kontrol butonlarını oluşturan widget.
  Widget _buildFilterControls(BuildContext context, JournalLoadSuccess state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(76.0, 8.0, 26.0, 4.0),
      child: Row(
        children: [
          // Genişleyen Arama Alanı
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 40,
              decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                      color: _isSearchExpanded ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withOpacity(0.7),
                      width: _isSearchExpanded? 1.5 : 1.0
                  )
              ),
              // Tıklanabilir alan için GestureDetector
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: !_isSearchExpanded ? () { // Sadece daraltılmışken tıkla
                  if (mounted) {
                    setState(() => _isSearchExpanded = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) _searchFocusNode.requestFocus(); });
                  }
                } : null,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Arama İkonu / Geri İkonu (Her zaman tıklanabilir)
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: IconButton(
                        icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: Icon(
                                _isSearchExpanded ? Icons.search_sharp : Icons.search,
                                key: ValueKey<bool>(_isSearchExpanded),
                                size: 18, color: theme.colorScheme.onSurfaceVariant
                            )
                        ),
                        tooltip: _isSearchExpanded ? 'Aramayı Kapat/Temizle' : 'Ara',
                        onPressed: () {
                          if (_isSearchExpanded) {
                            if (_searchController.text.isNotEmpty) {
                              _removeTextFilter(); // Doluysa sadece metni temizle
                            } else {
                              _dismissSearchIfApplicable(forceCollapse: true); // Boşsa daralt
                            }
                          } else {
                            setState(() => _isSearchExpanded = true); // Daraltılmışsa genişlet
                            WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) _searchFocusNode.requestFocus(); }); // ve odaklan
                          }
                        },
                      ),
                    ),

                    // TextField
                    Positioned(
                      left: 40, right: 40, top: 0, bottom: 0,
                      child: AnimatedOpacity(
                        opacity: _isSearchExpanded ? 1.0 : 0.0, duration: const Duration(milliseconds: 200),
                        child: Visibility(
                          visible: _isSearchExpanded, maintainState: true,
                          child: TextField(
                            controller: _searchController, focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Ara...',
                              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 0),
                            ),
                            style: theme.textTheme.bodyLarge, textAlignVertical: TextAlignVertical.center,
                          ),
                        ),
                      ),
                    ),

                    // Temizle Butonu
                    if (_isSearchExpanded && _searchController.text.isNotEmpty)
                      Positioned(
                        right: 4, top: 0, bottom: 0,
                        child: IconButton(
                          icon: const Icon(Icons.clear, size: 20), tooltip: 'Metni Temizle',
                          onPressed: _removeTextFilter,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 5),

          // Filtre Butonu
          IconButton(
            icon: Icon( Icons.filter_list_rounded,
                weight: 900, size: 27,

                color: state.isMoodFiltered ? theme.colorScheme.primary :
                theme.colorScheme.onSurfaceVariant),
            tooltip: 'Filtrele (Ruh Hali)',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  /// Aktif filtreleri gösteren Chip listesini oluşturur.
  Widget _buildActiveFiltersDisplay(BuildContext context, JournalLoadSuccess state, ThemeData theme) {
    if (!state.isFiltered) { return const SizedBox.shrink(); } // Filtre yoksa gösterme

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 6.0, left: 16, right: 16),
      child: Wrap(
        alignment: WrapAlignment.start, crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6.0, runSpacing: 0.0, // runSpacing azaltıldı
        children: [
          // Metin Filtresi Chip'i
          if (state.isTextFiltered)
            Chip(
              label: Text("'${state.currentFilterQuery!}'", style: theme.textTheme.labelSmall),
              padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              deleteIcon: const Icon(Icons.cancel_rounded, size: 14),
              onDeleted: _removeTextFilter, // Metin filtresini kaldırır
            ),
          // Mood Filtresi Chip'leri
          if (state.isMoodFiltered)
            ...(state.currentMoodFilters!).map((mood) => Chip(
              avatar: FaIcon(mood.icon, size: 13, color: mood.getColor(theme.colorScheme)),
              label: Text(mood.displayName, style: theme.textTheme.labelSmall),
              padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              deleteIcon: const Icon(Icons.cancel_rounded, size: 14),
              onDeleted: () => _removeMoodFilter(mood), // İlgili mood filtresini kaldırır
            )),
        ],
      ),
    );
  }


  /// Sekme 1 içeriği: Liste.
  Widget _buildFilteredEntryList(BuildContext context, JournalLoadSuccess state, ThemeData theme, double bottomPadding) {
    final List<JournalEntry> entriesToShow = state.filteredEntries ?? state.entries;
    final bool isCurrentlyFiltered = state.isFiltered;
    final sortedEntries = List<JournalEntry>.from(entriesToShow)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Liste İçeriği (Boş veya Dolu)
    // YENİ: Dışarı tıklamayı algılamak için GestureDetector eklendi
    return GestureDetector(
      onTap: _dismissSearchIfApplicable, // Liste alanına tıklanınca da kapat
      child: _buildEntryListContent(context, sortedEntries, isCurrentlyFiltered, theme, bottomPadding),
    );
  }


  /// Listenin içeriğini (ListView veya boş mesaj) oluşturur.
  Widget _buildEntryListContent(BuildContext context, List<JournalEntry> entries, bool isFiltered, ThemeData theme, double bottomPadding) {
    if (entries.isEmpty) {
      // Boş Durum Mesajı
      return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isFiltered ? Icons.filter_alt_off_outlined : Icons.menu_book_outlined, size: 55, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(isFiltered ? 'Filtreyle eşleşen kayıt bulunamadı.' : 'Henüz günlük kaydınız bulunmuyor.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        // Genel temizle butonu kaldırıldı, çünkü tek tek temizleme var
      ])));
    }
    // Dolu Liste
    return Scrollbar(thumbVisibility: true, child: ListView.builder(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: bottomPadding), // Üst padding azaltıldı
        itemCount: entries.length,
        itemBuilder: (context, index) => Padding(padding: const EdgeInsets.symmetric(vertical: 3.0), child: _buildJournalEntryCard(context, entries[index], theme))
    ));
  }

  /// Tek bir günlük kartı widget'ını oluşturur.
  Widget _buildJournalEntryCard(BuildContext context, JournalEntry entry, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final moodColor = entry.mood?.getColor(colorScheme) ?? colorScheme.outlineVariant;
    final moodIcon = entry.mood?.icon;
    final cardBackgroundColor = entry.isFavorite ? moodColor.withOpacity(0.08) : colorScheme.surfaceContainerHigh;
    final favoriteColor = Colors.red.shade400;
    final iconColor = colorScheme.onSurfaceVariant.withOpacity(0.7);
    final DateFormat dateFormat = DateFormat('d MMMM EEEE', 'tr_TR');
    final DateFormat timeFormat = DateFormat('HH:mm', 'tr_TR');
    final bool isUpdated = entry.updatedAt.millisecondsSinceEpoch != entry.createdAt.millisecondsSinceEpoch;
    final String displayTitle = entry.title?.isNotEmpty ?? false ? entry.title! : 'Başlıksız';
    final String contentPreview = entry.content.split('\n').first;

    return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
            color: cardBackgroundColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: entry.isFavorite ? favoriteColor.withOpacity(0.6) : colorScheme.outline.withOpacity(0.25), width: entry.isFavorite ? 1.2 : 1.0),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: () async {
                  if (!mounted) return;
                  _dismissSearchIfApplicable(); // Detaya gitmeden önce aramayı kapat
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditJournalScreen(existingEntry: entry)));
                  if (mounted) { context.read<JournalBloc>().add(const LoadJournalEntries()); }
                },
                splashColor: moodColor.withOpacity(0.1),
                highlightColor: moodColor.withOpacity(0.05),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (moodIcon != null) Padding(padding: const EdgeInsets.only(right: 12.0, top: 3), child: FaIcon(moodIcon, color: moodColor, size: 20)),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(displayTitle, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.25), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(contentPreview, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.9), height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Row( children: [
                                      Icon(Icons.access_time_rounded, size: 12, color: iconColor), const SizedBox(width: 4),
                                      Text('${timeFormat.format(entry.createdAt)} - ${dateFormat.format(entry.createdAt)}', style: textTheme.bodySmall?.copyWith(color: iconColor)),
                                      if (isUpdated) ...[const SizedBox(width: 6), Icon(Icons.edit_note_rounded, size: 13, color: iconColor.withOpacity(0.7))]
                                    ])
                                  ]
                              )
                          ),
                          // YENİ: Tooltip widget'ı ile sarılmış IconButton
                          Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Tooltip( // Tooltip widget'ı eklendi
                                message: entry.isFavorite ? 'Sabitlemeyi kaldır' : 'Sabitle',
                                child: IconButton(
                                    iconSize: 20, padding: const EdgeInsets.all(4), visualDensity: VisualDensity.compact, constraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
                                    // tooltip parametresi kaldırıldı
                                    icon: Icon(entry.isFavorite ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: entry.isFavorite ? favoriteColor : iconColor.withOpacity(0.8)),
                                    onPressed: () { context.read<JournalBloc>().add(ToggleFavoriteStatus(entryId: entry.id, currentStatus: entry.isFavorite)); }
                                ),
                              )
                          )
                        ]
                    )
                )
            )
        )
    );
  }


  /// Sekme 2: Takvim görünümünü oluşturur.
  Widget _buildCalendarView(BuildContext context, List<JournalEntry> allEntries, ThemeData theme, double bottomPadding) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // Stiller (HeaderStyle, CalendarStyle)
    final headerStyle = HeaderStyle(formatButtonVisible: true, formatButtonShowsNext: false, formatButtonTextStyle: textTheme.labelMedium!.copyWith(color: colorScheme.primary), formatButtonDecoration: BoxDecoration(border: Border.all(color: colorScheme.primary.withOpacity(0.5)), borderRadius: BorderRadius.circular(12.0)), titleCentered: true, titleTextStyle: textTheme.titleLarge ?? const TextStyle(), leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface), rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface));
    final calendarStyle = CalendarStyle(todayDecoration: BoxDecoration(border: Border.all(color: colorScheme.primary, width: 1.5), shape: BoxShape.circle), todayTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold), selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle), selectedTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold), weekendTextStyle: TextStyle(color: colorScheme.tertiary.withOpacity(0.8)), markersAlignment: Alignment.bottomCenter, markersOffset: const PositionedOffset(bottom: 5), markerDecoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle), markersMaxCount: 1, outsideDaysVisible: false);

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: bottomPadding),
        // Takvime dokunulduğunda da aramayı daralt
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // Takvimin boş alanlarına dokunmayı yakala
          onTap: _dismissSearchIfApplicable,
          child: TableCalendar<JournalEntry>(
            locale: 'tr_TR', firstDay: DateTime.utc(2020, 1, 1), lastDay: DateTime.utc(DateTime.now().year + 5, 12, 31), focusedDay: _focusedDay, calendarFormat: _calendarFormat, availableCalendarFormats: const { CalendarFormat.month: 'Aylık', CalendarFormat.twoWeeks: '2 Hafta', CalendarFormat.week: 'Haftalık'},
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) => _handleDaySelected(selectedDay, focusedDay, allEntries), // Yardımcı metodu çağır
            headerStyle: headerStyle, calendarStyle: calendarStyle,
            eventLoader: (day) => _getEntriesForDay(day, allEntries),
            onFormatChanged: (format) { if (_calendarFormat != format) { setState(() { _calendarFormat = format; }); } },
            onPageChanged: (focusedDay) { setState(() { _focusedDay = focusedDay; }); },
          ),
        ),
      ),
    );
  }


} // _CalendarPageState sonu