// lib/features/journal/bloc/journal_state.dart

part of 'journal_bloc.dart';

abstract class JournalState extends Equatable {
  const JournalState();
  @override List<Object?> get props => [];
}

class JournalInitial extends JournalState { const JournalInitial(); }

class JournalLoading extends JournalState {
  final String? message;
  const JournalLoading({this.message});
  @override List<Object?> get props => [message];
}

class JournalLoadSuccess extends JournalState {
  /// Tüm günlük girdilerinin tam listesi.
  final List<JournalEntry> entries;

  // --- Filtreleme Alanları ---
  /// Filtrelenmiş sonuçlar (filtre aktifse).
  final List<JournalEntry>? filteredEntries;
  /// Aktif metin sorgusu (varsa).
  final String? currentFilterQuery;
  /// YENİ: Aktif ruh hali filtreleri listesi (varsa).
  final List<Mood>? currentMoodFilters; // Çoğul yapıldı
  // --- Filtreleme Alanları Sonu ---

  // Constructor güncellendi
  const JournalLoadSuccess(
      this.entries, {
        this.filteredEntries,
        this.currentFilterQuery,
        this.currentMoodFilters, // Çoğul parametre
      });

  // props güncellendi
  @override
  List<Object?> get props => [
    entries,
    filteredEntries,
    currentFilterQuery,
    currentMoodFilters, // Çoğul prop
  ];

  // Kolaylık metodu: Belirli bir ID'ye sahip girdiyi bulma
  JournalEntry? entryById(String id) {
    try { return entries.firstWhere((entry) => entry.id == id); }
    catch (e) { return null; }
  }

  // Kolaylık özelliği: Şu anda herhangi bir filtre aktif mi?
  bool get isFiltered =>
      (currentFilterQuery != null && currentFilterQuery!.isNotEmpty) ||
          (currentMoodFilters != null && currentMoodFilters!.isNotEmpty); // Liste kontrolü

  // Kolaylık özelliği: Sadece metin filtresi mi aktif?
  bool get isTextFiltered => currentFilterQuery != null && currentFilterQuery!.isNotEmpty;

  // Kolaylık özelliği: Sadece mood filtresi mi aktif?
  bool get isMoodFiltered => currentMoodFilters != null && currentMoodFilters!.isNotEmpty; // Liste kontrolü
}

class JournalFailure extends JournalState {
  final String errorMessage;
  final Exception? error;
  const JournalFailure(this.errorMessage, {this.error});
  @override List<Object?> get props => [errorMessage, error];
}