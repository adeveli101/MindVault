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
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.isFavorite);
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
        return Mood.sad;
      case 2:
        return Mood.neutral;
      case 3:
        return Mood.excited;
      case 4:
        return Mood.anxious;
      case 5:
        return Mood.calm;
      case 6:
        return Mood.angry;
      case 7:
        return Mood.grateful;
      case 8:
        return Mood.stressed;
      case 9:
        return Mood.tired;
      case 10:
        return Mood.unknown;
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
      case Mood.sad:
        writer.writeByte(1);
        break;
      case Mood.neutral:
        writer.writeByte(2);
        break;
      case Mood.excited:
        writer.writeByte(3);
        break;
      case Mood.anxious:
        writer.writeByte(4);
        break;
      case Mood.calm:
        writer.writeByte(5);
        break;
      case Mood.angry:
        writer.writeByte(6);
        break;
      case Mood.grateful:
        writer.writeByte(7);
        break;
      case Mood.stressed:
        writer.writeByte(8);
        break;
      case Mood.tired:
        writer.writeByte(9);
        break;
      case Mood.unknown:
        writer.writeByte(10);
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
