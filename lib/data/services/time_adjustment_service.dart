import 'package:leave_management/data/models/time_adjustment_request_model.dart';
import 'package:leave_management/data/services/api_client.dart';

class TimeAdjustmentService {
  final ApiClient _apiClient;

  TimeAdjustmentService(this._apiClient);

  Future<TimeAdjustmentRequestModel> submitRequest({
    required String date,
    String? requestedStartTime,
    String? requestedEndTime,
    required String reason,
  }) async {
    final response = await _apiClient.post(
      '/time-adjustment-requests',
      data: {
        'date': date,
        if (requestedStartTime != null)
          'requested_start_time': requestedStartTime,
        if (requestedEndTime != null) 'requested_end_time': requestedEndTime,
        'reason': reason,
      },
    );
    return TimeAdjustmentRequestModel.fromJson(response.data['request']);
  }

  Future<List<TimeAdjustmentRequestModel>> getMyRequests({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    final response = await _apiClient.get(
      '/time-adjustment-requests/my-requests',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
      },
    );
    final data = response.data['requests'] as List;
    return data
        .map((item) => TimeAdjustmentRequestModel.fromJson(item))
        .toList();
  }

  Future<List<TimeAdjustmentRequestModel>> getAllRequests({
    int page = 1,
    int perPage = 20,
    String? status,
    int? userId,
  }) async {
    final response = await _apiClient.get(
      '/time-adjustment-requests',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (userId != null) 'user_id': userId,
      },
    );
    final data = response.data['requests'] as List;
    return data
        .map((item) => TimeAdjustmentRequestModel.fromJson(item))
        .toList();
  }

  Future<TimeAdjustmentRequestModel> approveRequest(int id) async {
    final response = await _apiClient.post(
      '/time-adjustment-requests/$id/approve',
    );
    return TimeAdjustmentRequestModel.fromJson(response.data['request']);
  }

  Future<TimeAdjustmentRequestModel> rejectRequest(
    int id,
    String reason,
  ) async {
    final response = await _apiClient.post(
      '/time-adjustment-requests/$id/reject',
      data: {'reason': reason},
    );
    return TimeAdjustmentRequestModel.fromJson(response.data['request']);
  }
}
