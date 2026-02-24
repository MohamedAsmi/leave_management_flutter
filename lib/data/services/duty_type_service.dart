import 'package:leave_management/data/models/duty_type_model.dart';
import 'package:leave_management/data/services/api_client.dart';

class DutyTypeService {
  final ApiClient _apiClient;

  DutyTypeService(this._apiClient);

  Future<List<DutyType>> getDutyTypes() async {
    final response = await _apiClient.get('/duty-types');
    final data = response.data['duty_types'] as List;
    return data.map((e) => DutyType.fromJson(e)).toList();
  }
}
