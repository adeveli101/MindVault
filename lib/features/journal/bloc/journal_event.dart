// lib/features/journal/bloc/journal_event.dart

part of 'journal_bloc.dart'; // Bloc dosyasına ait olduğunu belirtir

/// JournalBloc tarafından işlenecek olayların temel soyut sınıfı.
abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

// --- Temel CRUD ve Yükleme Olayları ---
class LoadJournalEntries extends JournalEvent { const LoadJournalEntries(); }
class AddJournalEntry extends JournalEvent { final JournalEntry entry; const AddJournalEntry(this.entry); @override List<Object?> get props => [entry]; }
class UpdateJournalEntry extends JournalEvent { final JournalEntry entry; const UpdateJournalEntry(this.entry); @override List<Object?> get props => [entry]; }
class DeleteJournalEntry extends JournalEvent { final String entryId; const DeleteJournalEntry(this.entryId); @override List<Object?> get props => [entryId]; }

// --- Filtreleme Olayı (GÜNCELLENDİ) ---
class FilterJournalEntriesByCriteria extends JournalEvent {
  final String? query;       // Metin sorgusu (opsiyonel)
  final List<Mood>? moods; // Seçilen ruh halleri listesi (opsiyonel, null veya boş ise filtre yok)

  // Hem query hem de moods null/boş ise tüm filtreler kaldırılır.
  const FilterJournalEntriesByCriteria({this.query, this.moods});

  @override
  List<Object?> get props => [query, moods];
}

// --- Diğer Olaylar ---
class LoadJournalEntryById extends JournalEvent { final String entryId; const LoadJournalEntryById(this.entryId); @override List<Object?> get props => [entryId]; }
class ToggleFavoriteStatus extends JournalEvent { final String entryId; final bool currentStatus; const ToggleFavoriteStatus({required this.entryId, required this.currentStatus}); @override List<Object?> get props => [entryId, currentStatus]; }
class ClearJournal extends JournalEvent { const ClearJournal(); }

// Eski FilterJournalEntries olayı kaldırıldı veya isteğe bağlı olarak tutulabilir.
// class FilterJournalEntries extends JournalEvent { ... }