import 'package:flutter/foundation.dart';
import 'package:leave_management/data/models/time_adjustment_request_model.dart';
import 'package:leave_management/data/services/time_adjustment_service.dart';

class TimeAdjustmentProvider with ChangeNotifier {
  final TimeAdjustmentService _service;

  List<TimeAdjustmentRequestModel> _myRequests = [];
  List<TimeAdjustmentRequestModel> _allRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  TimeAdjustmentProvider(this._service);

  List<TimeAdjustmentRequestModel> get myRequests => _myRequests;
  List<TimeAdjustmentRequestModel> get allRequests => _allRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> submitRequest({
    required String date,
    String? requestedStartTime,
    String? requestedEndTime,
    required String reason,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final request = await _service.submitRequest(
        date: date,
        requestedStartTime: requestedStartTime,
        requestedEndTime: requestedEndTime,
        reason: reason,
      );
      _myRequests.insert(0, request);
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

  Future<void> fetchMyRequests({String? status}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _myRequests = await _service.getMyRequests(status: status);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchAllRequests({String? status, int? userId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _allRequests = await _service.getAllRequests(
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

  Future<bool> approveRequest(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _service.approveRequest(id);
      _updateInLists(updated);
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

  Future<bool> rejectRequest(int id, String reason) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _service.rejectRequest(id, reason);
      _updateInLists(updated);
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

  void _updateInLists(TimeAdjustmentRequestModel updated) {
    final myIdx = _myRequests.indexWhere((r) => r.id == updated.id);
    if (myIdx != -1) _myRequests[myIdx] = updated;

    final allIdx = _allRequests.indexWhere((r) => r.id == updated.id);
    if (allIdx != -1) _allRequests[allIdx] = updated;
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
