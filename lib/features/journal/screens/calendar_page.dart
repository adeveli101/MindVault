import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
// FontAwesome ikonlarını kullanmak için:

// Projenizdeki ilgili dosyaları import edin (Yolları kontrol edin!)
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/page_screens/add_edit_journal_screen.dart'; // Düzenleme ekranı
import 'package:mindvault/features/journal/screens/themes/themed_background.dart'; // Arka plan
// import 'package:mindvault/features/journal/screens/widgets/mood_selector_widget.dart'; // Artık doğrudan kullanılmıyor ama ikon/renk mantığı burada

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late PageController _pageController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // Son başarılı yüklemedeki tüm girdileri tutmak için bir liste
  List<JournalEntry> _lastLoadedEntries = [];

  // Mood ikonları (FontAwesome ile güncellenmiş hali)
  // TODO: Ortak bir utility sınıfına taşıyın.
  final Map<Mood, IconData> _moodIcons = {
    Mood.happy: FontAwesomeIcons.faceSmileBeam,
    Mood.excited: FontAwesomeIcons.faceGrinStars,
    Mood.grateful: FontAwesomeIcons.handsPraying,
    Mood.calm: FontAwesomeIcons.dove,
    Mood.neutral: FontAwesomeIcons.faceMeh,
    Mood.sad: FontAwesomeIcons.faceSadTear,
    Mood.anxious: FontAwesomeIcons.faceFlushed,
    Mood.stressed: FontAwesomeIcons.boltLightning,
    Mood.tired: FontAwesomeIcons.batteryQuarter,
    Mood.angry: FontAwesomeIcons.faceAngry,
    Mood.unknown: FontAwesomeIcons.circleQuestion, // Deprecated olan düzeltildi
  };

  Color _getColorForMood(Mood mood, ColorScheme colorScheme) {
    switch (mood) {
      case Mood.happy: return Colors.amber.shade600;
      case Mood.excited: return Colors.orange.shade600;
      case Mood.grateful: return Colors.pink.shade300;
      case Mood.calm: return colorScheme.secondary;
      case Mood.neutral: return colorScheme.onSurfaceVariant;
      case Mood.sad: return Colors.blue.shade600;
      case Mood.anxious: return Colors.purple.shade300;
      case Mood.stressed: return colorScheme.error;
      case Mood.tired: return Colors.brown.shade400;
      case Mood.angry: return colorScheme.errorContainer;
      default: return colorScheme.outline;
    }
  }
  // ---------

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedDay = _focusedDay; // Başlangıçta bugünü seçili yap

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Asenkron boşluk sonrası context kontrolü
      if (!mounted) return;
      final currentState = context.read<JournalBloc>().state;
      if (currentState is JournalInitial) {
        context.read<JournalBloc>().add(const LoadJournalEntries());
      }
      else if (currentState is JournalLoadSuccess) {
        _lastLoadedEntries = currentState.entries;
        // _selectedDayEntriesList kaldırıldığı için burada atama yok.
        // Gerekirse ilk günün girdilerini almak için _getEntriesForDay çağrılabilir
        // ama UI ilk build'de BlocBuilder'dan alacak.
        if(mounted) setState(() {}); // State'i güncellemek gerekebilir (örn. markerlar için)
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Belirli bir gün için günlük girdilerini döndürür.
  List<JournalEntry> _getEntriesForDay(DateTime day, List<JournalEntry> allEntries) {
    return allEntries.where((entry) => isSameDay(entry.createdAt, day)).toList();
  }

  /// Seçili gün için girdileri gösteren bir bottom sheet açar.
  void _showEntriesBottomSheet(BuildContext context, DateTime day, List<JournalEntry> entries) {
    // Bu fonksiyon çağrıldığında context'in hala geçerli olduğunu varsayıyoruz
    // (genellikle onDaySelected içinden çağrılır ve orada kontrol edilir)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        backgroundColor: colorScheme.surfaceContainerLowest,
        builder: (bottomSheetContext) { // Farklı bir context ismi
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.6,
            builder: (_, scrollController) => Container(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4, width: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    DateFormat('dd MMMM<y_bin_46>, EEEE', 'tr_TR').format(day),
                    style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(height: 12.0),
                  entries.isEmpty
                      ? Expanded(
                    child: Center(
                      child: Text(
                        'Bu tarih için kayıt bulunamadı.',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                      : Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: entries.length,
                      itemBuilder: (ctx, index) { // Farklı context ismi
                        final entry = entries[index];
                        final fallbackIcon = FontAwesomeIcons.circleQuestion; // Düzeltilmiş fallback
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: entry.mood != null
                                ? FaIcon(
                              _moodIcons[entry.mood!] ?? fallbackIcon,
                              color: _getColorForMood(entry.mood!, colorScheme),
                              size: 26,
                            )
                                : Icon(Icons.article_outlined, size: 26, color: colorScheme.onSurfaceVariant),
                            title: Text(
                              entry.title?.isNotEmpty ?? false ? entry.title! : 'Başlıksız',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              entry.content,
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              DateFormat('HH:mm').format(entry.createdAt),
                              style: textTheme.labelSmall,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            tileColor: colorScheme.surfaceContainer.withOpacity(0.5),
                            onTap: () async { // Async yapıldı
                              Navigator.pop(bottomSheetContext); // Bottom sheet'i kapat
                              // Navigasyondan önce context kontrolü
                              if (!mounted) return;
                              await Navigator.push( // await eklendi
                                context, // Ana context kullanıldı
                                MaterialPageRoute(
                                  builder: (_) => AddEditJournalScreen(existingEntry: entry),
                                ),
                              );
                              // Navigasyondan sonra context kontrolü
                              if (!mounted) return;
                              // Geri dönüldüğünde listeyi yenile
                              context.read<JournalBloc>().add(const LoadJournalEntries());
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ColorScheme ve TextTheme artık BlocBuilder içinde state'e göre alınacak

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Takvim & Günlükler'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<JournalBloc, JournalState>(
          builder: (context, state) {
            // build metodu içinde tema verilerini alalım
            final currentTheme = Theme.of(context);
            final currentColorScheme = currentTheme.colorScheme;
            final currentTextTheme = currentTheme.textTheme;

            // 1. Başarılı Durum
            if (state is JournalLoadSuccess) {
              _lastLoadedEntries = state.entries; // Son veriyi sakla
              // Başarılı durumda PageView'ı göster
              return PageView(
                controller: _pageController,
                children: [
                  _buildEntryList(context, _lastLoadedEntries, currentTheme), // Temayı gönder
                  _buildCalendarView(context, _lastLoadedEntries, currentTheme), // Temayı gönder
                ],
              );
            }
            // 2. Yükleme Durumu
            else if (state is JournalLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // 3. Hata Durumu
            else if (state is JournalFailure) {
              return Center(
                child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: currentColorScheme.error, size: 40),
                        const SizedBox(height: 10),
                        // Hata mesajı için interpolasyon kullanıldı
                        Text('Hata: ${state.errorMessage}', textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context.read<JournalBloc>().add(const LoadJournalEntries()),
                          child: const Text('Tekrar Dene'),
                        )
                      ],
                    )
                ),
              );
            }
            // 4. Başlangıç Durumu veya Diğer Durumlar
            else { // JournalInitial veya beklenmedik bir durum
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  // --- Ekran 1: Günlük Listesi Widget'ı ---
  Widget _buildEntryList(BuildContext context, List<JournalEntry> entries, ThemeData theme) {
    if (entries.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Henüz günlük kaydınız bulunmuyor.\nSağa kaydırıp takvimden bir gün seçebilir veya yeni kayıt ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
      );
    }
    final sortedEntries = List<JournalEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          // Her kart için tema bilgisini gönder
          return _buildJournalEntryCard(context, entry, theme);
        }
    );
  }

  // --- Gelişmiş Günlük Kartı Widget'ı ---
  Widget _buildJournalEntryCard(BuildContext context, JournalEntry entry, ThemeData theme) {
    // Kart içinde tema verilerini al
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final moodColor = entry.mood != null ? _getColorForMood(entry.mood!, colorScheme) : colorScheme.outline;
    final fallbackIcon = FontAwesomeIcons.circleQuestion; // Düzeltilmiş fallback
    final moodIcon = entry.mood != null ? (_moodIcons[entry.mood!] ?? fallbackIcon) : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async { // Async yapıldı
          // Navigasyon öncesi context kontrolü
          if (!mounted) return;
          await Navigator.push( // await eklendi
            context,
            MaterialPageRoute(
              builder: (_) => AddEditJournalScreen(existingEntry: entry),
            ),
          );
          // Navigasyon sonrası context kontrolü
          if (!mounted) return;
          // Geri dönüldüğünde listeyi yenile
          context.read<JournalBloc>().add(const LoadJournalEntries());
        },
        splashColor: moodColor.withOpacity(0.1),
        highlightColor: moodColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (moodIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: FaIcon(moodIcon, color: moodColor, size: 22),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM, EEEE HH:mm', 'tr_TR').format(entry.createdAt),
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    if (entry.title != null && entry.title!.isNotEmpty)
                      Text(
                        entry.title!,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        entry.content,
                        style: textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        entry.content,
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.9)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Ekran 2: Takvim Widget'ı ---
  Widget _buildCalendarView(BuildContext context, List<JournalEntry> entries, ThemeData theme) {
    // Takvim içinde tema verilerini al
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TableCalendar<JournalEntry>(
              locale: 'tr_TR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(DateTime.now().year + 5, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  final entriesForSelectedDay = _getEntriesForDay(selectedDay, entries);
                  // Seçili gün state'ini güncelle
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    // _selectedDayEntriesList artık state'te tutulmuyor
                  });
                  // Asenkron boşluk sonrası context kontrolü
                  if (!mounted) return;
                  // Sadece girdi varsa bottom sheet aç
                  if (entriesForSelectedDay.isNotEmpty) {
                    _showEntriesBottomSheet(context, selectedDay, entriesForSelectedDay);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        // Interpolasyon kullanıldı
                        content: Text('${DateFormat('dd MMMM<y_bin_46>, EEEE', 'tr_TR').format(selectedDay)} için kayıt bulunmuyor.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                formatButtonShowsNext: false,
                formatButtonTextStyle: textTheme.labelMedium!.copyWith(color: colorScheme.primary),
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                titleCentered: true,
                titleTextStyle: textTheme.titleLarge ?? const TextStyle(),
                leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
                rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                weekendTextStyle: TextStyle(color: colorScheme.secondary),
                markersAlignment: Alignment.bottomCenter,
                markersOffset: const PositionedOffset(bottom: 4),
                markerDecoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                outsideDaysVisible: false,
              ),
              eventLoader: (day) {
                return _getEntriesForDay(day, entries);
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() { _calendarFormat = format; });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
        ],
      ),
    );
  }

} // _CalendarPageState sonu