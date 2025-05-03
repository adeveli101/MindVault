import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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



extension MoodUtils on Mood {
  /// Bu duyguya karşılık gelen FontAwesome ikonunu döndürür.
  IconData get icon {
    switch (this) {
    // Pozitif Duygular
      case Mood.happy: return FontAwesomeIcons.faceSmile;
      case Mood.excited: return FontAwesomeIcons.bolt;
      case Mood.ecstatic: return FontAwesomeIcons.star;
      case Mood.grateful: return FontAwesomeIcons.handsPraying;
      case Mood.peaceful: return FontAwesomeIcons.dove;
      case Mood.calm: return FontAwesomeIcons.spa;
      case Mood.content: return FontAwesomeIcons.faceSmileBeam;
      case Mood.confident: return FontAwesomeIcons.crown;
      case Mood.inspired: return FontAwesomeIcons.lightbulb;
      case Mood.hopeful: return FontAwesomeIcons.seedling;

    // Nötr Duygular
      case Mood.neutral: return FontAwesomeIcons.faceMeh;
      case Mood.contemplative: return FontAwesomeIcons.brain;
      case Mood.curious: return FontAwesomeIcons.magnifyingGlass;
      case Mood.focused: return FontAwesomeIcons.bullseye;
      case Mood.indifferent: return FontAwesomeIcons.faceRollingEyes;
      case Mood.nostalgic: return FontAwesomeIcons.clockRotateLeft;

    // Negatif Duygular
      case Mood.sad: return FontAwesomeIcons.faceSadTear;
      case Mood.melancholic: return FontAwesomeIcons.cloudRain;
      case Mood.anxious: return FontAwesomeIcons.personCircleExclamation;
      case Mood.stressed: return FontAwesomeIcons.fire;
      case Mood.overwhelmed: return FontAwesomeIcons.volcano;
      case Mood.tired: return FontAwesomeIcons.batteryQuarter;
      case Mood.exhausted: return FontAwesomeIcons.bed;
      case Mood.angry: return FontAwesomeIcons.faceAngry;
      case Mood.frustrated: return FontAwesomeIcons.personBurst;
      case Mood.jealous: return FontAwesomeIcons.eye;
      case Mood.guilty: return FontAwesomeIcons.scaleUnbalanced;
      case Mood.embarrassed: return FontAwesomeIcons.faceDizzy;
      case Mood.bored: return FontAwesomeIcons.faceMehBlank;
      case Mood.confused: return FontAwesomeIcons.circleQuestion; // Kafası Karışık (circleQuestion kullanılıyor)

    // Karma Duygular
      case Mood.bittersweet: return FontAwesomeIcons.yinYang;
      case Mood.amused: return FontAwesomeIcons.faceGrinWide;
    // case Mood.surprised: return FontAwesomeIcons.faceSurprise; // Uygun ikon seçilmeli
      case Mood.awed: return FontAwesomeIcons.solidStar;
      case Mood.determined: return FontAwesomeIcons.personWalking;
      case Mood.vulnerable: return FontAwesomeIcons.heartCrack;
      case Mood.reflective: return FontAwesomeIcons.brain; // Tekrar?

    // Fizyolojik Duygular
      case Mood.hungry: return FontAwesomeIcons.utensils;
      case Mood.energetic: return FontAwesomeIcons.batteryFull;
      case Mood.sleepy: return FontAwesomeIcons.moon;
      case Mood.refreshed: return FontAwesomeIcons.shower;

    // Diğer
      case Mood.unknown: return FontAwesomeIcons.circleQuestion;
      case Mood.creative: return FontAwesomeIcons.wandMagicSparkles;
      case Mood.motivated: return FontAwesomeIcons.rocket;
      case Mood.inLove: return FontAwesomeIcons.heartPulse;
      case Mood.generous: return FontAwesomeIcons.gift;
      case Mood.proud: return FontAwesomeIcons.medal;
    // case Mood.relieved: return FontAwesomeIcons.faceSmileRelief; // Uygun ikon seçilmeli

    // Not: surprised ve relieved için uygun FontAwesome ikonları bulunup eklenebilir.
    // Şimdilik eksik olanlar için varsayılan ikon dönecek.
      default: return FontAwesomeIcons.circleQuestion; // Bilinmeyen veya eksik durumlar
    }
  }

  /// Bu duyguya karşılık gelen rengi, verilen ColorScheme'e göre döndürür.
  Color getColor(ColorScheme colorScheme) {
    switch (this) {
    // Pozitif Duygular
      case Mood.happy: return Colors.amber.shade600;
      case Mood.excited: return Colors.orange.shade600;
      case Mood.ecstatic: return Colors.orange.shade800;
      case Mood.grateful: return Colors.pink.shade300;
      case Mood.peaceful: return Colors.teal.shade200;
      case Mood.calm: return colorScheme.secondary;
      case Mood.content: return Colors.lightGreen.shade400;
      case Mood.confident: return Colors.amber.shade800;
      case Mood.inspired: return Colors.deepPurple.shade300;
      case Mood.hopeful: return Colors.lightGreen.shade600;

    // Nötr Duygular
      case Mood.neutral: return colorScheme.onSurfaceVariant;
      case Mood.contemplative: return Colors.blueGrey.shade400;
      case Mood.curious: return Colors.cyan.shade400;
      case Mood.focused: return Colors.indigo.shade400;
      case Mood.indifferent: return Colors.grey.shade400;
      case Mood.nostalgic: return Colors.amber.shade200;

    // Negatif Duygular
      case Mood.sad: return Colors.blue.shade600;
      case Mood.melancholic: return Colors.blue.shade800;
      case Mood.anxious: return Colors.purple.shade300;
      case Mood.stressed: return colorScheme.error;
      case Mood.overwhelmed: return Colors.deepPurple.shade900;
      case Mood.tired: return Colors.brown.shade400;
      case Mood.exhausted: return Colors.brown.shade700;
      case Mood.angry: return colorScheme.errorContainer;
      case Mood.frustrated: return Colors.deepOrange.shade700;
      case Mood.jealous: return Colors.green.shade900;
      case Mood.guilty: return Colors.deepPurple.shade700;
      case Mood.embarrassed: return Colors.pink.shade400;
      case Mood.bored: return Colors.grey.shade500;
      case Mood.confused: return Colors.amber.shade300;

    // Karma Duygular
      case Mood.bittersweet: return Colors.deepOrange.shade300;
      case Mood.amused: return Colors.lime.shade400;
    // case Mood.surprised: return Colors.purple.shade200;
      case Mood.awed: return Colors.indigo.shade300;
      case Mood.determined: return Colors.red.shade500;
      case Mood.vulnerable: return Colors.pink.shade200;
      case Mood.reflective: return Colors.blueGrey.shade300;

    // Fizyolojik Duygular
      case Mood.hungry: return Colors.amber.shade700;
      case Mood.energetic: return Colors.yellow.shade700;
      case Mood.sleepy: return Colors.indigo.shade100;
      case Mood.refreshed: return Colors.lightBlue.shade400;

    // Diğer
      case Mood.unknown: return colorScheme.outline;
      case Mood.creative: return Colors.purple.shade400;
      case Mood.motivated: return Colors.red.shade300;
      case Mood.inLove: return Colors.pink.shade500;
      case Mood.generous: return Colors.deepPurple.shade200;
      case Mood.proud: return Colors.indigo.shade500;
    // case Mood.relieved: return Colors.teal.shade300;
      default: return colorScheme.outline; // Bilinmeyen veya eksik durumlar
    }
  }

  /// Bu duygunun kullanıcı dostu ismini döndürür (Türkçe).
  String get displayName {
    switch (this) {
    // Pozitif Duygular
      case Mood.happy: return "Mutlu";
      case Mood.excited: return "Heyecanlı";
      case Mood.ecstatic: return "Coşkulu";
      case Mood.grateful: return "Minnettar";
      case Mood.peaceful: return "Huzurlu";
      case Mood.calm: return "Sakin";
      case Mood.content: return "Memnun";
      case Mood.confident: return "Özgüvenli";
      case Mood.inspired: return "İlham Almış";
      case Mood.hopeful: return "Umutlu";

    // Nötr Duygular
      case Mood.neutral: return "Nötr";
      case Mood.contemplative: return "Düşünceli";
      case Mood.curious: return "Meraklı";
      case Mood.focused: return "Odaklanmış";
      case Mood.indifferent: return "Kayıtsız";
      case Mood.nostalgic: return "Nostaljik";

    // Negatif Duygular
      case Mood.sad: return "Üzgün";
      case Mood.melancholic: return "Melankolik";
      case Mood.anxious: return "Endişeli";
      case Mood.stressed: return "Stresli";
      case Mood.overwhelmed: return "Bunalmış";
      case Mood.tired: return "Yorgun";
      case Mood.exhausted: return "Bitkin";
      case Mood.angry: return "Kızgın";
      case Mood.frustrated: return "Hayal Kırıklığına Uğramış";
      case Mood.jealous: return "Kıskanç";
      case Mood.guilty: return "Suçlu";
      case Mood.embarrassed: return "Mahcup";
      case Mood.bored: return "Sıkılmış";
      case Mood.confused: return "Kafası Karışık";

    // Karma Duygular
      case Mood.bittersweet: return "Tatlı-Acı";
      case Mood.amused: return "Eğlenmiş";
      case Mood.surprised: return "Şaşırmış";
      case Mood.awed: return "Hayran";
      case Mood.determined: return "Kararlı";
      case Mood.vulnerable: return "Savunmasız";
      case Mood.reflective: return "Derin Düşünceli";

    // Fizyolojik Duygular
      case Mood.hungry: return "Aç";
      case Mood.energetic: return "Enerjik";
      case Mood.sleepy: return "Uykulu";
      case Mood.refreshed: return "Tazelenmiş";

    // Diğer
      case Mood.unknown: return "Bilinmiyor";
      case Mood.creative: return "Yaratıcı";
      case Mood.motivated: return "Motive Olmuş";
      case Mood.inLove: return "Aşık";
      case Mood.generous: return "Cömert";
      case Mood.proud: return "Gururlu";
      case Mood.relieved: return "Rahatlamış";
    // default: return toString().split('.').last; // Varsayılan olarak enum ismini döndür
    }
  }
}