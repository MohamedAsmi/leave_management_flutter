import 'package:leave_management/data/models/time_log_model.dart';
import 'package:leave_management/data/services/api_client.dart';

class TimeLogService {
  final ApiClient _apiClient;

  TimeLogService(this._apiClient);

  // Start Work Session
  Future<TimeLogModel> startSession({int? dutyTypeId}) async {
    final response = await _apiClient.post(
      '/time-logs/start',
      data: {
        if (dutyTypeId != null) 'duty_type_id': dutyTypeId,
      },
    );
    return TimeLogModel.fromJson(response.data['time_log']);
  }

  // End Work Session
  Future<TimeLogModel> endSession({
    required int timeLogId,
    required String endReason,
    String? customReason,
  }) async {
    final response = await _apiClient.post('/time-logs/$timeLogId/end', data: {
      'end_reason': endReason,
      if (customReason != null) 'custom_reason': customReason,
    });

    return TimeLogModel.fromJson(response.data['time_log']);
  }

  // Resume Session
  Future<TimeLogModel> resumeSession(int timeLogId, {int? dutyTypeId}) async {
    final response = await _apiClient.post(
      '/time-logs/$timeLogId/resume',
      data: {
        if (dutyTypeId != null) 'duty_type_id': dutyTypeId,
      },
    );
    return TimeLogModel.fromJson(response.data['time_log']);
  }

  // Update Time Log (Admin/HR)
  Future<TimeLogModel> updateTimeLog(int timeLogId, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '/time-logs/$timeLogId',
      data: data,
    );
    return TimeLogModel.fromJson(response.data['time_log']);
  }

  // Create Time Log (Admin/HR)
  Future<TimeLogModel> createTimeLogHr(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/time-logs/hr-create',
      data: data,
    );
    return TimeLogModel.fromJson(response.data['time_log']);
  }

  // Get Active Session
  Future<TimeLogModel?> getActiveSession() async {
    try {
      final response = await _apiClient.get('/time-logs/active');
      if (response.data['time_log'] != null) {
        return TimeLogModel.fromJson(response.data['time_log']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get My Time Logs
  Future<List<TimeLogModel>> getMyTimeLogs({
    int page = 1,
    int perPage = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _apiClient.get('/time-logs/my-logs', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    });

    final logsData = response.data['time_logs'] as List;
    return logsData.map((log) => TimeLogModel.fromJson(log)).toList();
  }

  // Get All Time Logs (Admin/HR)
  Future<List<TimeLogModel>> getAllTimeLogs({
    int page = 1,
    int perPage = 20,
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _apiClient.get('/time-logs', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (userId != null) 'user_id': userId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    });

    final logsData = response.data['time_logs'] as List;
    return logsData.map((log) => TimeLogModel.fromJson(log)).toList();
  }

  // Get Time Log by ID
  Future<TimeLogModel> getTimeLogById(int timeLogId) async {
    final response = await _apiClient.get('/time-logs/$timeLogId');
    return TimeLogModel.fromJson(response.data['time_log']);
  }

  // Get Today's Working Hours
  Future<Duration> getTodayWorkingHours() async {
    final response = await _apiClient.get('/time-logs/today-hours');
    final seconds = response.data['total_seconds'] ?? 0;
    return Duration(seconds: seconds);
  }

  // Get Monthly Working Hours
  Future<Map<String, dynamic>> getMonthlyWorkingHours({
    required int month,
    required int year,
  }) async {
    final response = await _apiClient.get('/time-logs/monthly-hours', queryParameters: {
      'month': month,
      'year': year,
    });

    return {
      'total_hours': response.data['total_hours'] ?? 0,
      'total_days': response.data['total_days'] ?? 0,
      'average_hours': response.data['average_hours'] ?? 0,
    };
  }

  // Get Working Hours Report (Admin/HR)
  Future<List<Map<String, dynamic>>> getWorkingHoursReport({
    required DateTime startDate,
    required DateTime endDate,
    int? userId,
  }) async {
    final response = await _apiClient.get('/time-logs/report', queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      if (userId != null) 'user_id': userId,
    });

    final reportData = response.data['report'] as List;
    return reportData.map((item) => item as Map<String, dynamic>).toList();
  }

  // Get Comprehensive Report for CSV (Admin/HR)
  Future<List<Map<String, dynamic>>> getComprehensiveReport({
    required DateTime startDate,
    required DateTime endDate,
    int? userId,
  }) async {
    final response = await _apiClient.get('/time-logs/comprehensive-report', queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      if (userId != null) 'user_id': userId,
    });

    final reportData = response.data['report'] as List;
    return reportData.map((item) => item as Map<String, dynamic>).toList();
  }

  // Get Attendance Summary
  Future<Map<String, dynamic>> getAttendanceSummary({
    required int month,
    required int year,
  }) async {
    final response = await _apiClient.get('/time-logs/attendance-summary', queryParameters: {
      'month': month,
      'year': year,
    });

    return response.data['summary'];
  }
}
