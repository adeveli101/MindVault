import 'dart:async';
import 'dart:convert'; // base64Encode / base64Decode için
import 'dart:typed_data'; // Uint8List için

// Firebase ve Bulut Servisleri
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Yerel Depolama ve Güvenlik
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:path_provider/path_provider.dart';

// Flutter Yardımcıları
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;

// Varsayım: Bu model dosyası projenizde mevcut ve Hive için gerekli
// anotasyonları içeriyor (@HiveType, @HiveField), HiveObject'ten türemiş
// ve ilgili adapter (.g.dart dosyası) 'build_runner' ile oluşturulmuş.

// --- Sabitler ---
const String _hiveEncryptionKeyStorageKey = 'mindvault_hive_encryption_key_v1';
const String _journalBoxName = 'mindvault_journal_box_v1';

// --- Özel Hata Sınıfı ---
/// MindVaultRepository tarafından fırlatılacak özel hata sınıfı.
class MindVaultRepositoryException implements Exception {
  final String message;
  final dynamic cause; // Hatanın orijinal kaynağı (isteğe bağlı)
  MindVaultRepositoryException(this.message, {this.cause});

  @override
  String toString() {
    String output = 'MindVaultRepositoryException: $message';
    if (cause != null) {
      output += '\nCause: $cause';
    }
    return output;
  }
}

// --- Repository Sınıfı ---

/// MindVault uygulamasının temel veri ve servis işlemlerini yöneten merkezi sınıf.
///
/// Sorumlulukları:
/// - Yerel ve şifreli günlük (Journal) veritabanı yönetimi (Hive ile).
/// - Firebase ile Anonim Kullanıcı Kimlik Doğrulama.
/// - Firebase Cloud Messaging (FCM) kurulumu ve token yönetimi (Firestore'a kaydetme).
///
/// Kullanmadan önce `init()` metodu çağrılmalıdır.
class MindVaultRepository {
  // --- Bağımlılıklar ---
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FlutterSecureStorage _secureStorage;

  // --- Dahili Durum ---
  Box<JournalEntry>? _journalBox; // Şifreli Hive kutusu
  bool _isInitialized = false;   // Başlatılma durumu bayrağı

  // --- Constructor ---
  /// `MindVaultRepository` örneği oluşturur.
  /// İsteğe bağlı olarak Firebase/SecureStorage instance'ları dışarıdan verilebilir (test için).
  MindVaultRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? firebaseMessaging,
    FlutterSecureStorage? secureStorage,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // --- Başlatma ve Kapatma ---

  /// Repository'yi asenkron olarak başlatır.
  /// Hive'ı kurar, adaptörleri kaydeder, şifreleme anahtarını yönetir ve
  /// şifreli Hive kutusunu açar.
  ///
  /// Uygulama başlangıcında (main.dart içinde) bir kez çağrılmalıdır.
  Future<void> init() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print("MindVaultRepository already initialized.");
      }
      return;
    }

    if (kDebugMode) {
      print("Initializing MindVaultRepository...");
    }
    try {
      // 1. Hive Altyapısını Başlat
      //    Web platformunda dosya yolu gerekmez.
      if (!kIsWeb) {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocumentDir.path);
        if (kDebugMode) {
          print("Hive initialized with path: ${appDocumentDir.path}");
        }
      } else {
        await Hive.initFlutter();
        if (kDebugMode) {
          print("Hive initialized for Web.");
        }
      }

      // 2. Hive TypeAdapter'larını Kaydet
      //    Eğer modelleriniz bu dosyada değilse, import ettiğinizden emin olun.
      _registerHiveAdapters();

      // 3. Güvenli Şifreleme Anahtarını Al/Oluştur
      final Uint8List encryptionKey = await _getOrGenerateEncryptionKey();

      // 4. Şifreli Hive Kutusunu Aç
      //    JournalEntry tipinde veriler saklayacak.
      _journalBox = await Hive.openBox<JournalEntry>(
        _journalBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      _isInitialized = true;
      if (kDebugMode) {
        print("MindVaultRepository initialized successfully. Encrypted journal box '$_journalBoxName' is open.");
      }

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('FATAL: MindVaultRepository initialization failed: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      // Uygulamanın devam etmesi tehlikeli olabilir. Hata fırlat.
      throw MindVaultRepositoryException('Repository başlatılamadı', cause: e);
    }
  }

  /// Kullanılacak Hive TypeAdapter'larını kaydeder.
  /// `JournalEntry` ve `Mood` için adaptörlerin oluşturulduğu varsayılır.
  void _registerHiveAdapters() {
    if (kDebugMode) {
      print("Registering Hive type adapters...");
    }
    // Hata almamak için zaten kayıtlı olup olmadığını kontrol etmek daha iyidir.
    if (!Hive.isAdapterRegistered(0)) { // JournalEntry için typeId 0 varsayımı
      Hive.registerAdapter(JournalEntryAdapter());
      if (kDebugMode) {
        print("JournalEntryAdapter registered.");
      }
    } else {
      if (kDebugMode) {
        print("JournalEntryAdapter already registered.");
      }
    }
    if (!Hive.isAdapterRegistered(1)) { // Mood için typeId 1 varsayımı
      Hive.registerAdapter(MoodAdapter());
      if (kDebugMode) {
        print("MoodAdapter registered.");
      }
    } else {
      if (kDebugMode) {
        print("MoodAdapter already registered.");
      }
    }
  }

  /// Güvenli depolamadan (Keychain/Keystore) Hive şifreleme anahtarını okur.
  /// Eğer anahtar yoksa, yeni bir tane üretir, kaydeder ve döndürür.
  Future<Uint8List> _getOrGenerateEncryptionKey() async {
    if (kDebugMode) {
      print("Getting/Generating encryption key...");
    }
    try {
      String? base64Key = await _secureStorage.read(key: _hiveEncryptionKeyStorageKey);
      if (base64Key == null || base64Key.isEmpty) {
        if (kDebugMode) {
          print('Encryption key not found in secure storage. Generating a new one...');
        }
        final key = Hive.generateSecureKey(); // 32 byte (256-bit) güvenli anahtar
        await _secureStorage.write(
          key: _hiveEncryptionKeyStorageKey,
          value: base64Encode(key), // Anahtarı base64 string olarak sakla
        );
        if (kDebugMode) {
          print('New encryption key generated and saved to secure storage.');
        }
        return Uint8List.fromList(key);
      } else {
        if (kDebugMode) {
          print('Encryption key loaded from secure storage.');
        }
        return base64Decode(base64Key); // Saklanan base64 string'i byte listesine çevir
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error managing encryption key: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException("Şifreleme anahtarı alınamadı/oluşturulamadı", cause: e);
    }
  }

  /// Repository kapatıldığında veya uygulama sonlandığında çağrılmalı.
  /// Açık Hive kutularını kapatır.
  Future<void> close() async {
    if (kDebugMode) {
      print("Closing MindVaultRepository...");
    }
    if (_journalBox?.isOpen ?? false) {
      try {
        // Kutuyu kapatmadan önce bekleyen yazma işlemleri varsa tamamlanmasını bekle
        await _journalBox!.flush();
        // İsteğe bağlı: Kutuyu sıkıştırarak disk alanını optimize et
        // await _journalBox!.compact();
        await _journalBox!.close();
        if (kDebugMode) {
          print("Encrypted journal box '$_journalBoxName' closed.");
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print("Error closing journal box: $e");
        }
        if (kDebugMode) {
          print(stackTrace);
        }
        // Hata olsa bile devam etmeye çalışabiliriz.
      }
    }
    _isInitialized = false; // Tekrar başlatılabilir olması için
    if (kDebugMode) {
      print("MindVaultRepository closed.");
    }
  }

  /// Dahili: İşlem yapmadan önce repository'nin başlatıldığından emin olur.
  void _ensureInitialized() {
    if (!_isInitialized || _journalBox == null || !_journalBox!.isOpen) {
      throw MindVaultRepositoryException(
          'Repository not initialized or box closed. Call init() first.');
    }
  }

  // --- Kimlik Doğrulama (Authentication) ---

  /// Mevcut giriş yapmış kullanıcıyı döndürür (yoksa null).
  User? get currentUser => _auth.currentUser;

  /// Kullanıcının oturum durumundaki (giriş/çıkış) değişiklikleri dinlemek için Stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Anonim olarak Firebase'e giriş yapar.
  /// Başarılı olursa, bildirim kurulumunu tetikler.
  Future<User?> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        if (kDebugMode) {
          print('Attempting anonymous sign-in...');
        }
        final userCredential = await _auth.signInAnonymously();
        if (kDebugMode) {
          print('Anonymous sign-in successful. User ID: ${userCredential.user?.uid}');
        }
        await _setupNotifications(); // Giriş sonrası bildirimleri kur
        return userCredential.user;
      } else {
        if (kDebugMode) {
          print('User already signed in anonymously. User ID: ${_auth.currentUser!.uid}');
        }
        // Oturum açık olsa bile token güncel değilse diye tekrar kurmayı dene
        await _setupNotifications();
        return _auth.currentUser;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Anonymous sign-in failed: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Anonim giriş başarısız', cause: e);
    }
  }

  /// Firebase'den çıkış yapar.
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('Signing out user...');
      }
      await _auth.signOut();
      if (kDebugMode) {
        print('User signed out successfully.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Oturum kapatılamadı', cause: e);
    }
  }

  // --- Bildirimler (FCM) ---

  /// FCM bildirimlerini kurar: İzin ister ve token'ı Firestore'a kaydeder.
  /// Genellikle `signInAnonymously` içinden çağrılır.
  Future<void> _setupNotifications() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print('Cannot setup notifications: User is not signed in.');
      }
      return; // Kullanıcı yoksa işlem yapma
    }

    // Web platformunda FCM farklı çalışır, bu örnek mobil odaklıdır.
    if (kIsWeb) {
      if (kDebugMode) {
        print("FCM setup skipped for Web platform in this example.");
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Requesting notification permissions...');
      }
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, // Kesin izin iste
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('Notification permission granted.');
        }
        String? token;
        try {
          // APNS token'ı almak için (iOS)
          // String? apnsToken = await _messaging.getAPNSToken();
          // if (apnsToken != null) { /* ... */ }
          token = await _messaging.getToken();
        } catch (e) {
          if (kDebugMode) {
            print("Error getting FCM token: $e");
          }
          // Token alınamasa bile devam et, belki daha sonra alınır.
        }

        if (token != null) {
          if (kDebugMode) {
            print('FCM Token obtained: $token');
          }
          // Token'ı Firestore'a kaydet
          final userDocRef = _firestore.collection('users').doc(user.uid);
          await userDocRef.set({
            'fcmToken': token,
            'lastUpdated': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform.name, // iOS, Android vs.
            'userId': user.uid, // Kolay sorgulama için
          }, SetOptions(merge: true)); // Varolan diğer alanları koru
          if (kDebugMode) {
            print('FCM Token saved/updated in Firestore for user ${user.uid}.');
          }
        } else {
          if (kDebugMode) {
            print('Could not get FCM token at this time.');
          }
        }
      } else {
        if (kDebugMode) {
          print('Notification permission denied by user (${settings.authorizationStatus}).');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Notification setup failed: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      // Bildirim hatası genellikle kritik değildir, hata fırlatma.
      // throw MindVaultRepositoryException('Bildirim kurulumu başarısız', cause: e);
    }
  }

  // --- Günlük (Journal) CRUD Operasyonları (Hive ile) ---

  /// Yeni bir günlük girdisini yerel Hive veritabanına ekler.
  Future<void> addEntry(JournalEntry entry) async {
    _ensureInitialized();
    if (kDebugMode) {
      print("Adding journal entry with ID: ${entry.id} to Hive...");
    }
    try {
      // Hive `put` işlemi anahtar-değer çifti alır.
      // Anahtar olarak entry.id kullanıyoruz.
      await _journalBox!.put(entry.id, entry);
      if (kDebugMode) {
        print("Journal entry added successfully.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Failed to add journal entry to Hive: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Günlük girdisi kaydedilemedi', cause: e);
    }
  }

  /// Mevcut bir günlük girdisini yerel Hive veritabanında günceller.
  Future<void> updateEntry(JournalEntry entry) async {
    _ensureInitialized();
    if (kDebugMode) {
      print("Updating journal entry with ID: ${entry.id} in Hive...");
    }
    try {
      // Hive'da `put` metodu, eğer anahtar zaten varsa değeri üzerine yazar.
      // `updatedAt` alanını otomatik olarak güncelleyelim.
      final entryToSave = entry.copyWith(updatedAt: DateTime.now());

      await _journalBox!.put(entry.id, entryToSave);
      if (kDebugMode) {
        print("Journal entry updated successfully.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Failed to update journal entry in Hive: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Günlük girdisi güncellenemedi', cause: e);
    }
  }

  /// Belirtilen ID'ye sahip günlük girdisini yerel Hive veritabanından siler.
  Future<void> deleteEntry(String id) async {
    _ensureInitialized();
    if (kDebugMode) {
      print("Deleting journal entry with ID: $id from Hive...");
    }
    try {
      await _journalBox!.delete(id);
      if (kDebugMode) {
        print("Journal entry deleted successfully.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Failed to delete journal entry from Hive: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Günlük girdisi silinemedi', cause: e);
    }
  }

  /// Tüm günlük girdilerini yerel Hive veritabanından getirir.
  /// Girdiler `updatedAt` alanına göre en yeniden en eskiye doğru sıralanır.
  Future<List<JournalEntry>> getAllEntries() async {
    _ensureInitialized();
    if (kDebugMode) {
      print("Fetching all journal entries from Hive...");
    }
    try {
      // `values` tüm değerleri bir Iterable olarak döndürür.
      final entries = _journalBox!.values.toList();
      // Veriyi tarihe göre sırala (en yeni üstte)
      entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (kDebugMode) {
        print('Fetched ${entries.length} journal entries.');
      }
      return entries;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Failed to get journal entries from Hive: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Günlük girdileri alınamadı', cause: e);
    }
  }

  /// Belirtilen ID'ye sahip tek bir günlük girdisini yerel Hive veritabanından getirir.
  /// Girdi bulunamazsa `null` döner.
  Future<JournalEntry?> getEntryById(String id) async {
    _ensureInitialized();
    if (kDebugMode) {
      print("Getting journal entry by ID: $id from Hive...");
    }
    try {
      // `get` metodu, anahtar yoksa null döndürür.
      final entry = _journalBox!.get(id);
      if (kDebugMode) {
        print(entry != null ? "Entry found." : "Entry not found.");
      }
      return entry;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Failed to get journal entry by ID from Hive: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Günlük girdisi alınamadı', cause: e);
    }
  }

  /// Hive kutusundaki tüm günlük girdilerini siler. **DİKKATLİ KULLANIN!**
  /// Genellikle test veya sıfırlama senaryoları için kullanılır.
  Future<int> deleteAllEntries() async {
    _ensureInitialized();
    if (kDebugMode) {
      print("WARNING: Deleting all journal entries from Hive box '$_journalBoxName'...");
    }
    try {
      // `clear` metodu kutuyu boşaltır ve silinen öğe sayısını döndürür.
      final count = await _journalBox!.clear();
      if (kDebugMode) {
        print("$count entries deleted successfully.");
      }
      return count;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Failed to delete all journal entries from Hive: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      throw MindVaultRepositoryException('Tüm günlük girdileri silinemedi', cause: e);
    }
  }
}