// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/repository/mindvault_repository.dart';

// Repository, Model, Event ve State dosyalarını import et
// Kendi proje yollarınızı kullandığınızdan emin olun

// Event ve State dosyalarını 'part' olarak dahil etme (eğer o dosyalarda 'part of' kullandıysanız)
part 'journal_event.dart';
part 'journal_state.dart';

/// Journal (Günlük) özelliği için iş mantığını yöneten BLoC.
/// Olayları alır, Repository ile etkileşime girer ve UI için durumları yayınlar.
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  /// Repository'ye erişim için.
  final MindVaultRepository _repository;

  /// Constructor: Gerekli repository'yi alır ve başlangıç durumunu ayarlar.
  /// Olay dinleyicilerini kaydeder.
  JournalBloc({required MindVaultRepository repository})
      : _repository = repository,
        super(const JournalInitial()) { // Başlangıç durumu JournalInitial
    // Olay dinleyicilerini (handler) kaydetme
    on<LoadJournalEntries>(_onLoadJournalEntries);
    on<AddJournalEntry>(_onAddJournalEntry);
    on<UpdateJournalEntry>(_onUpdateJournalEntry);
    on<DeleteJournalEntry>(_onDeleteJournalEntry);

    // Gelecekteki olaylar için handler kayıtları (şimdilik taslak)
    on<LoadJournalEntryById>(_onLoadJournalEntryById);
    on<FilterJournalEntries>(_onFilterJournalEntries);
    on<ToggleFavoriteStatus>(_onToggleFavoriteStatus);
    on<ClearJournal>(_onClearJournal);
  }

  // --- Olay İşleyici Metotları (Event Handlers) ---

  /// `LoadJournalEntries` olayını işler: Tüm girdileri yükler.
  Future<void> _onLoadJournalEntries(
      LoadJournalEntries event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received LoadJournalEntries event.");
    }
    // Yükleme durumunu yayınla
    emit(const JournalLoading(message: "Günlükler yükleniyor..."));
    try {
      // Repository'den tüm girdileri al
      final List<JournalEntry> entries = await _repository.getAllEntries();
      // Başarı durumunu güncel liste ile yayınla
      emit(JournalLoadSuccess(entries));
      if (kDebugMode) {
        print("JournalBloc: Emitted JournalLoadSuccess with ${entries.length} entries.");
      }
    } on MindVaultRepositoryException catch (e) {
      // Repository'den gelen özel hatayı yakala
      if (kDebugMode) {
        print("JournalBloc: Repository Exception during LoadJournalEntries: $e");
      }
      emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      // Beklenmedik diğer hataları yakala
      if (kDebugMode) {
        print("JournalBloc: Unexpected Exception during LoadJournalEntries: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      emit(JournalFailure("Günlükler yüklenirken beklenmedik bir hata oluştu.", error: e as Exception?));
    }
  }

  /// `AddJournalEntry` olayını işler: Yeni bir girdi ekler.
  Future<void> _onAddJournalEntry(
      AddJournalEntry event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received AddJournalEntry event for ID: ${event.entry.id}.");
    }
    // Mevcut durumu koruyarak (eğer liste varsa) veya genel bir yükleme durumu yayınla
    emit(const JournalLoading(message: "Günlük ekleniyor...")); // Veya önceki state'i koru?

    try {
      // Repository'ye ekleme işlemini yaptır
      await _repository.addEntry(event.entry);
      if (kDebugMode) {
        print("JournalBloc: Entry added via repository.");
      }
      // Başarılı ekleme sonrası güncel listeyi yükleyip yayınla
      // Bu, UI'ın hemen güncellenmesini sağlar.
      final List<JournalEntry> updatedEntries = await _repository.getAllEntries();
      emit(JournalLoadSuccess(updatedEntries));
      if (kDebugMode) {
        print("JournalBloc: Emitted JournalLoadSuccess after adding entry.");
      }
      // Alternatif: Önce 'JournalOperationSuccess' sonra 'JournalLoadSuccess' emit edilebilir.
      // emit(const JournalOperationSuccess("Günlük başarıyla eklendi!"));
      // await Future.delayed(Duration(milliseconds: 50)); // Kısa bekleme (opsiyonel)
      // emit(JournalLoadSuccess(updatedEntries));
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) {
        print("JournalBloc: Repository Exception during AddJournalEntry: $e");
      }
      emit(JournalFailure(e.message, error: e));
      // Hata sonrası belki eski listeyi tekrar yayınlamak gerekebilir?
      // Eğer önceki state JournalLoadSuccess ise: if (state is JournalLoadSuccess) emit(state);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("JournalBloc: Unexpected Exception during AddJournalEntry: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      emit(JournalFailure("Günlük eklenirken beklenmedik bir hata oluştu.", error: e as Exception?));
    }
  }

  /// `UpdateJournalEntry` olayını işler: Mevcut bir girdiyi günceller.
  Future<void> _onUpdateJournalEntry(
      UpdateJournalEntry event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received UpdateJournalEntry event for ID: ${event.entry.id}.");
    }
    emit(const JournalLoading(message: "Günlük güncelleniyor..."));

    try {
      // Repository'ye güncelleme işlemini yaptır
      await _repository.updateEntry(event.entry);
      if (kDebugMode) {
        print("JournalBloc: Entry updated via repository.");
      }

      // Başarılı güncelleme sonrası güncel listeyi yükleyip yayınla
      final List<JournalEntry> updatedEntries = await _repository.getAllEntries();
      emit(JournalLoadSuccess(updatedEntries));
      if (kDebugMode) {
        print("JournalBloc: Emitted JournalLoadSuccess after updating entry.");
      }
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) {
        print("JournalBloc: Repository Exception during UpdateJournalEntry: $e");
      }
      emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("JournalBloc: Unexpected Exception during UpdateJournalEntry: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      emit(JournalFailure("Günlük güncellenirken beklenmedik bir hata oluştu.", error: e as Exception?));
    }
  }

  /// `DeleteJournalEntry` olayını işler: Bir girdiyi siler.
  Future<void> _onDeleteJournalEntry(
      DeleteJournalEntry event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received DeleteJournalEntry event for ID: ${event.entryId}.");
    }
    emit(const JournalLoading(message: "Günlük siliniyor..."));

    try {
      // Repository'ye silme işlemini yaptır
      await _repository.deleteEntry(event.entryId);
      if (kDebugMode) {
        print("JournalBloc: Entry deleted via repository.");
      }

      // Başarılı silme sonrası güncel listeyi yükleyip yayınla
      final List<JournalEntry> updatedEntries = await _repository.getAllEntries();
      emit(JournalLoadSuccess(updatedEntries));
      if (kDebugMode) {
        print("JournalBloc: Emitted JournalLoadSuccess after deleting entry.");
      }
      // İsteğe bağlı: Silme sonrası anlık mesaj için JournalOperationSuccess emit edilebilir.
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) {
        print("JournalBloc: Repository Exception during DeleteJournalEntry: $e");
      }
      emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("JournalBloc: Unexpected Exception during DeleteJournalEntry: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      emit(JournalFailure("Günlük silinirken beklenmedik bir hata oluştu.", error: e as Exception?));
    }
  }


  // --- Gelecekteki Olaylar İçin Taslak İşleyiciler ---

  Future<void> _onLoadJournalEntryById(
      LoadJournalEntryById event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received LoadJournalEntryById event for ID: ${event.entryId}.");
    }
    // Bu olay genellikle liste state'ini değiştirmez, belki ayrı bir BLoC veya
    // UI tarafında doğrudan repository çağrısı ile yönetilir.
    // Şimdilik sadece hata durumunu ele alalım veya state'i değiştirmeyelim.
    emit(const JournalLoading(message: "Detaylar yükleniyor...")); // Veya state'i değiştirmeyebiliriz
    try {
      final entry = await _repository.getEntryById(event.entryId);
      if (entry != null) {
        if (kDebugMode) {
          print("JournalBloc: Entry detail loaded for ID: ${event.entryId}.");
        }
        // Başarılı durumu yayınla - Belki yeni bir state tipi?
        // emit(JournalEntryDetailLoadSuccess(entry)); // Eğer böyle bir state tanımladıysak
        // Veya mevcut state'i koru, UI bu veriyi başka yolla alsın.
        // Şimdilik sadece loglayalım ve önceki state'e dönelim (veya başarı state'ine)
        if (state is JournalLoading) { // Eğer hala loading ise başarıya dön
          final currentEntries = await _repository.getAllEntries();
          emit(JournalLoadSuccess(currentEntries));
        }
      } else {
        if (kDebugMode) {
          print("JournalBloc: Entry not found for ID: ${event.entryId}.");
        }
        emit(JournalFailure("Günlük girdisi bulunamadı."));
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("JournalBloc: Exception during LoadJournalEntryById: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      emit(JournalFailure("Günlük detayı yüklenirken hata oluştu.", error: e as Exception?));
    }
  }

  Future<void> _onFilterJournalEntries(
      FilterJournalEntries event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received FilterJournalEntries event with query: ${event.query}.");
    }
    // Filtreleme genellikle mevcut 'JournalLoadSuccess' durumu üzerinden yapılır.
    if (state is JournalLoadSuccess) {
      final currentState = state as JournalLoadSuccess;
      emit(const JournalLoading(message: "Filtreleniyor...")); // İsteğe bağlı
      try {
        // Filtreleme mantığını burada uygula (basit contains örneği)
        final query = event.query.toLowerCase();
        final filteredEntries = currentState.entries.where((entry) {
          return entry.content.toLowerCase().contains(query) ||
              (entry.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false);
        }).toList();

        // Filtrelenmiş sonucu içeren yeni bir state yayınla
        // JournalLoadSuccess state'ini filtre bilgisi içerecek şekilde güncellemek gerekebilir.
        // Şimdilik, sadece filtrelenmiş listeyi içeren yeni bir Success durumu yayınlayalım
        // (Bu, orijinal listeyi kaybedebilir, dikkatli olunmalı!)
        // emit(JournalLoadSuccess(filteredEntries)); // Basit yaklaşım

        // Daha iyi yaklaşım: State'i güncellemek
        emit(JournalLoadSuccess(currentState.entries)); // Filtrelenmiş listeyi ayrı tutabiliriz
        // veya state'e ek alan ekleyebiliriz.
        if (kDebugMode) {
          print("JournalBloc: Filtering completed. (Filtering logic needs refinement in state)");
        }

      } catch (e, stackTrace) {
        if (kDebugMode) {
          print("JournalBloc: Exception during FilterJournalEntries: $e");
        }
        if (kDebugMode) {
          print(stackTrace);
        }
        emit(JournalFailure("Filtreleme sırasında hata oluştu.", error: e as Exception?));
      }

    } else {
      if (kDebugMode) {
        print("JournalBloc: Cannot filter because current state is not JournalLoadSuccess.");
      }
      // Belki hata verilebilir veya sadece event görmezden gelinebilir.
    }
  }

  Future<void> _onToggleFavoriteStatus(
      ToggleFavoriteStatus event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received ToggleFavoriteStatus event for ID: ${event.entryId}.");
    }
    // Yükleme durumu gösterilebilir
    // emit(const JournalLoading(message: "Favori durumu güncelleniyor..."));

    try {
      // 1. Mevcut girdiyi al
      final currentEntry = await _repository.getEntryById(event.entryId);
      if (currentEntry == null) {
        throw MindVaultRepositoryException("Favori durumu değiştirilecek girdi bulunamadı.");
      }

      // 2. Yeni favori durumu ile girdiyi kopyala
      final updatedEntry = currentEntry.copyWith(
        isFavorite: !event.currentStatus, // Durumu tersine çevir
        updatedAt: DateTime.now(), // Güncelleme zamanını ayarla
      );

      // 3. Repository'de güncelle
      await _repository.updateEntry(updatedEntry);
      if (kDebugMode) {
        print("JournalBloc: Toggled favorite status via repository.");
      }

      // 4. Başarı sonrası listeyi yeniden yükle
      final List<JournalEntry> updatedEntries = await _repository.getAllEntries();
      emit(JournalLoadSuccess(updatedEntries));
      if (kDebugMode) {
        print("JournalBloc: Emitted JournalLoadSuccess after toggling favorite.");
      }

    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) {
        print("JournalBloc: Repository Exception during ToggleFavoriteStatus: $e");
      }
      // Önemli: Hata durumunda UI'ın eski haline dönmesi için listeyi tekrar yükleyebiliriz.
      final List<JournalEntry> currentEntries = await _repository.getAllEntries();
      emit(JournalLoadSuccess(currentEntries)); // Veya JournalFailure
      // emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("JournalBloc: Unexpected Exception during ToggleFavoriteStatus: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      emit(JournalFailure("Favori durumu güncellenirken hata oluştu.", error: e as Exception?));
    }
  }

  Future<void> _onClearJournal(
      ClearJournal event,
      Emitter<JournalState> emit,
      ) async {
    if (kDebugMode) {
      print("JournalBloc: Received ClearJournal event.");
    }
    emit(const JournalLoading(message: "Tüm günlükler siliniyor..."));

    try {
      await _repository.deleteAllEntries(); // Repository'deki metodu çağır
      if (kDebugMode) {
        print("JournalBloc: All entries cleared via repository.");
      }
      // Başarı durumunda boş liste ile state'i güncelle
      emit(const JournalLoadSuccess([]));
      if (kDebugMode) {
        print("JournalBloc: Emitted JournalLoadSuccess with empty list after clear.");
      }
    } on MindVaultRepositoryException catch (e) {
      if (kDebugMode) {
        print("JournalBloc: Repository Exception during ClearJournal: $e");
      }
      emit(JournalFailure(e.message, error: e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("JournalBloc: Unexpected Exception during ClearJournal: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      emit(JournalFailure("Günlükler silinirken beklenmedik bir hata oluştu.", error: e as Exception?));
    }
  }
}