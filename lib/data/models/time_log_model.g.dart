// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeLogModelAdapter extends TypeAdapter<TimeLogModel> {
  @override
  final int typeId = 2;

  @override
  TimeLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeLogModel(
      id: fields[0] as int,
      userId: fields[1] as int,
      userName: fields[2] as String,
      date: fields[3] as DateTime,
      startTime: fields[4] as DateTime?,
      endTime: fields[5] as DateTime?,
      endReason: fields[6] as String?,
      customReason: fields[7] as String?,
      totalDuration: fields[8] as Duration?,
      isActive: fields[9] as bool,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      dutyTypeId: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeLogModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.endReason)
      ..writeByte(7)
      ..write(obj.customReason)
      ..writeByte(8)
      ..write(obj.totalDuration)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.dutyTypeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
