import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 8)
class TaskModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int projectId;

  @HiveField(2)
  final String? projectName;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String status; // todo, in_progress, in_review, completed, blocked

  @HiveField(6)
  final String priority; // low, medium, high, urgent

  @HiveField(7)
  final int? assignedTo;

  @HiveField(8)
  final String? assignedToName;

  @HiveField(9)
  final String? assignedToEmail;

  @HiveField(10)
  final int createdBy;

  @HiveField(11)
  final String? createdByName;

  @HiveField(12)
  final DateTime? dueDate;

  @HiveField(13)
  final DateTime? completedAt;

  @HiveField(14)
  final double? estimatedHours;

  @HiveField(15)
  final double? actualHours;

  @HiveField(16)
  final DateTime? createdAt;

  @HiveField(17)
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.title,
    required this.description,
    this.status = 'todo',
    this.priority = 'medium',
    this.assignedTo,
    this.assignedToName,
    this.assignedToEmail,
    required this.createdBy,
    this.createdByName,
    this.dueDate,
    this.completedAt,
    this.estimatedHours,
    this.actualHours,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      projectId: json['project_id'] ?? 0,
      projectName: json['project']?['name'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_user']?['name'],
      assignedToEmail: json['assigned_user']?['email'],
      createdBy: json['created_by'] ?? 0,
      createdByName: json['creator']?['name'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      estimatedHours: json['estimated_hours'] != null
          ? double.parse(json['estimated_hours'].toString())
          : null,
      actualHours: json['actual_hours'] != null
          ? double.parse(json['actual_hours'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'assigned_to_email': assignedToEmail,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'completed_at': completedAt?.toIso8601String(),
      'estimated_hours': estimatedHours,
      'actual_hours': actualHours,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  String get statusLabel {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'in_progress':
        return 'In Progress';
      case 'in_review':
        return 'In Review';
      case 'completed':
        return 'Completed';
      case 'blocked':
        return 'Blocked';
      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != 'completed';
  }

  bool get isCompleted {
    return status == 'completed';
  }

  bool get isAssignedToMe {
    // This will be checked in the UI with current user ID
    return assignedTo != null;
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  double? get hoursVariance {
    if (estimatedHours == null || actualHours == null) return null;
    return actualHours! - estimatedHours!;
  }
}
