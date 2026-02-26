// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 8;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as int,
      projectId: fields[1] as int,
      projectName: fields[2] as String?,
      title: fields[3] as String,
      description: fields[4] as String,
      status: fields[5] as String,
      priority: fields[6] as String,
      assignedTo: fields[7] as int?,
      assignedToName: fields[8] as String?,
      assignedToEmail: fields[9] as String?,
      createdBy: fields[10] as int,
      createdByName: fields[11] as String?,
      dueDate: fields[12] as DateTime?,
      completedAt: fields[13] as DateTime?,
      estimatedHours: fields[14] as double?,
      actualHours: fields[15] as double?,
      createdAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.projectName)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.assignedTo)
      ..writeByte(8)
      ..write(obj.assignedToName)
      ..writeByte(9)
      ..write(obj.assignedToEmail)
      ..writeByte(10)
      ..write(obj.createdBy)
      ..writeByte(11)
      ..write(obj.createdByName)
      ..writeByte(12)
      ..write(obj.dueDate)
      ..writeByte(13)
      ..write(obj.completedAt)
      ..writeByte(14)
      ..write(obj.estimatedHours)
      ..writeByte(15)
      ..write(obj.actualHours)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
