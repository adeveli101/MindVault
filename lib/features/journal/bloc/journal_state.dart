// lib/features/journal/bloc/journal_state.dart

part of 'journal_bloc.dart';

abstract class JournalState extends Equatable {
  const JournalState();
  @override List<Object?> get props => [];
}

// --- Temel Durumlar ---
class JournalInitial extends JournalState { const JournalInitial(); }
class JournalLoading extends JournalState { final String? message; const JournalLoading({this.message}); @override List<Object?> get props => [message]; }
class JournalFailure extends JournalState { final String errorMessage; final Exception? error; const JournalFailure(this.errorMessage, {this.error}); @override List<Object?> get props => [errorMessage, error]; }

// --- Başarılı Yükleme (Ana Liste ve Filtreleme) ---
class JournalLoadSuccess extends JournalState {
  final List<JournalEntry> entries;
  final List<JournalEntry>? filteredEntries;
  final String? currentFilterQuery;
  final List<Mood>? currentMoodFilters;

  const JournalLoadSuccess(this.entries, { this.filteredEntries, this.currentFilterQuery, this.currentMoodFilters });

  @override List<Object?> get props => [ entries, filteredEntries, currentFilterQuery, currentMoodFilters ];
  bool get isFiltered => (currentFilterQuery != null && currentFilterQuery!.isNotEmpty) || (currentMoodFilters != null && currentMoodFilters!.isNotEmpty);
  bool get isTextFiltered => currentFilterQuery != null && currentFilterQuery!.isNotEmpty;
  bool get isMoodFiltered => currentMoodFilters != null && currentMoodFilters!.isNotEmpty;
  JournalEntry? entryById(String id) { try { return entries.firstWhere((e) => e.id == id); } catch (_) { return null; } }
}

// --- YENİ ETİKET STATE'LERİ ---

/// Tüm benzersiz etiketlerin başarıyla yüklendiği durum.
class JournalTagsLoadSuccess extends JournalState {
  final List<String> tags;
  const JournalTagsLoadSuccess(this.tags);
  @override List<Object?> get props => [tags];
}

/// Belirli bir etikete göre girdilerin başarıyla yüklendiği durum.
/// Bu state, `JournalLoadSuccess`'a benzer ancak özel bir durumu temsil eder.
/// Alternatif olarak `JournalLoadSuccess`'a bir `activeTagFilter` alanı eklenebilir.
class JournalEntriesByTagLoadSuccess extends JournalState {
  final String tag; // Hangi etiket için yüklendiği bilgisi
  final List<JournalEntry> entries; // O etikete ait girdiler
  const JournalEntriesByTagLoadSuccess(this.tag, this.entries);
  @override List<Object?> get props => [tag, entries];
}
// --- ETİKET STATE'LERİ SONU ---