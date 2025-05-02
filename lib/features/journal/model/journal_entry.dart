import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart'; // Hive import
import 'package:uuid/uuid.dart';

// ÖNEMLİ: Bu dosyayı güncelledikten sonra kod üreticisini çalıştırmanız gerekir:
// flutter packages pub run build_runner build --delete-conflicting-outputs
// 'title' alanı eklendiği için adaptörün güncellenmesi şarttır.

part 'journal_entry.g.dart'; // Hive Generator tarafından oluşturulacak dosya



@HiveType(typeId: 1) // Doğru typeId kullandığınızdan emin olun
enum Mood {
  // Pozitif Duygular
  @HiveField(0) happy,
  @HiveField(1) excited,
  @HiveField(2) ecstatic,
  @HiveField(3) grateful,
  @HiveField(4) peaceful,
  @HiveField(5) calm,
  @HiveField(6) content,
  @HiveField(7) confident,
  @HiveField(8) inspired,
  @HiveField(9) hopeful,

  // Nötr Duygular
  @HiveField(10) neutral,
  @HiveField(11) contemplative,
  @HiveField(12) curious,
  @HiveField(13) focused,
  @HiveField(14) indifferent,
  @HiveField(15) nostalgic,

  // Negatif Duygular
  @HiveField(16) sad,
  @HiveField(17) melancholic,
  @HiveField(18) anxious,
  @HiveField(19) stressed,
  @HiveField(20) overwhelmed,
  @HiveField(21) tired,
  @HiveField(22) exhausted,
  @HiveField(23) angry,
  @HiveField(24) frustrated,
  @HiveField(25) jealous,
  @HiveField(26) guilty,
  @HiveField(27) embarrassed,
  @HiveField(28) bored,
  @HiveField(29) confused,

  // Karma Duygular
  @HiveField(30) bittersweet,
  @HiveField(31) amused,
  @HiveField(32) surprised,
  @HiveField(33) awed,
  @HiveField(34) determined,
  @HiveField(35) vulnerable,
  @HiveField(36) reflective,

  // Fizyolojik Duygular
  @HiveField(37) hungry,
  @HiveField(38) energetic,
  @HiveField(39) sleepy,
  @HiveField(40) refreshed,

  // Diğer
  @HiveField(41) unknown,
  @HiveField(42) creative,
  @HiveField(43) motivated,
  @HiveField(44) inLove,
  @HiveField(45) generous,
  @HiveField(46) proud,
  @HiveField(47) relieved,
}


@HiveType(typeId: 0) // Benzersiz typeId (0: JournalEntry)
// ignore: must_be_immutable
class JournalEntry extends HiveObject with EquatableMixin { // HiveObject'ten türetin

  @HiveField(0) // Benzersiz alan index'i
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime updatedAt;

  @HiveField(4)
  final Mood? mood;

  @HiveField(5)
  final List<String>? tags;

  @HiveField(6)
  final bool isFavorite;

  @HiveField(7) // title için yeni Hive alanı index'i
  final String? title; // Yeni başlık alanı (nullable)

  JournalEntry({
    String? id,
    required this.content,
    required this.createdAt,
    DateTime? updatedAt,
    this.mood,
    this.tags,
    this.isFavorite = false,
    this.title, // Constructor'a eklendi
  })  : id = id ?? const Uuid().v4(), // const kullanıldı
        updatedAt = updatedAt ?? createdAt;

  JournalEntry copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    Mood? mood, // Nullable override için düzeltildi
    List<String>? tags, // Nullable override için düzeltildi
    bool? isFavorite,
    String? title, // copyWith'e eklendi (nullable)
  }) {
    return JournalEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Değişkenin null olması durumunda eski değeri koru,
      // null atanması isteniyorsa farklı bir mantık gerekebilir.
      mood: mood != null || this.mood == null ? mood : this.mood,
      tags: tags != null || this.tags == null ? tags : this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      title: title != null || this.title == null ? title : this.title, // title için eklendi
    );
  }


  // toJson/fromJson metodları Hive için zorunlu DEĞİL,
  // ama başka yerlerde (örn: API, loglama) gerekirse kalabilir.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title, // toJson'a eklendi
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'mood': mood?.name,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    Mood? parsedMood;
    final moodString = json['mood'] as String?;
    if (moodString != null) {
      try {
        parsedMood = Mood.values.byName(moodString);
      } catch (e) { parsedMood = Mood.unknown; }
    }
    List<String>? parsedTags;
    if (json['tags'] != null && json['tags'] is List) {
      try {
        parsedTags = List<String>.from(json['tags'].map((item) => item.toString()));
      } catch (e) { parsedTags = null;}
    }
    return JournalEntry(
      id: json['id'] as String,
      title: json['title'] as String?, // fromJson'a eklendi
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      mood: parsedMood,
      tags: parsedTags,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }


  @override
  List<Object?> get props => [
    id,
    content,
    createdAt,
    updatedAt,
    mood,
    tags,
    isFavorite,
    title, // props'a eklendi
  ];

  // HiveObject'ten geldiği için `toString` zaten var ama override edilebilir.
  @override
  bool get stringify => true; // Equatable'ın toString'i kullanmasını sağlar
}