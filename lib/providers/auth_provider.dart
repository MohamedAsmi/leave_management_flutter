import 'package:flutter/foundation.dart';
import 'package:leave_management/data/models/user_model.dart';
import 'package:leave_management/data/services/auth_service.dart';
import 'package:leave_management/data/services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService, this._storageService);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // Login
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _authService.login(email: email, password: password);

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      await _storageService.saveAuthToken(token);
      await _storageService.saveUserData(user);
      await _storageService.saveUserRole(user.role);

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? department,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        department: department,
      );

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      await _storageService.saveAuthToken(token);
      await _storageService.saveUserData(user);
      await _storageService.saveUserRole(user.role);

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore error on logout
    }

    await _storageService.clearAll();
    _currentUser = null;
    _setLoading(false);
    notifyListeners();
  }

  // Load User from Storage
  Future<void> loadUserFromStorage() async {
    _setLoading(true);

    try {
      final user = await _storageService.getUserData();
      if (user != null) {
        _currentUser = user;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _setLoading(false);
    notifyListeners();
  }

  // Refresh User Data
  Future<void> refreshUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      await _storageService.saveUserData(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? department,
    String? designation,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authService.updateProfile(
        userId: _currentUser!.id,
        name: name,
        phone: phone,
        department: department,
        designation: designation,
      );

      await _storageService.saveUserData(user);
      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
