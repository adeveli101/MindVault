// lib/features/journal/bloc/journal_event.dart

part of 'journal_bloc.dart';

abstract class JournalEvent extends Equatable {
  const JournalEvent();
  @override List<Object?> get props => [];
}

// --- Temel CRUD ve Yükleme ---
class LoadJournalEntries extends JournalEvent { const LoadJournalEntries(); }
class AddJournalEntry extends JournalEvent { final JournalEntry entry; const AddJournalEntry(this.entry); @override List<Object?> get props => [entry]; }
class UpdateJournalEntry extends JournalEvent { final JournalEntry entry; const UpdateJournalEntry(this.entry); @override List<Object?> get props => [entry]; }
class DeleteJournalEntry extends JournalEvent { final String entryId; const DeleteJournalEntry(this.entryId); @override List<Object?> get props => [entryId]; }

// --- Filtreleme ---
class FilterJournalEntriesByCriteria extends JournalEvent {
  final String? query;
  final List<Mood>? moods;
  const FilterJournalEntriesByCriteria({this.query, this.moods});
  @override List<Object?> get props => [query, moods];
}

// --- Diğer Olaylar ---
class LoadJournalEntryById extends JournalEvent { final String entryId; const LoadJournalEntryById(this.entryId); @override List<Object?> get props => [entryId]; }
class ToggleFavoriteStatus extends JournalEvent { final String entryId; final bool currentStatus; const ToggleFavoriteStatus({required this.entryId, required this.currentStatus}); @override List<Object?> get props => [entryId, currentStatus]; }
class ClearJournal extends JournalEvent { const ClearJournal(); }

// --- YENİ ETİKET OLAYLARI ---
/// Tüm benzersiz etiketlerin yüklenmesini tetikler.
class LoadAllTags extends JournalEvent { const LoadAllTags(); }

/// Belirli bir etikete sahip günlük girdilerinin yüklenmesini tetikler.
class LoadEntriesByTag extends JournalEvent {
  final String tag;
  const LoadEntriesByTag(this.tag);
  @override List<Object?> get props => [tag];
}
// --- ETİKET OLAYLARI SONU ---