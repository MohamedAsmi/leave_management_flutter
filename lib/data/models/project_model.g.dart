// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectModelAdapter extends TypeAdapter<ProjectModel> {
  @override
  final int typeId = 6;

  @override
  ProjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectModel(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      status: fields[3] as String,
      priority: fields[4] as String,
      progress: fields[5] as int,
      budget: fields[6] as double?,
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime,
      projectManagerId: fields[9] as int,
      projectManagerName: fields[10] as String?,
      projectManagerEmail: fields[11] as String?,
      members: (fields[12] as List?)?.cast<ProjectMember>(),
      totalTasks: fields[13] as int?,
      completedTasks: fields[14] as int?,
      createdAt: fields[15] as DateTime?,
      updatedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.budget)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.projectManagerId)
      ..writeByte(10)
      ..write(obj.projectManagerName)
      ..writeByte(11)
      ..write(obj.projectManagerEmail)
      ..writeByte(12)
      ..write(obj.members)
      ..writeByte(13)
      ..write(obj.totalTasks)
      ..writeByte(14)
      ..write(obj.completedTasks)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProjectMemberAdapter extends TypeAdapter<ProjectMember> {
  @override
  final int typeId = 7;

  @override
  ProjectMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectMember(
      id: fields[0] as int,
      name: fields[1] as String,
      email: fields[2] as String,
      role: fields[3] as String,
      joinedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectMember obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.joinedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
