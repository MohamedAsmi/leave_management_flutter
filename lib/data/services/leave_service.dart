import 'package:leave_management/data/models/leave_model.dart';
import 'package:leave_management/data/models/leave_policy.dart';
import 'package:leave_management/data/services/api_client.dart';

class LeaveService {
  final ApiClient _apiClient;

  LeaveService(this._apiClient);

  // Apply for Leave
  Future<LeaveModel> applyLeave({
    required String leaveType,
    required DateTime startDate,
    DateTime? endDate,
    required String reason,
    double? totalDays,
    String? leaveMode,
    int? userId,
  }) async {
    final response = await _apiClient.post(
      '/leaves',
      data: {
        'leave_type': leaveType,
        'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        'reason': reason,
        if (totalDays != null) 'total_days': totalDays,
        if (leaveMode != null) 'leave_mode': leaveMode,
        if (userId != null) 'user_id': userId,
      },
    );

    return LeaveModel.fromJson(response.data['leave']);
  }

  // Get My Leaves
  Future<List<LeaveModel>> getMyLeaves({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    final response = await _apiClient.get(
      '/leaves/my-leaves',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
      },
    );

    final leavesData = response.data['leaves'] as List;
    return leavesData.map((leave) => LeaveModel.fromJson(leave)).toList();
  }

  // Get All Leaves (Admin/HR)
  Future<List<LeaveModel>> getAllLeaves({
    int page = 1,
    int perPage = 20,
    String? status,
    int? userId,
  }) async {
    final response = await _apiClient.get(
      '/leaves',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (userId != null) 'user_id': userId,
      },
    );

    final leavesData = response.data['leaves'] as List;
    return leavesData.map((leave) => LeaveModel.fromJson(leave)).toList();
  }

  // Get Leave by ID
  Future<LeaveModel> getLeaveById(int leaveId) async {
    final response = await _apiClient.get('/leaves/$leaveId');
    return LeaveModel.fromJson(response.data['leave']);
  }

  // Approve Leave
  Future<LeaveModel> approveLeave(int leaveId) async {
    final response = await _apiClient.post('/leaves/$leaveId/approve');
    return LeaveModel.fromJson(response.data['leave']);
  }

  // Reject Leave
  Future<LeaveModel> rejectLeave({required int leaveId, String? reason}) async {
    final response = await _apiClient.post(
      '/leaves/$leaveId/reject',
      data: {if (reason != null) 'reason': reason},
    );

    return LeaveModel.fromJson(response.data['leave']);
  }

  // Cancel Leave
  Future<LeaveModel> cancelLeave(int leaveId) async {
    final response = await _apiClient.delete('/leaves/$leaveId');
    return LeaveModel.fromJson(response.data['leave']);
  }

  // Get Leave Balance
  Future<Map<String, int>> getLeaveBalance() async {
    final response = await _apiClient.get('/leaves/balance');
    return {
      'casual_leave': response.data['casual_leave'] ?? 0,
      'short_leave': response.data['short_leave'] ?? 0,
    };
  }

  // Get Leave Policy
  Future<LeavePolicy> getLeavePolicy() async {
    final response = await _apiClient.get('/leave-policies');
    return LeavePolicy.fromJson(response.data['policy']);
  }

  // Update Leave Policy (Admin only)
  Future<LeavePolicy> updateLeavePolicy({
    required int casualLeaveCount,
    required int shortLeaveCount,
    String? resetCycle,
  }) async {
    final response = await _apiClient.put(
      '/leave-policies',
      data: {
        'casual_leave_count': casualLeaveCount,
        'short_leave_count': shortLeaveCount,
        if (resetCycle != null) 'reset_cycle': resetCycle,
      },
    );

    return LeavePolicy.fromJson(response.data['policy']);
  }

  // Get Leave Statistics (Admin/HR)
  Future<Map<String, dynamic>> getLeaveStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _apiClient.get(
      '/leaves/statistics',
      queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      },
    );

    return response.data['statistics'];
  }
}
