class TimeAdjustmentRequestModel {
  final int id;
  final int userId;
  final String userName;
  final DateTime date;
  final DateTime? requestedStartTime;
  final DateTime? requestedEndTime;
  final String reason;
  final String status;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? approvedLeaveType;

  TimeAdjustmentRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    this.requestedStartTime,
    this.requestedEndTime,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.approvedLeaveType,
  });

  factory TimeAdjustmentRequestModel.fromJson(Map<String, dynamic> json) {
    return TimeAdjustmentRequestModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      requestedStartTime: json['requested_start_time'] != null
          ? DateTime.parse(json['requested_start_time'])
          : null,
      requestedEndTime: json['requested_end_time'] != null
          ? DateTime.parse(json['requested_end_time'])
          : null,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      approvedLeaveType: json['approved_leave_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'date': date.toIso8601String(),
      'requested_start_time': requestedStartTime?.toIso8601String(),
      'requested_end_time': requestedEndTime?.toIso8601String(),
      'reason': reason,
      'status': status,
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'approved_at': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'approved_leave_type': approvedLeaveType,
    };
  }
}
