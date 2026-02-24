// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LeaveModelAdapter extends TypeAdapter<LeaveModel> {
  @override
  final int typeId = 1;

  @override
  LeaveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeaveModel(
      id: fields[0] as int,
      userId: fields[1] as int,
      userName: fields[2] as String,
      leaveType: fields[3] as String,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime?,
      reason: fields[6] as String,
      status: fields[7] as String,
      approvedBy: fields[8] as int?,
      approvedByName: fields[9] as String?,
      approvedAt: fields[10] as DateTime?,
      rejectionReason: fields[11] as String?,
      totalDays: fields[12] as double,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
      halfDayType: fields[15] as String?,
      leaveMode: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LeaveModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.leaveType)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.approvedBy)
      ..writeByte(9)
      ..write(obj.approvedByName)
      ..writeByte(10)
      ..write(obj.approvedAt)
      ..writeByte(11)
      ..write(obj.rejectionReason)
      ..writeByte(12)
      ..write(obj.totalDays)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.halfDayType)
      ..writeByte(16)
      ..write(obj.leaveMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
