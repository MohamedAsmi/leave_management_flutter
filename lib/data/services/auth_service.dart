import 'package:leave_management/data/models/user_model.dart';
import 'package:leave_management/data/services/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    return {
      'token': response.data['token'],
      'user': UserModel.fromJson(response.data['user']),
    };
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? department,
  }) async {
    final response = await _apiClient.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'phone': phone,
      'department': department,
    });

    return {
      'token': response.data['token'],
      'user': UserModel.fromJson(response.data['user']),
    };
  }

  // Logout
  Future<void> logout() async {
    await _apiClient.post('/auth/logout');
  }

  // Get Current User
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/auth/user');
    return UserModel.fromJson(response.data['user']);
  }

  // Update Profile
  Future<UserModel> updateProfile({
    required int userId,
    String? name,
    String? phone,
    String? department,
    String? designation,
  }) async {
    final response = await _apiClient.put('/auth/profile/$userId', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
    });

    return UserModel.fromJson(response.data['user']);
  }

  // Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _apiClient.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }

  // Forgot Password
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  // Reset Password
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiClient.post('/auth/reset-password', data: {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }
}
