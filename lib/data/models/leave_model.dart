import 'package:hive/hive.dart';

part 'leave_model.g.dart';

@HiveType(typeId: 1)
class LeaveModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final String leaveType; // casual, short, half_day, other

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime? endDate;

  @HiveField(6)
  final String reason;

  @HiveField(7)
  final String status; // pending, approved, rejected

  @HiveField(8)
  final int? approvedBy;

  @HiveField(9)
  final String? approvedByName;

  @HiveField(10)
  final DateTime? approvedAt;

  @HiveField(11)
  final String? rejectionReason;

  @HiveField(12)
  final double totalDays;

  @HiveField(13)
  final DateTime? createdAt;

  @HiveField(14)
  final DateTime? updatedAt;

  @HiveField(15)
  final String? halfDayType; // 'first_half' or 'second_half' - keeping for backward compatibility

  @HiveField(16)
  final String? leaveMode; // 'full_day', 'first_half', 'second_half'

  LeaveModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.leaveType,
    required this.startDate,
    this.endDate,
    required this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.totalDays = 1.0,
    this.createdAt,
    this.updatedAt,
    this.halfDayType,
    this.leaveMode,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      leaveType: json['leave_type'] ?? 'casual',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      totalDays: (json['total_days'] ?? 1).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      halfDayType: json['half_day_type'],
      leaveMode: json['leave_mode'] ?? json['half_day_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'reason': reason,
      'status': status,
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'total_days': totalDays,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (halfDayType != null) 'half_day_type': halfDayType,
      if (leaveMode != null) 'leave_mode': leaveMode,
    };
  }

  LeaveModel copyWith({
    int? id,
    int? userId,
    String? userName,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? status,
    int? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    double? totalDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? halfDayType,
    String? leaveMode,
  }) {
    return LeaveModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      totalDays: totalDays ?? this.totalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      halfDayType: halfDayType ?? this.halfDayType,
      leaveMode: leaveMode ?? this.leaveMode,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get formattedLeaveMode {
    if (leaveMode == null) return 'Full Day';
    switch (leaveMode) {
      case 'first_half':
        return 'First Half';
      case 'second_half':
        return 'Second Half';
      case 'full_day':
        return 'Full Day';
      default:
        return leaveMode!.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
    }
  }
}
