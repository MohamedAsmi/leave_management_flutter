// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duty_type_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DutyTypeAdapter extends TypeAdapter<DutyType> {
  @override
  final int typeId = 3;

  @override
  DutyType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DutyType(
      id: fields[0] as int,
      name: fields[1] as String,
      type: fields[2] as String?,
      lat: fields[3] as double?,
      long: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, DutyType obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.long);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DutyTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
