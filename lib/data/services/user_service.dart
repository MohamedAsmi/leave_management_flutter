import 'package:leave_management/data/models/user_model.dart';
import 'package:leave_management/data/services/api_client.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  // Get All Users (Admin/HR)
  Future<List<UserModel>> getAllUsers({
    int page = 1,
    int perPage = 20,
    String? role,
    String? search,
  }) async {
    final response = await _apiClient.get('/users', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (role != null) 'role': role,
      if (search != null) 'search': search,
    });

    final usersData = response.data['users'] as List;
    return usersData.map((user) => UserModel.fromJson(user)).toList();
  }

  // Get User by ID
  Future<UserModel> getUserById(int userId) async {
    final response = await _apiClient.get('/users/$userId');
    return UserModel.fromJson(response.data['user']);
  }

  // Create User (Admin)
  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? department,
    String? designation,
    DateTime? joinedDate,
    double? casualLeaveBalance,
    double? medicalLeaveBalance,
    double? annualLeaveBalance,
    double? shortLeaveBalance,
    double? halfDayLeaveBalance,
  }) async {
    final response = await _apiClient.post('/users', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
      if (joinedDate != null) 'joined_date': joinedDate.toIso8601String().split('T')[0],
      if (casualLeaveBalance != null) 'casual_leave_balance': casualLeaveBalance,
      if (medicalLeaveBalance != null) 'medical_leave_balance': medicalLeaveBalance,
      if (annualLeaveBalance != null) 'annual_leave_balance': annualLeaveBalance,
      if (shortLeaveBalance != null) 'short_leave_balance': shortLeaveBalance,
      if (halfDayLeaveBalance != null) 'half_day_leave_balance': halfDayLeaveBalance,
    });

    return UserModel.fromJson(response.data['user']);
  }

  // Update User (Admin)
  Future<UserModel> updateUser({
    required int userId,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? department,
    String? designation,
    int? casualLeaveBalance,
    int? shortLeaveBalance,
    bool? isActive,
  }) async {
    final response = await _apiClient.put('/users/$userId', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
      if (casualLeaveBalance != null) 'casual_leave_balance': casualLeaveBalance,
      if (shortLeaveBalance != null) 'short_leave_balance': shortLeaveBalance,
      if (isActive != null) 'is_active': isActive,
    });

    return UserModel.fromJson(response.data['user']);
  }

  // Delete User (Admin)
  Future<void> deleteUser(int userId) async {
    await _apiClient.delete('/users/$userId');
  }

  // Update Leave Balance (Admin/HR)
  Future<UserModel> updateLeaveBalance({
    required int userId,
    int? casualLeaveBalance,
    int? shortLeaveBalance,
  }) async {
    final response = await _apiClient.post('/users/$userId/update-balance', data: {
      if (casualLeaveBalance != null) 'casual_leave_balance': casualLeaveBalance,
      if (shortLeaveBalance != null) 'short_leave_balance': shortLeaveBalance,
    });

    return UserModel.fromJson(response.data['user']);
  }

  // Get User Statistics (Admin)
  Future<Map<String, dynamic>> getUserStatistics() async {
    final response = await _apiClient.get('/users/statistics');
    return response.data['statistics'];
  }
}
