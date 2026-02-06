// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hifz_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HifzLogAdapter extends TypeAdapter<HifzLog> {
  @override
  final int typeId = 2;

  @override
  HifzLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HifzLog(
      id: fields[0] as int,
      studentId: fields[1] as int,
      studentName: fields[2] as String,
      courseId: fields[3] as int,
      courseName: fields[4] as String,
      sheikhId: fields[5] as int,
      sheikhName: fields[6] as String,
      sessionDate: fields[7] as DateTime,
      startSura: fields[8] as int,
      startAyah: fields[9] as int,
      endSura: fields[10] as int,
      endAyah: fields[11] as int,
      evaluation: fields[12] as String,
      fluencyScore: fields[13] as int?,
      tajweedScore: fields[14] as int?,
      memorizationScore: fields[15] as int?,
      comments: fields[16] as String?,
      nextAssignment: fields[17] as String?,
      createdAt: fields[18] as DateTime,
      updatedAt: fields[19] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HifzLog obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.studentName)
      ..writeByte(3)
      ..write(obj.courseId)
      ..writeByte(4)
      ..write(obj.courseName)
      ..writeByte(5)
      ..write(obj.sheikhId)
      ..writeByte(6)
      ..write(obj.sheikhName)
      ..writeByte(7)
      ..write(obj.sessionDate)
      ..writeByte(8)
      ..write(obj.startSura)
      ..writeByte(9)
      ..write(obj.startAyah)
      ..writeByte(10)
      ..write(obj.endSura)
      ..writeByte(11)
      ..write(obj.endAyah)
      ..writeByte(12)
      ..write(obj.evaluation)
      ..writeByte(13)
      ..write(obj.fluencyScore)
      ..writeByte(14)
      ..write(obj.tajweedScore)
      ..writeByte(15)
      ..write(obj.memorizationScore)
      ..writeByte(16)
      ..write(obj.comments)
      ..writeByte(17)
      ..write(obj.nextAssignment)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HifzLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
