// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mosque.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MosqueAdapter extends TypeAdapter<Mosque> {
  @override
  final int typeId = 3;

  @override
  Mosque read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mosque(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String?,
      address: fields[3] as String?,
      city: fields[4] as String?,
      phone: fields[5] as String?,
      email: fields[6] as String?,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      imagePath: fields[9] as String?,
      isActive: fields[10] as bool,
      createdBy: fields[11] as int?,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Mosque obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.createdBy)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MosqueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
