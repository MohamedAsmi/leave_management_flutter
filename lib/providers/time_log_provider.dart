import 'package:flutter/foundation.dart';
import 'package:leave_management/data/models/time_log_model.dart';
import 'package:leave_management/data/services/time_log_service.dart';

class TimeLogProvider with ChangeNotifier {
  final TimeLogService _timeLogService;

  TimeLogModel? _activeSession;
  List<TimeLogModel> _myTimeLogs = [];
  List<TimeLogModel> _allTimeLogs = [];
  Duration? _todayWorkingHours;
  bool _isLoading = false;
  String? _errorMessage;

  TimeLogProvider(this._timeLogService);

  TimeLogModel? get activeSession => _activeSession;
  List<TimeLogModel> get myTimeLogs => _myTimeLogs;
  List<TimeLogModel> get allTimeLogs => _allTimeLogs;
  Duration? get todayWorkingHours => _todayWorkingHours;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSession => _activeSession != null;

  // Check if duty is completed today
  // This checks if there's any completed session today with the reason "End of workday"
  bool get isDutyCompletedToday {
    final today = DateTime.now();
    return _myTimeLogs.any((log) {
      final localDate = log.date.toLocal();
      final isToday = localDate.year == today.year &&
          localDate.month == today.month &&
          localDate.day == today.day;
      return isToday &&
          ((log.endReason == 'other' &&
                  log.customReason == 'End of workday') ||
              log.endReason == 'half_day' &&
                  log.customReason == 'second half');
    });
  }

  // Check if duty has started today (any log exists for today)
  bool get hasDutyStartedToday {
    final today = DateTime.now();
    return _myTimeLogs.any((log) {
      final localDate = log.date.toLocal();
      return localDate.year == today.year &&
          localDate.month == today.month &&
          localDate.day == today.day;
    });
  }

  // Get the ID of the last log (for resuming)
  int? get lastLogId => _myTimeLogs.isNotEmpty ? _myTimeLogs.first.id : null;

  // Start Work Session
  Future<bool> startSession({int? dutyTypeId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _activeSession = await _timeLogService.startSession(dutyTypeId: dutyTypeId);
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

  // End Work Session
  Future<bool> endSession({
    required String endReason,
    String? customReason,
  }) async {
    if (_activeSession == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final endedSession = await _timeLogService.endSession(
        timeLogId: _activeSession!.id,
        endReason: endReason,
        customReason: customReason,
      );

      _activeSession = null;
      _myTimeLogs.insert(0, endedSession);
      await fetchTodayWorkingHours();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      // If session is already ended on server (404), clear local session and return success
      if (e.toString().contains('404') || e.toString().contains('No active session found')) {
        _activeSession = null;
        _errorMessage = null;
        await fetchTodayWorkingHours();
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Resume Session
  Future<bool> resumeSession(int timeLogId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Try to find the log locally to get its duty type
      TimeLogModel? logToResume;
      try {
        logToResume = _myTimeLogs.firstWhere((log) => log.id == timeLogId);
      } catch (_) {}

      // If not found locally, we could fetch it, but for now let's rely on what we have.
      // If we don't have it, we default to 1 (Office) to strictly avoid 500 errors.
      
      int? dutyTypeId = logToResume?.dutyTypeId;
      
      // Fallback for legacy logs or missing data
      dutyTypeId ??= 1;

      _activeSession = await _timeLogService.resumeSession(
        timeLogId, 
        dutyTypeId: dutyTypeId,
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

  // Get Active Session
  Future<void> fetchActiveSession() async {
    try {
      _activeSession = await _timeLogService.getActiveSession();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get My Time Logs
  Future<void> fetchMyTimeLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _myTimeLogs = await _timeLogService.getMyTimeLogs(
        startDate: startDate,
        endDate: endDate,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Get All Time Logs (Admin/HR)
  Future<void> fetchAllTimeLogs({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _allTimeLogs = await _timeLogService.getAllTimeLogs(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Get Today's Working Hours
  Future<void> fetchTodayWorkingHours() async {
    try {
      _todayWorkingHours = await _timeLogService.getTodayWorkingHours();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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
