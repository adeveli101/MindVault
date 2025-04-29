// lib/features/journal/bloc/journal_event.dart



part of 'journal_bloc.dart'; // Bloc dosyasına ait olduğunu belirtir



/// JournalBloc tarafından işlenecek olayların temel soyut sınıfı.
abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

// --- Temel CRUD ve Yükleme Olayları ---

/// Tüm günlük girdilerinin yüklenmesini veya güncel listesinin alınmasını tetikler.
/// Genellikle ilk açılışta veya 'pull-to-refresh' gibi eylemlerde kullanılır.
class LoadJournalEntries extends JournalEvent {
  const LoadJournalEntries();
// Props'a bir şey eklemeye gerek yok
}

/// Yeni bir günlük girdisi eklenmesini tetikler.
class AddJournalEntry extends JournalEvent {
  /// Eklenecek yeni günlük girdisi nesnesi.
  final JournalEntry entry;

  const AddJournalEntry(this.entry);

  @override
  List<Object?> get props => [entry];
}

/// Mevcut bir günlük girdisinin güncellenmesini tetikler.
class UpdateJournalEntry extends JournalEvent {
  /// Güncellenmiş verileri içeren JournalEntry nesnesi.
  /// BLoC, bu nesnenin 'id' alanını kullanarak Repository'de güncelleme yapar.
  final JournalEntry entry;

  const UpdateJournalEntry(this.entry);

  @override
  List<Object?> get props => [entry];
}

/// Belirli bir günlük girdisinin silinmesini tetikler.
class DeleteJournalEntry extends JournalEvent {
  /// Silinecek günlük girdisinin benzersiz ID'si.
  final String entryId;

  const DeleteJournalEntry(this.entryId);

  @override
  List<Object?> get props => [entryId];
}


// --- Geleceğe Yönelik ve Ek İşlevsellik Olayları ---

/// Belirli bir ID'ye sahip tek bir günlük girdisinin detaylarını yüklemeyi tetikler.
/// (Örn: Bir liste öğesine tıklandığında detay ekranı için veri çekmek.)
class LoadJournalEntryById extends JournalEvent {
  /// Detayları yüklenecek girdinin ID'si.
  final String entryId;

  const LoadJournalEntryById(this.entryId);

  @override
  List<Object?> get props => [entryId];
}

/// Günlük girdilerini belirli bir kritere göre filtrelemeyi veya aramayı tetikler.
class FilterJournalEntries extends JournalEvent {
  /// Arama sorgusu veya filtreleme kriterleri.
  /// Bu, basit bir String olabileceği gibi daha karmaşık bir filtre nesnesi de olabilir.
  final String query; // Veya `FilterCriteria filter`

  const FilterJournalEntries(this.query); // Veya `this.filter`

  @override
  List<Object?> get props => [query]; // Veya `[filter]`
}

/// Bir günlük girdisinin 'favori' durumunu değiştirmeyi tetikler.
class ToggleFavoriteStatus extends JournalEvent {
  /// Durumu değiştirilecek girdinin ID'si.
  final String entryId;
  /// Girdinin mevcut favori durumu (tersine çevirmek için kullanılır).
  final bool currentStatus;

  const ToggleFavoriteStatus({required this.entryId, required this.currentStatus});

  @override
  List<Object?> get props => [entryId, currentStatus];
}


/// Tüm günlük girdilerini silmeyi tetikler. **DİKKATLİ KULLANILMALI!**
/// Ayarlar ekranında veya özel bir durumda kullanılabilir.
class ClearJournal extends JournalEvent {
  const ClearJournal();
// Parametre yok
}