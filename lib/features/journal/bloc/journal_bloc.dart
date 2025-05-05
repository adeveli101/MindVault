// lib/features/journal/bloc/journal_bloc.dart
// Etiket yönetimi (kaydetme ve yükleme olayları/handlerları) eklendi.

// ignore_for_file: unused_local_variable

import 'dart:async';
import 'package:bloc/bloc.dart';
// listEquals için (opsiyonel)
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
    on<AddJournalEntry>(_onAddJournalEntry);       // Etiket kaydetme mantığı içerir
    on<UpdateJournalEntry>(_onUpdateJournalEntry); // Etiket kaydetme mantığı içerir
    on<DeleteJournalEntry>(_onDeleteJournalEntry);
    on<FilterJournalEntriesByCriteria>(_onFilterJournalEntriesByCriteria);
    on<ToggleFavoriteStatus>(_onToggleFavoriteStatus);
    on<ClearJournal>(_onClearJournal);
    on<LoadJournalEntryById>(_onLoadJournalEntryById);
    // YENİ ETİKET HANDLER'LARI
    on<LoadAllTags>(_onLoadAllTags);
    on<LoadEntriesByTag>(_onLoadEntriesByTag);
  }

  // --- CRUD ve Load Metotları (Etiketler Dahil Edildi) ---

  Future<void> _onLoadJournalEntries(LoadJournalEntries event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received LoadJournalEntries event."); }
    emit(const JournalLoading(message: "Günlükler yükleniyor..."));
    try {
      _allEntries = await _repository.getAllEntries();
      // Başlangıçta filtre yok, normal success state emit et
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
    // Event içinde gelen entry'nin tags alanı UI'dan alınmış olmalı.
    if (kDebugMode) { print("JournalBloc: Received AddJournalEntry event with tags: ${event.entry.tags}"); }
    final previousState = state;
    try {
      // Gelen entry'yi doğrudan repoya gönder (tags dahil)
      await _repository.addEntry(event.entry);
      _allEntries = await _repository.getAllEntries(); // Listeyi güncelle
      // Ekleme sonrası filtreler sıfırlanır
      emit(JournalLoadSuccess(_allEntries));
      if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after adding."); }
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) { print("JournalBloc: Add Repo Exception: $e"); }
      if (previousState is JournalLoadSuccess) emit(previousState); // Eski state'i geri yükle
      emit(JournalFailure("Ekleme hatası: ${e.toString()}", error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) { print("JournalBloc: Add Exception: $e\n$stackTrace"); }
      if (previousState is JournalLoadSuccess) emit(previousState);
      emit(JournalFailure("Ekleme hatası: ${e.toString()}", error: e as Exception?));
    }
  }

  Future<void> _onUpdateJournalEntry(UpdateJournalEntry event, Emitter<JournalState> emit) async {
    // Event içinde gelen entry'nin tags alanı UI'dan alınmış olmalı.
    if (kDebugMode) { print("JournalBloc: Received UpdateJournalEntry event with tags: ${event.entry.tags}"); }
    final previousState = state;
    try {
      // Gelen entry'yi doğrudan repoya gönder (tags dahil)
      await _repository.updateEntry(event.entry);
      _allEntries = await _repository.getAllEntries(); // Listeyi güncelle
      // Güncelleme sonrası filtreleri koru
      _emitFilteredStateIfNeeded(previousState, emit);
      if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after updating (filters preserved)."); }
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) { print("JournalBloc: Update Repo Exception: $e"); }
      if (previousState is JournalLoadSuccess) emit(previousState);
      emit(JournalFailure("Güncelleme hatası: ${e.toString()}", error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) { print("JournalBloc: Update Exception: $e\n$stackTrace"); }
      if (previousState is JournalLoadSuccess) emit(previousState);
      emit(JournalFailure("Güncelleme hatası: ${e.toString()}", error: e as Exception?));
    }
  }

  // DeleteJournalEntry, ToggleFavoriteStatus, ClearJournal metotları filtre koruma mantığıyla aynı kalır.
  Future<void> _onDeleteJournalEntry(DeleteJournalEntry event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received DeleteJournalEntry event."); }
    final previousState = state;
    try { await _repository.deleteEntry(event.entryId); _allEntries = await _repository.getAllEntries(); _emitFilteredStateIfNeeded(previousState, emit); if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after deleting (filters preserved)."); } }
    catch (e, stackTrace) { if (kDebugMode) { print("JournalBloc: Delete Exception: $e\n$stackTrace"); } if (previousState is JournalLoadSuccess) emit(previousState); emit(JournalFailure("Silme hatası: ${e.toString()}", error: e as Exception?)); }
  }
  Future<void> _onToggleFavoriteStatus(ToggleFavoriteStatus event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received ToggleFavoriteStatus event."); }
    final previousState = state;
    try { final entry = await _repository.getEntryById(event.entryId); if (entry != null) { await _repository.updateEntry(entry.copyWith(isFavorite: !event.currentStatus, updatedAt: DateTime.now())); _allEntries = await _repository.getAllEntries(); _emitFilteredStateIfNeeded(previousState, emit); if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after toggle favorite (filters preserved)."); } } else { /* Girdi bulunamadı */ if (previousState is JournalLoadSuccess) emit(previousState); } }
    catch (e, stackTrace) { if (kDebugMode) { print("JournalBloc: ToggleFav Exception: $e\n$stackTrace"); } if (previousState is JournalLoadSuccess) emit(previousState); emit(JournalFailure("Favori değiştirme hatası: ${e.toString()}", error: e as Exception?)); }
  }
  Future<void> _onClearJournal(ClearJournal event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received ClearJournal event."); }
    emit(const JournalLoading(message: "Tüm günlükler siliniyor..."));
    try { await _repository.deleteAllEntries(); _allEntries = []; emit(JournalLoadSuccess(_allEntries)); if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess after clear."); } }
    catch (e, stackTrace) { if (kDebugMode) { print("JournalBloc: Clear Exception: $e\n$stackTrace"); } emit(JournalFailure("Temizleme hatası: ${e.toString()}", error: e as Exception?)); emit(JournalLoadSuccess(_allEntries)); }
  }

  // --- Filtreleme İşleyicisi ---
  Future<void> _onFilterJournalEntriesByCriteria(FilterJournalEntriesByCriteria event, Emitter<JournalState> emit) async {
    final query = event.query?.trim(); final moods = event.moods;
    if (kDebugMode) { print("JournalBloc: Filtering by Criteria - Query: '$query', Moods: ${moods?.map((m) => m.name).toList()}"); }
    if (state is JournalLoadSuccess || state is JournalInitial) {
      if (_allEntries.isEmpty && state is! JournalLoading) { if (kDebugMode) { print("JournalBloc: _allEntries is empty, loading first..."); } await _onLoadJournalEntries(const LoadJournalEntries(), emit); final currentStateAfterLoad = state; if (currentStateAfterLoad is! JournalLoadSuccess) { if (kDebugMode) { print("JournalBloc: Failed to load entries before filtering."); } return; } }
      try { final bool noTextQuery = query == null || query.isEmpty; final bool noMoodFilter = moods == null || moods.isEmpty; bool currentlyFiltered = false; if(state is JournalLoadSuccess){ currentlyFiltered = (state as JournalLoadSuccess).isFiltered; } if (noTextQuery && noMoodFilter) { if (currentlyFiltered) { if (kDebugMode) { print("JournalBloc: Clearing all filters."); } emit(JournalLoadSuccess(_allEntries)); } else { if (kDebugMode) { print("JournalBloc: No filters to apply or clear."); } } } else { if (kDebugMode) { print("JournalBloc: Applying filters..."); } final filtered = _filterEntries(_allEntries, query: query, moods: moods); emit(JournalLoadSuccess(_allEntries, filteredEntries: filtered, currentFilterQuery: query, currentMoodFilters: moods)); if (kDebugMode) { print("JournalBloc: Emitted JournalLoadSuccess with ${filtered.length} filtered entries."); } } }
      catch (e, stackTrace) { if (kDebugMode) { print("JournalBloc: Exception during FilterByCriteria: $e\n$stackTrace"); } emit(JournalLoadSuccess(_allEntries)); emit(JournalFailure("Filtreleme hatası.", error: e as Exception?)); }
    } else { if (kDebugMode) { print("JournalBloc: Cannot filter in current state: $state"); } }
  }

  // --- YENİ ETİKET HANDLER'LARI ---

  /// Tüm benzersiz etiketleri yükler.
  Future<void> _onLoadAllTags(LoadAllTags event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received LoadAllTags event."); }
    // Yükleme durumu opsiyonel
    // emit(const JournalLoading(message: "Etiketler yükleniyor..."));
    try {
      final tags = await _repository.getAllUniqueTags();
      emit(JournalTagsLoadSuccess(tags)); // Yeni state
      if (kDebugMode) { print("JournalBloc: Emitted JournalTagsLoadSuccess with ${tags.length} tags."); }
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) { print("JournalBloc: Repository Exception during LoadAllTags: $e"); }
      emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) { print("JournalBloc: Unexpected Exception during LoadAllTags: $e\n$stackTrace"); }
      emit(JournalFailure("Etiketler yüklenirken hata oluştu.", error: e as Exception?));
    }
  }

  /// Belirli bir etikete göre girdileri yükler.
  Future<void> _onLoadEntriesByTag(LoadEntriesByTag event, Emitter<JournalState> emit) async {
    final tag = event.tag;
    if (kDebugMode) { print("JournalBloc: Received LoadEntriesByTag event for tag: '$tag'."); }
    emit(JournalLoading(message: "'$tag' etiketli girdiler yükleniyor..."));
    try {
      final entries = await _repository.getEntriesByTag(tag);
      emit(JournalEntriesByTagLoadSuccess(tag, entries)); // Yeni state
      if (kDebugMode) { print("JournalBloc: Emitted JournalEntriesByTagLoadSuccess with ${entries.length} entries for tag '$tag'."); }
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) { print("JournalBloc: Repository Exception during LoadEntriesByTag: $e"); }
      emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) { print("JournalBloc: Unexpected Exception during LoadEntriesByTag: $e\n$stackTrace"); }
      emit(JournalFailure("'$tag' etiketli girdiler yüklenirken hata oluştu.", error: e as Exception?));
    }
  }
  // --- ETİKET HANDLER'LARI SONU ---


  // --- Yardımcı Metotlar ---

  /// Mevcut filtreleri koruyarak state'i yeniden emit eder.
  void _emitFilteredStateIfNeeded(JournalState previousState, Emitter<JournalState> emit) {
    String? currentQuery;
    List<Mood>? currentMoods; // Liste olarak al
    if (previousState is JournalLoadSuccess) {
      currentQuery = previousState.currentFilterQuery;
      currentMoods = previousState.currentMoodFilters; // Listeyi al
    }
    List<JournalEntry>? updatedFilteredEntries;
    if ((currentQuery != null && currentQuery.isNotEmpty) || (currentMoods != null && currentMoods.isNotEmpty)) {
      updatedFilteredEntries = _filterEntries(_allEntries, query: currentQuery, moods: currentMoods); // Listeyi gönder
    }
    emit(JournalLoadSuccess( _allEntries, filteredEntries: updatedFilteredEntries, currentFilterQuery: currentQuery, currentMoodFilters: currentMoods ));
  }

  /// Hem metin hem de mood listesine göre filtreleme yapar.
  List<JournalEntry> _filterEntries(List<JournalEntry> entries, {String? query, List<Mood>? moods}) {
    final String lowerCaseQuery = query?.toLowerCase() ?? '';
    final bool hasTextQuery = lowerCaseQuery.isNotEmpty;
    final bool hasMoodFilter = moods != null && moods.isNotEmpty;

    if (!hasTextQuery && !hasMoodFilter) { return entries; }

    final Set<Mood>? moodFilterSet = hasMoodFilter ? Set.from(moods) : null;

    return entries.where((entry) {
      bool textMatch = !hasTextQuery;
      if (hasTextQuery) {
        final contentMatch = entry.content.toLowerCase().contains(lowerCaseQuery);
        final titleMatch = entry.title?.toLowerCase().contains(lowerCaseQuery) ?? false;
        final tagMatch = entry.tags?.any((tag) => tag.toLowerCase().contains(lowerCaseQuery)) ?? false;
        textMatch = contentMatch || titleMatch || tagMatch;
      }
      bool moodMatch = !hasMoodFilter;
      if (hasMoodFilter) {
        moodMatch = entry.mood != null && moodFilterSet!.contains(entry.mood);
      }
      return textMatch && moodMatch;
    }).toList();
  }

  /// Detay yükleme olayı (liste state'ini etkilemez).
  Future<void> _onLoadJournalEntryById(LoadJournalEntryById event, Emitter<JournalState> emit) async {
    if (kDebugMode) { print("JournalBloc: Received LoadJournalEntryById (No state change)."); }
  }

} // JournalBloc sınıfı sonu