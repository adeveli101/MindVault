// lib/features/journal/screens/calendar_page.dart
// *** BU KOD, main_screen.dart'ın AppBar ve TabController'ı YÖNETMESİNİ GEREKTİRİR! ***
// *** MainScreen Scaffold'unda extendBody: true ve PageView padding'i KALDIRILMIŞ olmalıdır! ***
// Bu versiyon Scaffold, AppBar, ThemedBackground veya local TabController İÇERMEZ.
// İçerik padding'i alt widget'larda yönetilir.

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Proje importları
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart'; // MoodUtils extension
import 'package:mindvault/features/journal/screens/page_screens/add_edit_journal_screen.dart';

// main_screen.dart'taki sabitler (Tutarlılık için)
const double kBottomNavHeight = 65.0;
const double kBottomNavBottomMargin = 32.0;

class CalendarPage extends StatefulWidget {
  // *** YENİ: MainScreen'den gelen TabController ***
  final TabController tabController;

  const CalendarPage({
    super.key,
    required this.tabController, // Constructor'a eklendi
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> { // TickerProviderStateMixin KALDIRILDI
  // Yerel TabController KALDIRILDI

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<JournalEntry> _lastLoadedEntries = [];

  // Yerel mood tanımlamaları YOK (MoodUtils extension kullanılıyor)

  @override
  void initState() {
    super.initState();
    // Yerel TabController başlatma KALDIRILDI
    _selectedDay = _focusedDay;
    // Veri yükleme...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = context.read<JournalBloc>().state;
      if (currentState is JournalInitial || currentState is JournalFailure) {
        context.read<JournalBloc>().add(const LoadJournalEntries());
      } else if (currentState is JournalLoadSuccess) {
        _lastLoadedEntries = currentState.entries;
        // Sadece state değişikliği gerektiğinde çağrılmalı
        if (mounted) setState(() {});
      }
    });
  }

  // dispose metodu artık yerel controller olmadığı için gerekmiyor.

  List<JournalEntry> _getEntriesForDay(DateTime day, List<JournalEntry> allEntries) {
    // TableCalendar widget'ından isSameDay fonksiyonunu kullanır.
    return allEntries.where((entry) => isSameDay(entry.createdAt, day)).toList();
  }

  // BottomSheet gösterme fonksiyonu
  void _showEntriesBottomSheet(BuildContext scaffoldContext, DateTime day, List<JournalEntry> entries) {
    // Temayı scaffoldContext'ten alıyoruz (MainScreen'den gelen context)
    final theme = Theme.of(scaffoldContext);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showModalBottomSheet(
      context: scaffoldContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),),
      backgroundColor: colorScheme.surfaceContainerLowest, // Alt sayfa arka plan rengi
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4, // Başlangıç boyutu
          minChildSize: 0.25,   // Minimum boyut
          maxChildSize: 0.7,    // Maksimum boyut
          builder: (_, scrollController) {
            return Column(
              children: [
                // Sürükleme Çubuğu
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                // Başlık (Seçilen Gün)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0), // Alt boşluk eklendi
                  child: Text(
                    DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(day), // Yıl da eklendi
                    style: textTheme.titleMedium?.copyWith( // Biraz daha küçük başlık
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                // const Divider(height: 1), // İsteğe bağlı ayırıcı çizgi

                // Liste veya Boş Durum
                Expanded(
                  child: entries.isEmpty
                      ? Center( // Kayıt yoksa gösterilecek mesaj
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                      child: Text(
                        'Bu tarih için kayıt bulunamadı.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                      : ListView.builder( // Kayıt varsa liste
                    controller: scrollController,
                    // Kenarlara padding verelim
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
                    itemCount: entries.length,
                    itemBuilder: (ctx, index) {
                      final entry = entries[index];

                      // *** DEĞİŞİKLİK: ListTile yerine _buildJournalEntryCard kullanılıyor ***
                      // Kartın kendi iç padding'i olduğu için ekstra Padding'e genellikle gerek yok.
                      return _buildJournalEntryCard(ctx, entry, theme);
                      // ---------------------------------------------------------------------

                      /* ÖNCEKİ KOD (Referans için silindi):
                            final itemColorScheme = Theme.of(ctx).colorScheme;
                            final IconData? moodIconData = entry.mood?.icon;
                            final Color moodColor = entry.mood?.getColor(itemColorScheme) ?? itemColorScheme.outlineVariant;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                leading: moodIconData != null ? FaIcon(moodIconData, color: moodColor, size: 26,) : Icon(Icons.article_outlined, size: 26, color: itemColorScheme.onSurfaceVariant,),
                                title: Text( entry.title?.isNotEmpty ?? false ? entry.title! : 'Başlıksız', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                subtitle: Text( entry.content, style: textTheme.bodySmall?.copyWith(color: itemColorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                trailing: Text( DateFormat('HH:mm').format(entry.createdAt), style: textTheme.labelSmall,),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                tileColor: itemColorScheme.surfaceContainerHigh,
                                onTap: () async {
                                  Navigator.pop(bottomSheetContext); // Önce bottom sheet'i kapat
                                  if (!scaffoldContext.mounted) return;
                                  // Düzenleme ekranına git
                                  await Navigator.push(
                                    scaffoldContext,
                                    MaterialPageRoute(builder: (_) => AddEditJournalScreen(existingEntry: entry)),
                                  );
                                  // Geri dönüldüğünde listeyi yenilemek için Bloc event'i gönder
                                  if (!scaffoldContext.mounted) return;
                                  scaffoldContext.read<JournalBloc>().add(const LoadJournalEntries());
                                },
                              ),
                            );
                            */
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Scaffold, AppBar, ThemedBackground YOK.
    final currentTheme = Theme.of(context);
    final currentColorScheme = currentTheme.colorScheme;
    // Alt boşluk hesaplaması
    final double bottomNavBarHeight = kBottomNavHeight + kBottomNavBottomMargin;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final double totalBottomPadding = bottomNavBarHeight + bottomSafeArea + 10.0;

    // Sayfanın ana içeriği BlocConsumer
    return BlocConsumer<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalFailure) {
          // SnackBar için MainScreen context'ini kullanır
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar( content: Text('Hata: ${state.errorMessage}'), backgroundColor: currentColorScheme.error,),
          );
        }
      },
      builder: (context, state) {
        // Yükleme durumu
        if (state is JournalLoading && _lastLoadedEntries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        // Hata durumu
        else if (state is JournalFailure && _lastLoadedEntries.isEmpty) {
          return Center(child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, color: currentColorScheme.error, size: 40),
            const SizedBox(height: 10), Text(state.errorMessage, textAlign: TextAlign.center), const SizedBox(height: 10),
            ElevatedButton( onPressed: () => context.read<JournalBloc>().add(const LoadJournalEntries()), child: const Text('Tekrar Dene'),)
          ],)));
        }
        // Başarılı veya Hata (eski veri var) durumu
        else {
          if (state is JournalLoadSuccess) { _lastLoadedEntries = state.entries; }
          // TabBarView döndürülür, controller widget'tan gelir
          return TabBarView(
            controller: widget.tabController, // MainScreen'den gelen controller
            children: [
              // Sekme içerikleri alt padding ile oluşturulur
              _buildEntryList(context, _lastLoadedEntries, currentTheme, totalBottomPadding),
              _buildCalendarView(context, _lastLoadedEntries, currentTheme, totalBottomPadding),
            ],
          );
        }
      },
    );
    // FloatingActionButton burada OLMAZ.
  }

  // --- Sekme 1: Günlük Listesi (Alt Padding eklendi) ---
  Widget _buildEntryList(BuildContext context, List<JournalEntry> entries, ThemeData theme, double bottomPadding) {
    // Boş durum kontrolü
    if (entries.isEmpty) {
      return Center(child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.menu_book, size: 50, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)), const SizedBox(height: 16),
        Text( 'Henüz günlük kaydınız bulunmuyor.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),),
      ],),),);
    }
    // Girdileri sırala
    final sortedEntries = List<JournalEntry>.from(entries)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Kaydırılabilir liste
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        // İç padding: Kenarlar ve alt boşluk
          padding: EdgeInsets.only( left: 16.0, right: 16.0, top: 8.0, bottom: bottomPadding ),
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            // Kart için ek yatay padding
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildJournalEntryCard(context, sortedEntries[index], theme),
            );
          } ), );
  }

// --- Gelişmiş Günlük Kartı (Sadece Tarih Odaklı) ---
  Widget _buildJournalEntryCard(BuildContext context, JournalEntry entry, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Renk ve ikonlar
    final moodColor = entry.mood?.getColor(colorScheme) ?? colorScheme.outlineVariant;
    final moodIcon = entry.mood?.icon;
    final cardBackgroundColor = entry.isFavorite ? moodColor.withOpacity(0.08) : colorScheme.surfaceContainer;
    final favoriteColor = Colors.brown.shade600;
    final iconColor = colorScheme.onSurfaceVariant.withOpacity(0.7);

    // Tarih Formatları
    final DateFormat dateFormat = DateFormat('d MMMM yyyy', 'tr_TR'); // Yılı da ekleyelim
    final DateFormat timeFormat = DateFormat('(HH:mm)', 'tr_TR');

    // Güncelleme kontrolü
    final bool isUpdated = entry.updatedAt.millisecondsSinceEpoch != entry.createdAt.millisecondsSinceEpoch;

    // *** BAŞLIK VE İÇERİK METNİ TAMAMEN KALDIRILDI ***

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: colorScheme.outline.withOpacity(0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(1, 2),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditJournalScreen(existingEntry: entry)),
            );
            if (!mounted) return;
            context.read<JournalBloc>().add(const LoadJournalEntries());
          },
          splashColor: moodColor.withOpacity(0.1),
          highlightColor: moodColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Padding aynı kalabilir
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol Bölüm: Mood İkonu
                if (moodIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: FaIcon(moodIcon, color: moodColor, size: 20),
                  )
                else
                  const SizedBox(width: 20 + 12), // İkon yoksa boşluk bırak

                // Orta Bölüm: Sadece Tarihler (Genişleyebilir)
                Expanded(
                  child: Column( // Column hala yapıyı korumak için kalabilir veya doğrudan Row kullanılabilir
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortalamak için
                    children: [
                      // *** DEĞİŞİKLİK: Önceki başlık/içerik Text widget'ı ve SizedBox kaldırıldı ***

                      // Tarih Bilgileri Alanı (Artık ana içerik)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Oluşturulma Tarihi
                          Icon(Icons.calendar_today_outlined, size: 14, color: iconColor), // Takvim ikonu daha uygun olabilir
                          const SizedBox(width: 4),
                          Text(
                            // Tarih ve saati birleştirelim
                            '${dateFormat.format(entry.createdAt)} ${timeFormat.format(entry.createdAt)}',
                            style: textTheme.bodySmall?.copyWith( // bodySmall biraz daha belirgin olabilir
                              color: colorScheme.onSurface, // Ana metin rengiyle daha okunaklı
                              // fontWeight: FontWeight.w500, // İsteğe bağlı hafif kalınlık
                            ),
                          ),

                          // Güncelleme Tarihi (varsa)
                          if (isUpdated) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.edit_outlined, size: 14, color: iconColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                timeFormat.format(entry.updatedAt), // Sadece saat
                                style: textTheme.bodySmall?.copyWith( // Stil tutarlılığı
                                  color: iconColor, // Biraz daha soluk olabilir
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          // Eğer tarihler sığmazsa diye Row'u Flexible ile sarmalayabiliriz
                          // ancak Expanded Column içinde olduğu için genellikle gerekmez.
                        ],
                      ),
                    ],
                  ),
                ),

                // Sağ Bölüm: Favori Butonu
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(maxWidth: 30, maxHeight: 30),
                    tooltip: entry.isFavorite ? 'Sabitlemeyi kaldır' : 'Sabitle',
                    icon: Icon(
                      entry.isFavorite ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      color: entry.isFavorite ? favoriteColor : iconColor,
                    ),
                    onPressed: () {
                      context.read<JournalBloc>().add(
                        ToggleFavoriteStatus(
                          entryId: entry.id,
                          currentStatus: entry.isFavorite,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// --- Sekme 2: Takvim Widget'ı (Refaktör Edilmiş) ---
  Widget _buildCalendarView(BuildContext context, List<JournalEntry> entries, ThemeData theme, double bottomPadding) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- Stil Tanımlamaları ---
    final headerStyle = HeaderStyle(
      formatButtonVisible: true,
      formatButtonShowsNext: false,
      formatButtonTextStyle: textTheme.labelMedium!.copyWith(color: colorScheme.primary),
      formatButtonDecoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary.withOpacity(0.7)), // Küçük düzeltme: 0.7 -> 0.5 veya isteğe bağlı
        borderRadius: BorderRadius.circular(12.0),
      ),
      titleCentered: true,
      titleTextStyle: textTheme.titleLarge ?? const TextStyle(), // Null check sonrası varsayılan stil
      leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
      rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
    );

    final calendarStyle = CalendarStyle(
      // Bugünün Stili
      todayDecoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary, width: 1.5), // Ana renkle çerçeve
        shape: BoxShape.circle,
      ),
      todayTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),

      // Seçili Gün Stili
      selectedDecoration: BoxDecoration(
        color: colorScheme.primary, // Ana renkle dolgu
        shape: BoxShape.circle,
      ),
      selectedTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold), // Üzerindeki yazı rengi

      // Hafta Sonu Stili
      weekendTextStyle: TextStyle(color: colorScheme.tertiary.withOpacity(0.8)), // Biraz soluk üçüncül renk

      // İşaretçiler (Marker) - Günlük girdisi olduğunu gösteren noktalar
      markersAlignment: Alignment.bottomCenter,
      markersOffset: const PositionedOffset(bottom: 5), // Aşağıdan boşluk
      markerDecoration: BoxDecoration(
        color: colorScheme.secondary, // İkincil renkte nokta
        shape: BoxShape.circle,
      ),
      markersMaxCount: 1, // En fazla 1 nokta göster

      // Diğer
      outsideDaysVisible: false, // Geçerli ay dışındaki günleri gizle
    );
    // --- Stil Tanımlamaları Sonu ---


    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 8.0, right: 8.0, top: 8.0, bottom: bottomPadding,
        ),
        child: TableCalendar<JournalEntry>(
          // Temel Ayarlar
          locale: 'tr_TR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(DateTime.now().year + 5, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,

          // Seçim Mantığı
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          // *** DEĞİŞİKLİK: Yardımcı fonksiyona referans ***
          onDaySelected: _handleDaySelected,

          // Stil Ayarları
          headerStyle: headerStyle,       // Yukarıda tanımlanan değişken
          calendarStyle: calendarStyle,   // Yukarıda tanımlanan değişken

          // Olay Yükleyici (Girdileri işaretlemek için)
          eventLoader: (day) => _getEntriesForDay(day, _lastLoadedEntries),

          // Diğer Callback'ler
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() { _calendarFormat = format; });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            // Sayfa değiştiğinde seçili günü temizlemek isteyebilirsiniz:
            // setState(() { _selectedDay = null; });
          },
        ),
      ),
    );
  }


  // --- Yardımcı Fonksiyon: Gün Seçildiğinde Çalışacak Mantık ---
  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Seçili gün değiştiyse state'i güncelle
    if (!isSameDay(_selectedDay, selectedDay)) {
      // setState çağrısı için mounted kontrolü önemli olabilir,
      // ancak TableCalendar callback'leri genellikle widget ağacındayken çağrılır.
      // Güvenlik için ekleyebilirsiniz: if (!mounted) return;
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // Odaklanılan günü de güncellemek iyi pratiktir
      });
    }

    // Mounted kontrolü (Context veya Bloc kullanmadan önce)
    if (!mounted) return;

    // Seçilen gün için girdileri al
    final entriesForSelectedDay = _getEntriesForDay(selectedDay, _lastLoadedEntries);
    final currentColorScheme = Theme.of(context).colorScheme; // Mevcut context'ten al

    // Girdiler varsa BottomSheet göster, yoksa SnackBar göster
    if (entriesForSelectedDay.isNotEmpty) {
      _showEntriesBottomSheet(context, selectedDay, entriesForSelectedDay);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${DateFormat('dd MMMM', 'tr_TR').format(selectedDay)} için kayıt bulunmuyor.',
            style: TextStyle(color: currentColorScheme.onInverseSurface),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: currentColorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        ),
      );
    }
  }


} // _CalendarPageState sonu