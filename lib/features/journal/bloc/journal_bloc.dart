// lib/features/journal/bloc/journal_bloc.dart
// ignore_for_file: unused_local_variable

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/repository/mindvault_repository.dart';

part 'journal_event.dart';
part 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final MindVaultRepository _repository;
  List<JournalEntry> _allEntries = [];

  JournalBloc({required MindVaultRepository repository})
      : _repository = repository,
        super(const JournalInitial()) {
    // Olay dinleyicileri
    on<LoadJournalEntries>(_onLoadJournalEntries);
    on<AddJournalEntry>(_onAddJournalEntry);
    on<UpdateJournalEntry>(_onUpdateJournalEntry);
    on<DeleteJournalEntry>(_onDeleteJournalEntry);
    // Eski filtre olayı kaldırıldı veya isteğe bağlı olarak yeniye yönlendirilebilir
    // on<FilterJournalEntries>(_onFilterJournalEntries);
    on<FilterJournalEntriesByCriteria>(_onFilterJournalEntriesByCriteria); // GÜNCELLENMİŞ olay
    on<ToggleFavoriteStatus>(_onToggleFavoriteStatus);
    on<ClearJournal>(_onClearJournal);
    on<LoadJournalEntryById>(_onLoadJournalEntryById);
  }

  // --- CRUD ve Load Metotları (Filtre Koruması Eklendi/Güncellendi) ---

  Future<void> _onLoadJournalEntries(LoadJournalEntries event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received LoadJournalEntries event."); }
    emit(const JournalLoading(message: "Günlükler yükleniyor..."));
    try {
      _allEntries = await _repository.getAllEntries();
      // Filtre yok (başlangıçta)
      emit(JournalLoadSuccess(_allEntries));
      if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess with ${_allEntries.length} entries."); }
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) { print("JournalBloc: Load Repo Exception: $e"); }
      emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) { print("JournalBloc: Load Exception: $e\n$stackTrace"); }
      emit(JournalFailure("Günlükler yüklenirken hata.", error: e as Exception?));
    }
  }

  Future<void> _onAddJournalEntry(AddJournalEntry event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received AddJournalEntry event."); }
    final previousState = state;
    try {
      await _repository.addEntry(event.entry);
      _allEntries = await _repository.getAllEntries();
      // Ekleme sonrası filtreler sıfırlanır
      emit(JournalLoadSuccess(_allEntries));
      if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after adding."); }
    } catch (e, stackTrace) { // Hata yönetimi (önceki gibi)
      if (kDebugMode) { print("JournalBloc: Add Exception: $e\n$stackTrace"); }
      if (previousState is JournalLoadSuccess) emit(previousState);
      emit(JournalFailure("Ekleme hatası: ${e.toString()}", error: e as Exception?));
    }
  }

  Future<void> _onUpdateJournalEntry(UpdateJournalEntry event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received UpdateJournalEntry event."); }
    final previousState = state;
    try {
      await _repository.updateEntry(event.entry);
      _allEntries = await _repository.getAllEntries();
      // Güncelleme sonrası filtreleri koru
      _emitFilteredStateIfNeeded(previousState, emit);
      if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after updating (filters preserved)."); }
    } catch (e, stackTrace) { // Hata yönetimi (önceki gibi)
      if (kDebugMode) { print("JournalBloc: Update Exception: $e\n$stackTrace"); }
      if (previousState is JournalLoadSuccess) emit(previousState);
      emit(JournalFailure("Güncelleme hatası: ${e.toString()}", error: e as Exception?));
    }
  }

  Future<void> _onDeleteJournalEntry(DeleteJournalEntry event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received DeleteJournalEntry event."); }
    final previousState = state;
    try {
      await _repository.deleteEntry(event.entryId);
      _allEntries = await _repository.getAllEntries();
      // Silme sonrası filtreleri koru
      _emitFilteredStateIfNeeded(previousState, emit);
      if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after deleting (filters preserved)."); }
    } catch (e, stackTrace) { // Hata yönetimi (önceki gibi)
      if (kDebugMode) { print("JournalBloc: Delete Exception: $e\n$stackTrace"); }
      if (previousState is JournalLoadSuccess) emit(previousState);
      emit(JournalFailure("Silme hatası: ${e.toString()}", error: e as Exception?));
    }
  }

  Future<void> _onToggleFavoriteStatus(ToggleFavoriteStatus event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received ToggleFavoriteStatus event."); }
    final previousState = state;
    try {
      final entry = await _repository.getEntryById(event.entryId);
      if (entry != null) {
        await _repository.updateEntry(entry.copyWith(isFavorite: !event.currentStatus, updatedAt: DateTime.now()));
        _allEntries = await _repository.getAllEntries();
        // Favori değiştirme sonrası filtreleri koru
        _emitFilteredStateIfNeeded(previousState, emit);
        if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after toggle favorite (filters preserved)."); }
      } else { /* Girdi bulunamadı durumu */ }
    } catch (e, stackTrace) { // Hata yönetimi (önceki gibi)
      if (kDebugMode) { print("JournalBloc: ToggleFav Exception: $e\n$stackTrace"); }
      if (previousState is JournalLoadSuccess) emit(previousState);
      emit(JournalFailure("Favori değiştirme hatası: ${e.toString()}", error: e as Exception?));
    }
  }

  Future<void> _onClearJournal(ClearJournal event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received ClearJournal event."); }
    emit(const JournalLoading(message: "Tüm günlükler siliniyor..."));
    try {
      await _repository.deleteAllEntries();
      _allEntries = [];
      // Temizleme sonrası filtreler de temizlenir
      emit(JournalLoadSuccess(_allEntries));
      if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after clear."); }
    } catch (e, stackTrace) { // Hata yönetimi (önceki gibi)
      if (kDebugMode) { print("JournalBloc: Clear Exception: $e\n$stackTrace"); }
      emit(JournalFailure("Temizleme hatası: ${e.toString()}", error: e as Exception?));
      emit(JournalLoadSuccess(_allEntries)); // Boş liste ile emit
    }
  }


  // --- Filtreleme İşleyicisi (GÜNCELLENDİ) ---

  /// Kriterlere göre filtreleme (Metin ve/veya Mood Listesi)
  Future<void> _onFilterJournalEntriesByCriteria(
      FilterJournalEntriesByCriteria event,
      Emitter<JournalState> emit,
      ) async {

    final query = event.query?.trim();       // Metin sorgusu
    final moods = event.moods; // Ruh hali listesi

    if (kDebugMode) { print("JournalBloc: Filtering by Criteria - Query: '$query', Moods: ${moods?.map((m) => m.name).toList()}"); }

    // Başarılı yükleme state'i veya başlangıç state'i kontrolü
    if (state is JournalLoadSuccess || state is JournalInitial) {

      // Eğer _allEntries boşsa (ilk filtreleme veya hata sonrası), veriyi yükle
      if (_allEntries.isEmpty && state is! JournalLoading) {
        if (kDebugMode) { print("JournalBloc: _allEntries is empty, loading first for filtering..."); }
        await _onLoadJournalEntries(const LoadJournalEntries(), emit);
        final currentStateAfterLoad = state;
        if (currentStateAfterLoad is! JournalLoadSuccess) {
          if (kDebugMode) { print("JournalBloc: Failed to load entries before filtering."); }
          return; // Yükleme başarısızsa devam etme
        }
      }

      // Filtreleme mantığı
      try {
        final bool noTextQuery = query == null || query.isEmpty;
        final bool noMoodFilter = moods == null || moods.isEmpty; // Liste boşsa filtre yok

        // Mevcut state'in filtre durumunu al (varsa)
        bool currentlyFiltered = false;
        if(state is JournalLoadSuccess){
          currentlyFiltered = (state as JournalLoadSuccess).isFiltered;
        }

        if (noTextQuery && noMoodFilter) {
          // Uygulanacak filtre yoksa ve şu an filtreliyse, filtreyi kaldır
          if (currentlyFiltered) {
            if (kDebugMode) { print("JournalBloc: Clearing all filters."); }
            emit(JournalLoadSuccess(_allEntries)); // Filtresiz state
          } else {
            if (kDebugMode) { print("JournalBloc: No filters to apply or clear."); }
            // Zaten filtresizse tekrar emit etmeye gerek yok
          }
        } else {
          // Uygulanacak en az bir filtre varsa
          if (kDebugMode) { print("JournalBloc: Applying filters..."); }
          final filtered = _filterEntries(_allEntries, query: query, moods: moods); // GÜNCELLENMİŞ filtreleme metodu
          emit(JournalLoadSuccess(
            _allEntries, // Ana liste her zaman tam
            filteredEntries: filtered,
            currentFilterQuery: query, // Null olabilir
            currentMoodFilters: moods, // Null veya boş olabilir
          ));
          if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess with ${filtered.length} filtered entries."); }
        }
      } catch (e, stackTrace) {
        if (kDebugMode) { print("JournalBloc: Exception during FilterByCriteria: $e\n$stackTrace"); }
        emit(JournalLoadSuccess(_allEntries)); // Hata durumunda filtreyi temizle
        emit(JournalFailure("Filtreleme hatası.", error: e as Exception?));
      }

    } else {
      // Yükleme sırasında veya hata durumunda filtreleme yapma
      if (kDebugMode) { print("JournalBloc: Cannot filter in current state: $state"); }
    }
  }

  /// Mevcut filtreleri koruyarak state'i yeniden emit etme yardımcısı.
  void _emitFilteredStateIfNeeded(JournalState previousState, Emitter<JournalState> emit) {
    String? currentQuery;
    List<Mood>? currentMoods; // Liste olarak al
    // Önceki state'ten filtreleri al (varsa)
    if (previousState is JournalLoadSuccess) {
      currentQuery = previousState.currentFilterQuery;
      currentMoods = previousState.currentMoodFilters; // Listeyi al
    }

    // Eğer filtre varsa, filtrelenmiş listeyi _allEntries'in güncel haliyle yeniden hesapla
    List<JournalEntry>? updatedFilteredEntries;
    if ((currentQuery != null && currentQuery.isNotEmpty) || (currentMoods != null && currentMoods.isNotEmpty)) {
      updatedFilteredEntries = _filterEntries(_allEntries, query: currentQuery, moods: currentMoods); // Listeyi gönder
    }

    // Yeni state'i emit et
    emit(JournalLoadSuccess(
        _allEntries,
        filteredEntries: updatedFilteredEntries,
        currentFilterQuery: currentQuery,
        currentMoodFilters: currentMoods // Listeyi state'e yaz
    ));
  }


  /// GÜNCELLENMİŞ: Hem metin hem de mood listesine göre filtreleme yapan yardımcı metot.
  List<JournalEntry> _filterEntries(List<JournalEntry> entries, {String? query, List<Mood>? moods}) {
    final String lowerCaseQuery = query?.toLowerCase() ?? '';
    final bool hasTextQuery = lowerCaseQuery.isNotEmpty;
    final bool hasMoodFilter = moods != null && moods.isNotEmpty; // Liste null değil ve boş değilse filtre var

    // Eğer uygulanacak filtre yoksa tüm listeyi döndür
    if (!hasTextQuery && !hasMoodFilter) {
      return entries;
    }

    // Set<Mood> oluşturmak aramayı hızlandırabilir (eğer liste büyükse)
    final Set<Mood>? moodFilterSet = hasMoodFilter ? Set.from(moods) : null;

    return entries.where((entry) {
      // Metin kontrolü (eğer metin sorgusu varsa)
      bool textMatch = !hasTextQuery; // Metin sorgusu yoksa, varsayılan olarak eşleşir
      if (hasTextQuery) {
        final contentMatch = entry.content.toLowerCase().contains(lowerCaseQuery);
        final titleMatch = entry.title?.toLowerCase().contains(lowerCaseQuery) ?? false;
        final tagMatch = entry.tags?.any((tag) => tag.toLowerCase().contains(lowerCaseQuery)) ?? false;
        textMatch = contentMatch || titleMatch || tagMatch;
      }

      // Ruh hali kontrolü (eğer ruh hali filtresi varsa)
      bool moodMatch = !hasMoodFilter; // Mood filtresi yoksa, varsayılan olarak eşleşir
      if (hasMoodFilter) {
        // Girdinin mood'u null olamaz ve seçilen mood'lardan biri olmalı
        moodMatch = entry.mood != null && moodFilterSet!.contains(entry.mood);
      }

      // Girdinin geçmesi için HER İKİ aktif filtrenin de sağlanması gerekir
      return textMatch && moodMatch;
    }).toList();
  }

  // _onLoadJournalEntryById aynı kalabilir.
  Future<void> _onLoadJournalEntryById(LoadJournalEntryById event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received LoadJournalEntryById (No state change)."); }
  }
}