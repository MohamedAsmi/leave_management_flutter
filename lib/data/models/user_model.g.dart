// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as int,
      name: fields[1] as String,
      email: fields[2] as String,
      role: fields[3] as String,
      phone: fields[4] as String?,
      department: fields[5] as String?,
      designation: fields[6] as String?,
      profileImage: fields[7] as String?,
      joinedDate: fields[8] as DateTime?,
      casualLeaveBalance: fields[9] as double,
      shortLeaveBalance: fields[10] as double,
      halfDayLeaveBalance: fields[14] as double,
      annualLeaveBalance: fields[15] as double,
      medicalLeaveBalance: fields[16] as double,
      isActive: fields[11] as bool,
      createdAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.department)
      ..writeByte(6)
      ..write(obj.designation)
      ..writeByte(7)
      ..write(obj.profileImage)
      ..writeByte(8)
      ..write(obj.joinedDate)
      ..writeByte(9)
      ..write(obj.casualLeaveBalance)
      ..writeByte(10)
      ..write(obj.shortLeaveBalance)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.halfDayLeaveBalance)
      ..writeByte(15)
      ..write(obj.annualLeaveBalance)
      ..writeByte(16)
      ..write(obj.medicalLeaveBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
