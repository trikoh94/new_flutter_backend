// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'idea.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IdeaAdapter extends TypeAdapter<Idea> {
  @override
  final int typeId = 0;

  @override
  Idea read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Idea(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime,
      connectedIdeas: (fields[4] as List).cast<String>(),
      x: fields[5] as double,
      y: fields[6] as double,
      isShared: fields[7] as bool,
      sharedAt: fields[8] as DateTime?,
      isAIGenerated: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Idea obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.connectedIdeas)
      ..writeByte(5)
      ..write(obj.x)
      ..writeByte(6)
      ..write(obj.y)
      ..writeByte(7)
      ..write(obj.isShared)
      ..writeByte(8)
      ..write(obj.sharedAt)
      ..writeByte(9)
      ..write(obj.isAIGenerated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
