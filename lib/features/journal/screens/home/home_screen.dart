// lib/screens/home_screen.dart (YENİ TASARIM)

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/add_edit_journal_screen.dart';
import 'package:mindvault/features/journal/screens/journal_list_screen.dart';
import 'package:mindvault/theme_mindvault.dart';
import 'package:table_calendar/table_calendar.dart'; // Takvim paketi

// --- Kendi Proje Dosyalarınız ---
// (Yolları KONTROL EDİN ve kendi projenize göre güncelleyin!)

// import 'package:mind_vault/features/settings/screens/settings_screen.dart'; // Ayarlar ekranı varsa

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Takvim için state değişkenleri
  CalendarFormat _calendarFormat = CalendarFormat.week; // Başlangıçta haftalık görünüm
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Rastgele söz
  final List<String> _inspirationalQuotes = [
    "Bugün zihnine nazik davran.",
    "Küçük anların değerini bil.",
    "Yazmak, düşünceleri netleştirir.",
    "Hissettiğin her şey geçerli.",
    "Bir adım da olsa ilerle.",
  ];
  late String _dailyQuote;

  // Günlük girdilerini tutacak liste (BLoC'tan alınacak)
  List<JournalEntry> _allEntries = [];
  // Seçili güne ait girdiler
  List<JournalEntry> _selectedDayEntries = [];

  @override
  void initState() {
    super.initState();
    _dailyQuote = _inspirationalQuotes[Random().nextInt(_inspirationalQuotes.length)];
    _selectedDay = _focusedDay; // Başlangıçta bugünü seçili yap

    // BLoC state'ini dinleyerek girdileri ve seçili gün girdilerini güncelle
    // Eğer state zaten LoadSuccess ise ilk değerleri alalım
    final currentState = context.read<JournalBloc>().state;
    if (currentState is JournalLoadSuccess) {
      _allEntries = currentState.entries;
      _selectedDayEntries = _getEntriesForDay(_selectedDay!);
    } else {
      // Değilse yüklenmesini tetikle (main.dart'ta zaten yapılıyor olabilir)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<JournalBloc>().state is JournalInitial) {
          context.read<JournalBloc>().add(const LoadJournalEntries());
        }
      });
    }
  }

  /// Belirli bir gün için günlük girdilerini döndürür.
  List<JournalEntry> _getEntriesForDay(DateTime day) {
    // Tarihlerin gün, ay, yıl olarak eşleşmesini kontrol et
    return _allEntries.where((entry) => isSameDay(entry.createdAt, day)).toList();
  }

  /// Takvimde bir gün seçildiğinde tetiklenir.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // focusedDay'i de güncellemek önemli
        _selectedDayEntries = _getEntriesForDay(selectedDay);
      });
      if (kDebugMode) {
        print("Selected day: $selectedDay, Found entries: ${_selectedDayEntries.length}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    // ignore: unused_local_variable
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Vault'),
        // AppBar'ı daha sade tutalım, ayarlar için ikon ekleyelim
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () {
              // TODO: Ayarlar ekranına git
              if (kDebugMode) {
                print("Settings button tapped.");
              }
              // Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
        ],
      ),
      body: BlocListener<JournalBloc, JournalState>(
        // Liste güncellendiğinde veya hata olduğunda state'i yenile
        listener: (context, state) {
          if (state is JournalLoadSuccess) {
            setState(() {
              _allEntries = state.entries;
              // Seçili gün değişmediyse bile, o gün için girdiler güncellenmiş olabilir
              if (_selectedDay != null) {
                _selectedDayEntries = _getEntriesForDay(_selectedDay!);
              }
            });
            if (kDebugMode) {
              print("HomeScreen BlocListener: Received JournalLoadSuccess, updated entries.");
            }
          } else if (state is JournalFailure) {
            // Hata durumunda belki bir SnackBar gösterilebilir
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Veri yüklenirken hata: ${state.errorMessage}'),
              backgroundColor: colorScheme.error,
            ));
            if (kDebugMode) {
              print("HomeScreen BlocListener: Received JournalFailure: ${state.errorMessage}");
            }
          }
        },
        // Sadece state tipinin değiştiği durumlarda yeniden çizim yapmamak için
        // BlocBuilder yerine BlocConsumer veya sadece Listener kullanmak daha iyi olabilir.
        // Şimdilik tüm sayfayı yeniden çizdirelim.
        child: ListView( // Ana kaydırılabilir alan
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // FAB için altta boşluk
          children: [
            // --- Günün Sözü ---
            _buildDailyQuoteCard(context, _dailyQuote),
            const SizedBox(height: 24.0),

            // --- Hızlı Eylemler ---
            _buildQuickActions(context),
            const SizedBox(height: 24.0),

            // --- Takvim Bölümü ---
            _buildCalendarSection(context),
            const SizedBox(height: 16.0),

            // --- Seçili Günün Girdileri (varsa) ---
            if (_selectedDayEntries.isNotEmpty)
              _buildSelectedDayEntries(context),

            const SizedBox(height: 24.0),

            // --- Tüm Günlüğe Git Butonu ---
            _buildGoToJournalButton(context),
            const SizedBox(height: 24.0),

            // --- Gizlilik Hatırlatması ---
            _buildPrivacyReminder(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditJournalScreen()));
        },
        tooltip: 'Yeni Günlük Ekle',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }


  Widget _buildGoToJournalButton(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Hızlı aksiyon butonlarıyla hizalı olması için benzer padding
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // Veya padding yok
      child: OutlinedButton.icon(
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Tüm Günlüğü Görüntüle'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500), // Biraz daha ince belki?
          foregroundColor: theme.colorScheme.secondary, // İkincil rengi kullanalım
          side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5)),
          minimumSize: const Size.fromHeight(45), // Buton yüksekliği
        ),
        onPressed: () {
          if (kDebugMode) {
            print("Navigating to JournalListScreen from GoToJournal button.");
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalListScreen()));
        },
      ),
    );
  }
  // --- Yardımcı Builder Metotları ---

  Widget _buildDailyQuoteCard(BuildContext context, String quote) {
    // ... (Önceki Pano kodundaki ile aynı veya benzer) ...
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.format_quote_rounded, color: theme.colorScheme.secondary.withOpacity(0.8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quote,
                style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text("Yeni Girdi"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditJournalScreen()));
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.checklist_rtl_rounded, size: 20),
            label: const Text("Tüm Günlük"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalListScreen()));
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: theme.colorScheme.secondary,
              side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      // elevation: 0,
      // shape: RoundedRectangleBorder(
      //   side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      //   borderRadius: BorderRadius.circular(12),
      // ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0), // Altta biraz boşluk
        child: TableCalendar<JournalEntry>( // Generic tip olarak JournalEntry verdik
          locale: 'tr_TR', // Türkçe yerelleştirme
          firstDay: DateTime.utc(2020, 1, 1), // Gösterilecek ilk tarih
          lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31), // Gösterilecek son tarih
          focusedDay: _focusedDay, // Takvimin odaklanacağı gün
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day), // Hangi günün seçili olduğunu belirler
          calendarFormat: _calendarFormat, // Hafta veya ay formatı
          startingDayOfWeek: StartingDayOfWeek.monday, // Haftanın başlangıcı Pazartesi
          // eventLoader: _getEntriesForDay, // Her gün için event (girdi) listesini döndüren fonksiyon
          calendarStyle: CalendarStyle(
            // Bugünün işaretçisi
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            // Seçili günün işaretçisi
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
            // Hafta sonları
            weekendTextStyle: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.8)),
            // Dışarıdaki günler (önceki/sonraki ay)
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true, // Ay/Hafta değiştirme butonu
            titleCentered: true,
            formatButtonShowsNext: false, // Buton sadece formatı değiştirir, sonraki aya gitmez
            titleTextStyle: theme.textTheme.titleMedium!,
            formatButtonTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
            formatButtonDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12.0),
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
            rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
          ),
          // Gün seçildiğinde tetiklenir
          onDaySelected: _onDaySelected,
          // Takvim formatı değiştiğinde (Ay <-> Hafta)
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          // Odaklanılan gün değiştiğinde (sağa/sola kaydırınca)
          onPageChanged: (focusedDay) {
            // focusedDay state'ini güncellemek önemli, ancak _selectedDay'i değiştirmemeli
            _focusedDay = focusedDay;
          },
          // Takvim hücrelerini özelleştirme (Mood renklerini göstermek için)
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              // O güne ait girdiler varsa marker göster
              final entriesForDay = _getEntriesForDay(day);
              if (entriesForDay.isNotEmpty) {
                // Birden fazla girdi varsa veya tek varsa farklı markerlar olabilir
                return Positioned( // Noktayı hücrenin altına yerleştir
                  bottom: 1,
                  // right: 1, // Veya ortala
                  child: Wrap( // Birden fazla mood varsa yan yana noktalar
                    spacing: 2,
                    children: entriesForDay.take(3).map((entry) { // En fazla 3 nokta gösterelim
                      final moodColor = MindVaultTheme.getColorForMood(entry.mood, theme.brightness);
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: moodColor.withOpacity(0.8), // Hafif şeffaf
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
              return null; // O gün girdi yoksa marker gösterme
            },
          ),
        ),
      ),
    );
  }

  /// Seçili güne ait günlük girdilerini gösteren bölüm.
  Widget _buildSelectedDayEntries(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text(
              DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay!),
              style: theme.textTheme.titleMedium
          ),
        ),
        // Seçili gün girdileri için kompakt liste
        ListView.builder(
          itemCount: _selectedDayEntries.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final entry = _selectedDayEntries[index];
            // JournalListItem'ı veya daha basit bir ListTile kullanabiliriz
            return Card(
              margin: const EdgeInsets.only(bottom: 6.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: MindVaultTheme.getColorForMood(entry.mood, theme.brightness).withOpacity(0.8),
                  radius: 18,
                  child: Icon(_getMoodIcon(entry.mood), size: 18, color: MindVaultTheme.getOnColorForMood(MindVaultTheme.getColorForMood(entry.mood, theme.brightness))),
                ),
                title: Text(entry.content.split('\n').first, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(DateFormat('HH:mm', 'tr_TR').format(entry.updatedAt)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  // TODO: Detay ekranına git
                },
              ),
            );
          },
        ),
      ],
    );
  }


  /// Gizlilik hatırlatmasını gösteren bölüm.
  Widget _buildPrivacyReminder(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            "Verileriniz şifreli ve sadece cihazınızda.",
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // Mood'a göre ikon döndüren yardımcı metot
  IconData _getMoodIcon(Mood? mood) {
    final Map<Mood, IconData> moodIcons = {
      Mood.happy: Icons.sentiment_very_satisfied_rounded,
      Mood.excited: Icons.celebration_rounded,
      Mood.grateful: Icons.volunteer_activism_rounded,
      Mood.calm: Icons.self_improvement_rounded,
      Mood.neutral: Icons.sentiment_neutral_rounded,
      Mood.sad: Icons.sentiment_very_dissatisfied_rounded,
      Mood.anxious: Icons.priority_high_rounded,
      Mood.stressed: Icons.bolt_rounded,
      Mood.tired: Icons.battery_alert_rounded,
      Mood.angry: Icons.local_fire_department_rounded,
    };
    return moodIcons[mood] ?? Icons.radio_button_unchecked; // Varsayılan veya bilinmeyen
  }
}