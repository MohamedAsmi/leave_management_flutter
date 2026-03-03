// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_log_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeLogSessionModelAdapter extends TypeAdapter<TimeLogSessionModel> {
  @override
  final int typeId = 9;

  @override
  TimeLogSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeLogSessionModel(
      startTime: fields[0] as DateTime,
      endTime: fields[1] as DateTime,
      duration: fields[2] as int,
      reason: fields[3] as String,
      customReason: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeLogSessionModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.endTime)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.customReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLogSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
