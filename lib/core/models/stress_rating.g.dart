// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stress_rating.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StressRatingAdapter extends TypeAdapter<StressRating> {
  @override
  final int typeId = 1;

  @override
  StressRating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StressRating(
      id: fields[0] as String,
      userId: fields[1] as String,
      rating: fields[2] as int,
      loggedAt: fields[3] as DateTime,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StressRating obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.rating)
      ..writeByte(3)
      ..write(obj.loggedAt)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StressRatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
