part of 'assessment_result.dart';

class AssessmentResultAdapter extends TypeAdapter<AssessmentResult> {
  @override
  final int typeId = 4;

  @override
  AssessmentResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssessmentResult(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as String,
      totalScore: fields[3] as double,
      answers: (fields[4] as Map).cast<String, dynamic>(),
      interpretation: fields[5] as String,
      takenAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AssessmentResult obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.totalScore)
      ..writeByte(4)
      ..write(obj.answers)
      ..writeByte(5)
      ..write(obj.interpretation)
      ..writeByte(6)
      ..write(obj.takenAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
