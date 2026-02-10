import 'package:hive/hive.dart';

part 'time_log_model.g.dart';

@HiveType(typeId: 2)
class TimeLogModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final DateTime? startTime;

  @HiveField(5)
  final DateTime? endTime;

  @HiveField(6)
  final String? endReason; // lunch, prayer, short_leave, half_day, other

  @HiveField(7)
  final String? customReason;

  @HiveField(8)
  final Duration? totalDuration;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final DateTime? createdAt;

  @HiveField(11)
  final DateTime? updatedAt;

  TimeLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    this.startTime,
    this.endTime,
    this.endReason,
    this.customReason,
    this.totalDuration,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TimeLogModel.fromJson(Map<String, dynamic> json) {
    return TimeLogModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      endReason: json['end_reason'],
      customReason: json['custom_reason'],
      totalDuration: json['total_duration'] != null
          ? Duration(seconds: json['total_duration'])
          : null,
      isActive: json['is_active'] ?? true,
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
      'user_id': userId,
      'user_name': userName,
      'date': date.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'end_reason': endReason,
      'custom_reason': customReason,
      'total_duration': totalDuration?.inSeconds,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TimeLogModel copyWith({
    int? id,
    int? userId,
    String? userName,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? endReason,
    String? customReason,
    Duration? totalDuration,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endReason: endReason ?? this.endReason,
      customReason: customReason ?? this.customReason,
      totalDuration: totalDuration ?? this.totalDuration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
