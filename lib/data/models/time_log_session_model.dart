import 'package:hive/hive.dart';

part 'time_log_session_model.g.dart';

@HiveType(typeId: 9)
class TimeLogSessionModel extends HiveObject {
  @HiveField(0)
  final DateTime startTime;

  @HiveField(1)
  final DateTime endTime;

  @HiveField(2)
  final int duration;

  @HiveField(3)
  final String reason;

  @HiveField(4)
  final String? customReason;

  TimeLogSessionModel({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.reason,
    this.customReason,
  });

  factory TimeLogSessionModel.fromJson(Map<String, dynamic> json) {
    return TimeLogSessionModel(
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      duration: json['duration'] ?? 0,
      reason: json['reason'] ?? 'work',
      customReason: json['custom_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration,
      'reason': reason,
      'custom_reason': customReason,
    };
  }
}
