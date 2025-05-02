// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 0;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry(
      id: fields[0] as String?,
      content: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime?,
      mood: fields[4] as Mood?,
      tags: (fields[5] as List?)?.cast<String>(),
      isFavorite: fields[6] as bool,
      title: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoodAdapter extends TypeAdapter<Mood> {
  @override
  final int typeId = 1;

  @override
  Mood read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Mood.happy;
      case 1:
        return Mood.excited;
      case 2:
        return Mood.ecstatic;
      case 3:
        return Mood.grateful;
      case 4:
        return Mood.peaceful;
      case 5:
        return Mood.calm;
      case 6:
        return Mood.content;
      case 7:
        return Mood.confident;
      case 8:
        return Mood.inspired;
      case 9:
        return Mood.hopeful;
      case 10:
        return Mood.neutral;
      case 11:
        return Mood.contemplative;
      case 12:
        return Mood.curious;
      case 13:
        return Mood.focused;
      case 14:
        return Mood.indifferent;
      case 15:
        return Mood.nostalgic;
      case 16:
        return Mood.sad;
      case 17:
        return Mood.melancholic;
      case 18:
        return Mood.anxious;
      case 19:
        return Mood.stressed;
      case 20:
        return Mood.overwhelmed;
      case 21:
        return Mood.tired;
      case 22:
        return Mood.exhausted;
      case 23:
        return Mood.angry;
      case 24:
        return Mood.frustrated;
      case 25:
        return Mood.jealous;
      case 26:
        return Mood.guilty;
      case 27:
        return Mood.embarrassed;
      case 28:
        return Mood.bored;
      case 29:
        return Mood.confused;
      case 30:
        return Mood.bittersweet;
      case 31:
        return Mood.amused;
      case 32:
        return Mood.surprised;
      case 33:
        return Mood.awed;
      case 34:
        return Mood.determined;
      case 35:
        return Mood.vulnerable;
      case 36:
        return Mood.reflective;
      case 37:
        return Mood.hungry;
      case 38:
        return Mood.energetic;
      case 39:
        return Mood.sleepy;
      case 40:
        return Mood.refreshed;
      case 41:
        return Mood.unknown;
      case 42:
        return Mood.creative;
      case 43:
        return Mood.motivated;
      case 44:
        return Mood.inLove;
      case 45:
        return Mood.generous;
      case 46:
        return Mood.proud;
      case 47:
        return Mood.relieved;
      default:
        return Mood.happy;
    }
  }

  @override
  void write(BinaryWriter writer, Mood obj) {
    switch (obj) {
      case Mood.happy:
        writer.writeByte(0);
        break;
      case Mood.excited:
        writer.writeByte(1);
        break;
      case Mood.ecstatic:
        writer.writeByte(2);
        break;
      case Mood.grateful:
        writer.writeByte(3);
        break;
      case Mood.peaceful:
        writer.writeByte(4);
        break;
      case Mood.calm:
        writer.writeByte(5);
        break;
      case Mood.content:
        writer.writeByte(6);
        break;
      case Mood.confident:
        writer.writeByte(7);
        break;
      case Mood.inspired:
        writer.writeByte(8);
        break;
      case Mood.hopeful:
        writer.writeByte(9);
        break;
      case Mood.neutral:
        writer.writeByte(10);
        break;
      case Mood.contemplative:
        writer.writeByte(11);
        break;
      case Mood.curious:
        writer.writeByte(12);
        break;
      case Mood.focused:
        writer.writeByte(13);
        break;
      case Mood.indifferent:
        writer.writeByte(14);
        break;
      case Mood.nostalgic:
        writer.writeByte(15);
        break;
      case Mood.sad:
        writer.writeByte(16);
        break;
      case Mood.melancholic:
        writer.writeByte(17);
        break;
      case Mood.anxious:
        writer.writeByte(18);
        break;
      case Mood.stressed:
        writer.writeByte(19);
        break;
      case Mood.overwhelmed:
        writer.writeByte(20);
        break;
      case Mood.tired:
        writer.writeByte(21);
        break;
      case Mood.exhausted:
        writer.writeByte(22);
        break;
      case Mood.angry:
        writer.writeByte(23);
        break;
      case Mood.frustrated:
        writer.writeByte(24);
        break;
      case Mood.jealous:
        writer.writeByte(25);
        break;
      case Mood.guilty:
        writer.writeByte(26);
        break;
      case Mood.embarrassed:
        writer.writeByte(27);
        break;
      case Mood.bored:
        writer.writeByte(28);
        break;
      case Mood.confused:
        writer.writeByte(29);
        break;
      case Mood.bittersweet:
        writer.writeByte(30);
        break;
      case Mood.amused:
        writer.writeByte(31);
        break;
      case Mood.surprised:
        writer.writeByte(32);
        break;
      case Mood.awed:
        writer.writeByte(33);
        break;
      case Mood.determined:
        writer.writeByte(34);
        break;
      case Mood.vulnerable:
        writer.writeByte(35);
        break;
      case Mood.reflective:
        writer.writeByte(36);
        break;
      case Mood.hungry:
        writer.writeByte(37);
        break;
      case Mood.energetic:
        writer.writeByte(38);
        break;
      case Mood.sleepy:
        writer.writeByte(39);
        break;
      case Mood.refreshed:
        writer.writeByte(40);
        break;
      case Mood.unknown:
        writer.writeByte(41);
        break;
      case Mood.creative:
        writer.writeByte(42);
        break;
      case Mood.motivated:
        writer.writeByte(43);
        break;
      case Mood.inLove:
        writer.writeByte(44);
        break;
      case Mood.generous:
        writer.writeByte(45);
        break;
      case Mood.proud:
        writer.writeByte(46);
        break;
      case Mood.relieved:
        writer.writeByte(47);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
