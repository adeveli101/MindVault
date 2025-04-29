import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart'; // Hive import
import 'package:uuid/uuid.dart';

// ÖNEMLİ: Bu dosyayı güncelledikten sonra kod üreticisini çalıştırmanız gerekir:
// flutter packages pub run build_runner build --delete-conflicting-outputs
// 'title' alanı eklendiği için adaptörün güncellenmesi şarttır.

part 'journal_entry.g.dart'; // Hive Generator tarafından oluşturulacak dosya

@HiveType(typeId: 1) // typeId 1: Mood Enum
enum Mood {
  @HiveField(0) happy,
  @HiveField(1) sad,
  @HiveField(2) neutral,
  @HiveField(3) excited,
  @HiveField(4) anxious,
  @HiveField(5) calm,
  @HiveField(6) angry,
  @HiveField(7) grateful,
  @HiveField(8) stressed,
  @HiveField(9) tired,
  @HiveField(10) unknown, // veya belirtilmemiş
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