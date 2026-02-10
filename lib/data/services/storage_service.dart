import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:leave_management/core/constants/app_constants.dart';
import 'package:leave_management/data/models/user_model.dart';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth Token
  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(AppConstants.authTokenKey, token);
  }

  Future<String?> getAuthToken() async {
    return _prefs.getString(AppConstants.authTokenKey);
  }

  Future<void> removeAuthToken() async {
    await _prefs.remove(AppConstants.authTokenKey);
  }

  // User Data
  Future<void> saveUserData(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(AppConstants.userDataKey, userJson);
  }

  Future<UserModel?> getUserData() async {
    final userJson = _prefs.getString(AppConstants.userDataKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  Future<void> removeUserData() async {
    await _prefs.remove(AppConstants.userDataKey);
  }

  // User Role
  Future<void> saveUserRole(String role) async {
    await _prefs.setString(AppConstants.userRoleKey, role);
  }

  Future<String?> getUserRole() async {
    return _prefs.getString(AppConstants.userRoleKey);
  }

  Future<void> removeUserRole() async {
    await _prefs.remove(AppConstants.userRoleKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all data
  Future<void> clearAll() async {
    await removeAuthToken();
    await removeUserData();
    await removeUserRole();
  }

  // Generic methods
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
