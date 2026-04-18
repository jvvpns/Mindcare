// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlannerEntryAdapter extends TypeAdapter<PlannerEntry> {
  @override
  final int typeId = 3;

  @override
  PlannerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlannerEntry(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      category: fields[4] as String,
      dueDate: fields[5] as DateTime,
      isCompleted: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      endTime: fields[8] as DateTime?,
      reminderOffset: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PlannerEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.endTime)
      ..writeByte(9)
      ..write(obj.reminderOffset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannerEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
