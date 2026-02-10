class LeavePolicy {
  final int id;
  final int casualLeaveCount;
  final int shortLeaveCount;
  final int halfDayLeaveCount;
  final String resetCycle; // monthly, yearly
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeavePolicy({
    required this.id,
    required this.casualLeaveCount,
    required this.shortLeaveCount,
    required this.halfDayLeaveCount,
    this.resetCycle = 'yearly',
    this.createdAt,
    this.updatedAt,
  });

  factory LeavePolicy.fromJson(Map<String, dynamic> json) {
    return LeavePolicy(
      id: json['id'] ?? 0,
      casualLeaveCount: json['casual_leave_count'] ?? 0,
      shortLeaveCount: json['short_leave_count'] ?? 0,
      halfDayLeaveCount: json['half_day_leave_count'] ?? 0,
      resetCycle: json['reset_cycle'] ?? 'yearly',
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
      'casual_leave_count': casualLeaveCount,
      'short_leave_count': shortLeaveCount,
      'half_day_leave_count': halfDayLeaveCount,
      'reset_cycle': resetCycle,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  LeavePolicy copyWith({
    int? id,
    int? casualLeaveCount,
    int? shortLeaveCount,
    int? halfDayLeaveCount,
    String? resetCycle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeavePolicy(
      id: id ?? this.id,
      casualLeaveCount: casualLeaveCount ?? this.casualLeaveCount,
      shortLeaveCount: shortLeaveCount ?? this.shortLeaveCount,
      halfDayLeaveCount: halfDayLeaveCount ?? this.halfDayLeaveCount,
      resetCycle: resetCycle ?? this.resetCycle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
