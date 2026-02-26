import 'package:flutter/foundation.dart';
import 'package:leave_management/data/models/leave_model.dart';
import 'package:leave_management/data/models/leave_policy.dart';
import 'package:leave_management/data/services/leave_service.dart';

class LeaveProvider with ChangeNotifier {
  final LeaveService _leaveService;

  List<LeaveModel> _myLeaves = [];
  List<LeaveModel> _allLeaves = [];
  LeavePolicy? _leavePolicy;
  Map<String, int> _leaveBalance = {};
  bool _isLoading = false;
  String? _errorMessage;

  LeaveProvider(this._leaveService);

  List<LeaveModel> get myLeaves => _myLeaves;
  List<LeaveModel> get allLeaves => _allLeaves;
  LeavePolicy? get leavePolicy => _leavePolicy;
  Map<String, int> get leaveBalance => _leaveBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Apply for Leave
  Future<bool> applyLeave({
    required String leaveType,
    required DateTime startDate,
    DateTime? endDate,
    required String reason,
    double? totalDays,
    String? leaveMode,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final leave = await _leaveService.applyLeave(
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        totalDays: totalDays,
        leaveMode: leaveMode,
      );

      _myLeaves.insert(0, leave);
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

  // Get My Leaves
  Future<void> fetchMyLeaves({String? status}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _myLeaves = await _leaveService.getMyLeaves(status: status);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Get All Leaves (Admin/HR)
  Future<void> fetchAllLeaves({String? status, int? userId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _allLeaves = await _leaveService.getAllLeaves(
        status: status,
        userId: userId,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Approve Leave
  Future<bool> approveLeave(int leaveId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedLeave = await _leaveService.approveLeave(leaveId);

      // Update in all leaves list
      final index = _allLeaves.indexWhere((leave) => leave.id == leaveId);
      if (index != -1) {
        _allLeaves[index] = updatedLeave;
      }

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

  // Reject Leave
  Future<bool> rejectLeave({required int leaveId, String? reason}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedLeave = await _leaveService.rejectLeave(
        leaveId: leaveId,
        reason: reason,
      );

      // Update in all leaves list
      final index = _allLeaves.indexWhere((leave) => leave.id == leaveId);
      if (index != -1) {
        _allLeaves[index] = updatedLeave;
      }

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

  // Cancel Leave
  Future<bool> cancelLeave(int leaveId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _leaveService.cancelLeave(leaveId);

      _myLeaves.removeWhere((leave) => leave.id == leaveId);
      _allLeaves.removeWhere((leave) => leave.id == leaveId);

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

  // Get Leave Balance
  Future<void> fetchLeaveBalance() async {
    try {
      _leaveBalance = await _leaveService.getLeaveBalance();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get Leave Policy
  Future<void> fetchLeavePolicy() async {
    try {
      _leavePolicy = await _leaveService.getLeavePolicy();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update Leave Policy (Admin)
  Future<bool> updateLeavePolicy({
    required int casualLeaveCount,
    required int shortLeaveCount,
    String? resetCycle,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _leavePolicy = await _leaveService.updateLeavePolicy(
        casualLeaveCount: casualLeaveCount,
        shortLeaveCount: shortLeaveCount,
        resetCycle: resetCycle,
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
