// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = 1;

  @override
  Course read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Course(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as String,
      mosqueId: fields[4] as int?,
      mosqueName: fields[5] as String?,
      image_url: fields[6] as String?,
      startDate: fields[7] as DateTime?,
      endDate: fields[8] as DateTime?,
      maxStudents: fields[9] as int,
      currentStudents: fields[10] as int,
      isActive: fields[11] as bool,
      isRegistrationOpen: fields[12] as bool,
      requirements: fields[13] as String?,
      scheduleDetails: fields[14] as String?,
      createdBy: fields[15] as int?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      enrollmentStatus: fields[18] as String?,
      mosque: fields[19] as Mosque?,
    );
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.mosqueId)
      ..writeByte(5)
      ..write(obj.mosqueName)
      ..writeByte(6)
      ..write(obj.image_url)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.maxStudents)
      ..writeByte(10)
      ..write(obj.currentStudents)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.isRegistrationOpen)
      ..writeByte(13)
      ..write(obj.requirements)
      ..writeByte(14)
      ..write(obj.scheduleDetails)
      ..writeByte(15)
      ..write(obj.createdBy)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.enrollmentStatus)
      ..writeByte(19)
      ..write(obj.mosque);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
