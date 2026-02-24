import 'package:flutter/foundation.dart';
import 'package:leave_management/data/models/user_model.dart';
import 'package:leave_management/data/services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService;

  UserProvider(this._userService);

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Fetch all users
  Future<void> fetchAllUsers({String? role, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _userService.getAllUsers(
        role: role,
        search: search,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(int userId) async {
    try {
      return await _userService.getUserById(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Create new user
  Future<UserModel?> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? department,
    String? designation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUser = await _userService.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        department: department,
        designation: designation,
      );
      
      // Refresh the users list
      await fetchAllUsers();
      
      _error = null;
      return newUser;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user
  Future<UserModel?> updateUser({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _userService.updateUser(
        userId: userId,
        name: name,
        email: email,
        role: role,
        phone: phone,
        department: department,
        designation: designation,
        casualLeaveBalance: casualLeaveBalance,
        shortLeaveBalance: shortLeaveBalance,
        isActive: isActive,
      );
      
      // Refresh the users list
      await fetchAllUsers();
      
      _error = null;
      return updatedUser;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.deleteUser(userId);
      
      // Refresh the users list
      await fetchAllUsers();
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter users by role
  List<UserModel> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Filter active users
  List<UserModel> get activeUsers {
    return _users.where((user) => user.isActive).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
