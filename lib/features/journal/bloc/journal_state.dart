// lib/features/journal/bloc/journal_state.dart

part of 'journal_bloc.dart'; // Bloc dosyasına ait olduğunu belirtir

/// JournalBloc'un durumunu temsil eden temel soyut sınıf.
/// Durumlar arasında geçişi ve UI'ın buna göre güncellenmesini sağlar.
abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

// --- Temel Durumlar ---

/// Bloc'un başlangıç durumu. Henüz hiçbir işlem yapılmadı veya veri yüklenmedi.
class JournalInitial extends JournalState {
  const JournalInitial();
}

/// Bir işlemin (veri yükleme, ekleme, silme vb.) aktif olarak devam ettiğini gösterir.
/// UI bu durumda bir yükleme göstergesi (örn: CircularProgressIndicator) gösterebilir.
class JournalLoading extends JournalState {
  /// İsteğe bağlı: Yükleme sırasında kullanıcıya gösterilebilecek bir mesaj.
  /// Örn: "Günlükler yükleniyor...", "Girdi siliniyor..."
  final String? message;

  const JournalLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Günlük girdilerinin başarıyla yüklendiği veya güncellendiği durumu temsil eder.
class JournalLoadSuccess extends JournalState {
  /// Yüklenen veya güncellenen günlük girdilerinin tam listesi.
  final List<JournalEntry> entries;

  // Gelecekte filtreleme/arama eklenirse:
  // final List<JournalEntry> filteredEntries; // Filtrelenmiş liste
  // final String? currentFilterQuery; // Aktif filtre sorgusu

  const JournalLoadSuccess(this.entries);
  // Gelecekte: const JournalLoadSuccess(this.entries, {this.filteredEntries, this.currentFilterQuery});

  @override
  List<Object?> get props => [entries];
  // Gelecekte: @override List<Object?> get props => [entries, filteredEntries, currentFilterQuery];

  // Kolaylık metodu: Belirli bir ID'ye sahip girdiyi bulma
  JournalEntry? entryById(String id) {
    try {
      return entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null; // Bulunamadı
    }
  }
}

/// Herhangi bir işlem sırasında (yükleme, ekleme, silme vb.) bir hata oluştuğunu gösterir.
class JournalFailure extends JournalState {
  /// Oluşan hatayı açıklayan mesaj veya hatanın kendisi.
  /// UI bu durumda bir hata mesajı veya 'tekrar dene' butonu gösterebilir.
  final String errorMessage;
  final Exception? error; // Orijinal hatayı saklamak isteyebilirsiniz

  const JournalFailure(this.errorMessage, {this.error});

  @override
  List<Object?> get props => [errorMessage, error];
}


// --- İsteğe Bağlı Detaylı Durumlar (Genellikle JournalLoadSuccess yeterli olur) ---

/*
/// Belirli bir işlemin (örn: ekleme, güncelleme, silme) başarıyla tamamlandığını
/// anlık olarak belirtmek için kullanılabilir. Genellikle hemen ardından
/// güncellenmiş liste ile `JournalLoadSuccess` durumu yayınlanır.
class JournalOperationSuccess extends JournalState {
  final String successMessage;
  // İsteğe bağlı olarak işlem gören entry ID'si veya nesnesi eklenebilir.
  // final String? entryId;

  const JournalOperationSuccess(this.successMessage);

  @override
  List<Object?> get props => [successMessage];
}

/// Tek bir günlük girdisinin detaylarının yüklendiği durum.
/// (Eğer detay ekranı için ayrı bir state yönetimi yapılıyorsa kullanılır.)
class JournalEntryDetailLoadSuccess extends JournalState {
  final JournalEntry entry;
  const JournalEntryDetailLoadSuccess(this.entry);
   @override
  List<Object?> get props => [entry];
}
*/