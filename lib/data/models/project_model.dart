import 'package:hive/hive.dart';

part 'project_model.g.dart';

@HiveType(typeId: 6)
class ProjectModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String status; // planning, in_progress, on_hold, completed, cancelled

  @HiveField(4)
  final String priority; // low, medium, high, urgent

  @HiveField(5)
  final int progress; // 0-100

  @HiveField(6)
  final double? budget;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final DateTime endDate;

  @HiveField(9)
  final int projectManagerId;

  @HiveField(10)
  final String? projectManagerName;

  @HiveField(11)
  final String? projectManagerEmail;

  @HiveField(12)
  final List<ProjectMember>? members;

  @HiveField(13)
  final int? totalTasks;

  @HiveField(14)
  final int? completedTasks;

  @HiveField(15)
  final DateTime? createdAt;

  @HiveField(16)
  final DateTime? updatedAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    this.status = 'planning',
    this.priority = 'medium',
    this.progress = 0,
    this.budget,
    required this.startDate,
    required this.endDate,
    required this.projectManagerId,
    this.projectManagerName,
    this.projectManagerEmail,
    this.members,
    this.totalTasks,
    this.completedTasks,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    List<ProjectMember>? membersList;
    if (json['members'] != null) {
      membersList = (json['members'] as List)
          .map((m) => ProjectMember.fromJson(m))
          .toList();
    }

    return ProjectModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'planning',
      priority: json['priority'] ?? 'medium',
      progress: json['progress'] ?? 0,
      budget: json['budget'] != null ? double.parse(json['budget'].toString()) : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      projectManagerId: json['project_manager_id'] ?? 0,
      projectManagerName: json['project_manager']?['name'],
      projectManagerEmail: json['project_manager']?['email'],
      members: membersList,
      totalTasks: json['total_tasks'],
      completedTasks: json['completed_tasks'],
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
      'name': name,
      'description': description,
      'status': status,
      'priority': priority,
      'progress': progress,
      'budget': budget,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'project_manager_id': projectManagerId,
      'project_manager_name': projectManagerName,
      'project_manager_email': projectManagerEmail,
      'members': members?.map((m) => m.toJson()).toList(),
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  String get statusLabel {
    switch (status) {
      case 'planning':
        return 'Planning';
      case 'in_progress':
        return 'In Progress';
      case 'on_hold':
        return 'On Hold';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
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

  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  bool get isOverdue {
    return DateTime.now().isAfter(endDate) && status != 'completed';
  }

  bool get isActive {
    return status == 'in_progress' || status == 'planning';
  }
}

@HiveType(typeId: 7)
class ProjectMember extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String role; // member, lead, contributor

  @HiveField(4)
  final DateTime? joinedAt;

  ProjectMember({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'member',
    this.joinedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }

  String get roleLabel {
    switch (role) {
      case 'lead':
        return 'Lead';
      case 'contributor':
        return 'Contributor';
      case 'member':
        return 'Member';
      default:
        return role;
    }
  }
}
