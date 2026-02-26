import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../providers/time_log_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/week_picker_dialog.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/leave_model.dart';
import '../../../data/models/time_log_model.dart';

class UserWeeklyReportScreen extends StatefulWidget {
  final UserModel? initialUser;

  const UserWeeklyReportScreen({super.key, this.initialUser});

  @override
  State<UserWeeklyReportScreen> createState() => _UserWeeklyReportScreenState();
}

class _UserWeeklyReportScreenState extends State<UserWeeklyReportScreen> {
  UserModel? _selectedUser;
  DateTime _selectedWeekStart = DateTime.now();
  bool _isLoading = false;

  List<UserModel> _allUsers = [];
  List<LeaveModel> _userLeaves = [];
  List<TimeLogModel> _userTimeLogs = [];

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.initialUser;
    _selectedWeekStart = _getWeekStart(DateTime.now());
    _loadData();
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the week
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getWeekEnd(DateTime weekStart) {
    // Get Sunday of the week
    return weekStart.add(const Duration(days: 6));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.fetchAllUsers();

      setState(() {
        _allUsers = userProvider.users;
        if (_selectedUser == null && _allUsers.isNotEmpty) {
          _selectedUser = _allUsers.first;
        }
      });

      if (_selectedUser != null) {
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    if (_selectedUser == null) return;

    try {
      final leaveProvider = context.read<LeaveProvider>();
      final timeLogProvider = context.read<TimeLogProvider>();

      await Future.wait([
        leaveProvider.fetchAllLeaves(),
        timeLogProvider.fetchAllTimeLogs(),
      ]);

      final weekEnd = _getWeekEnd(_selectedWeekStart);

      setState(() {
        _userLeaves = leaveProvider.allLeaves
            .where((leave) =>
                leave.userId == _selectedUser!.id &&
                (leave.startDate.isAfter(_selectedWeekStart.subtract(const Duration(days: 1))) &&
                    leave.startDate.isBefore(weekEnd.add(const Duration(days: 1)))))
            .toList();

        _userTimeLogs = timeLogProvider.allTimeLogs
            .where((log) =>
                log.userId == _selectedUser!.id &&
                log.startTime != null &&
                log.startTime!.isAfter(_selectedWeekStart.subtract(const Duration(days: 1))) &&
                log.startTime!.isBefore(weekEnd.add(const Duration(days: 1))))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
    _loadUserData();
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
    _loadUserData();
  }

  void _selectWeek() async {
    final DateTime? picked = await showWeekPicker(
      context: context,
      initialDate: _selectedWeekStart,
    );

    if (picked != null) {
      setState(() {
        _selectedWeekStart = picked;
      });
      _loadUserData();
    }
  }

  // Calculate statistics
  static const double _expectedWeeklyHours = 40.0;

  double get _totalHours {
    return _userTimeLogs.fold<double>(
      0.0,
      (sum, log) => sum + ((log.totalDuration?.inMinutes ?? 0) / 60.0),
    );
  }

  double get _balanceHours {
    return _expectedWeeklyHours - _totalHours;
  }

  double get _avgHoursPerDay {
    if (_daysWorked == 0) return 0.0;
    return _totalHours / _daysWorked; // Average across days actually worked
  }

  int get _daysWorked {
    final uniqueDays = <String>{};
    for (var log in _userTimeLogs) {
      if (log.startTime != null) {
        uniqueDays.add(DateFormat('yyyy-MM-dd').format(log.startTime!));
      }
    }
    return uniqueDays.length;
  }

  int get _leaveDays => _userLeaves.where((l) => l.status == 'approved').length;

  Map<String, double> get _dailyHours {
    final Map<String, double> daily = {};
    final weekEnd = _getWeekEnd(_selectedWeekStart);

    // Initialize all days in the week
    for (int i = 0; i < 7; i++) {
      final day = _selectedWeekStart.add(Duration(days: i));
      final dateKey = DateFormat('EEE\nMMM dd').format(day);
      daily[dateKey] = 0.0;
    }

    // Fill in actual hours
    for (var log in _userTimeLogs) {
      if (log.startTime != null) {
        final dateKey = DateFormat('EEE\nMMM dd').format(log.startTime!);
        final hours = (log.totalDuration?.inMinutes ?? 0) / 60.0;
        daily[dateKey] = (daily[dateKey] ?? 0) + hours;
      }
    }

    return daily;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Weekly Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildUserSelector(),
                _buildWeekSelector(),
                Expanded(
                  child: _selectedUser == null
                      ? const Center(child: Text('Please select a user'))
                      : _buildReportContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildUserSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<UserModel>(
              value: _selectedUser,
              decoration: const InputDecoration(
                labelText: 'Select Employee',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _allUsers.map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text(
                    '${user.name} - ${user.department ?? "No Dept"}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (user) {
                setState(() {
                  _selectedUser = user;
                });
                _loadUserData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final weekEnd = _getWeekEnd(_selectedWeekStart);
    final isCurrentWeek = _getWeekStart(DateTime.now()).isAtSameMomentAs(_selectedWeekStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousWeek,
            tooltip: 'Previous Week',
          ),
          Expanded(
            child: InkWell(
              onTap: _selectWeek,
              child: Column(
                children: [
                  Text(
                    isCurrentWeek ? 'This Week' : 'Selected Week',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM dd').format(_selectedWeekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextWeek,
            tooltip: 'Next Week',
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmployeeCard(),
            const SizedBox(height: 16),
            _buildWeeklySummary(),
            const SizedBox(height: 16),
            _buildDailyBreakdown(),
            const SizedBox(height: 16),
            _buildLeavesSection(),
            const SizedBox(height: 16),
            _buildAttendanceDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(
                _selectedUser!.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedUser!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedUser!.designation ?? 'No Designation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedUser!.department ?? 'No Department',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedUser!.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedUser!.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: _selectedUser!.isActive ? AppColors.success : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    final balanceHours = _balanceHours;
    final isOnTrack = balanceHours <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Expected Hours',
                '${_expectedWeeklyHours.toStringAsFixed(1)} hrs',
                Icons.flag,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Hours',
                '${_totalHours.toStringAsFixed(1)} hrs',
                Icons.access_time,
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Balance Hours',
                '${balanceHours.abs().toStringAsFixed(1)} hrs',
                Icons.schedule_outlined,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Days Worked',
                '$_daysWorked days',
                Icons.event_available,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Avg/Day',
                '${_avgHoursPerDay.toStringAsFixed(1)} hrs',
                Icons.schedule,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Leaves',
                '$_leaveDays days',
                Icons.beach_access,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    final dailyHours = _dailyHours;
    final maxHours = dailyHours.values.fold<double>(0, (max, val) => val > max ? val : max);
    final normalizedMax = maxHours > 0 ? maxHours : 8.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Hours Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyHours.entries.map((entry) {
                final height = (entry.value / normalizedMax * 100).clamp(0, 100);
                final isToday = entry.key.contains(DateFormat('MMM dd').format(DateTime.now()));

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          entry.value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: entry.value > 0 ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height + 20,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: entry.value > 0
                                ? (isToday ? AppColors.success : AppColors.primary)
                                : Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday ? AppColors.success : Colors.grey[600],
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeavesSection() {
    if (_userLeaves.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 12),
              const Text('No leaves this week'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaves This Week',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._userLeaves.map((leave) {
              Color statusColor;
              IconData statusIcon;

              switch (leave.status) {
                case 'approved':
                  statusColor = AppColors.success;
                  statusIcon = Icons.check_circle;
                  break;
                case 'rejected':
                  statusColor = AppColors.error;
                  statusIcon = Icons.cancel;
                  break;
                default:
                  statusColor = AppColors.warning;
                  statusIcon = Icons.hourglass_empty;
              }

              return ListTile(
                leading: Icon(statusIcon, color: statusColor),
                title: Text(_formatLeaveType(leave.leaveType)),
                subtitle: Text(
                  '${DateFormat('MMM dd').format(leave.startDate)}${leave.endDate != null ? ' - ${DateFormat('MMM dd').format(leave.endDate!)}' : ''}',
                ),
                trailing: Chip(
                  label: Text(
                    leave.status.toUpperCase(),
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  padding: EdgeInsets.zero,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceDetails() {
    if (_userTimeLogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[400], size: 48),
              const SizedBox(height: 8),
              Text(
                'No attendance records for this week',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Sort logs by date
    final sortedLogs = List<TimeLogModel>.from(_userTimeLogs)
      ..sort((a, b) {
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...sortedLogs.map((log) {
              final hours = (log.totalDuration?.inMinutes ?? 0) / 60.0;
              final date = log.startTime != null
                  ? DateFormat('EEE, MMM dd').format(log.startTime!)
                  : 'Unknown';
              
              // Check if time component exists (not midnight 00:00)
              bool hasStartTime = log.startTime != null && 
                  (log.startTime!.hour != 0 || log.startTime!.minute != 0);
              bool hasEndTime = log.endTime != null && 
                  (log.endTime!.hour != 0 || log.endTime!.minute != 0);

              String timeDisplay;
              if (hasStartTime && hasEndTime) {
                timeDisplay = '${DateFormat('HH:mm').format(log.startTime!)} - ${DateFormat('HH:mm').format(log.endTime!)}';
              } else if (hasStartTime && log.endTime != null && !hasEndTime) {
                timeDisplay = '${DateFormat('HH:mm').format(log.startTime!)} - Active';
              } else if (log.totalDuration != null) {
                // Show duration only if times are not properly recorded
                timeDisplay = 'Duration: ${hours.toStringAsFixed(1)} hrs';
              } else {
                timeDisplay = 'No time recorded';
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.info.withValues(alpha: 0.2),
                  child: Icon(Icons.schedule, color: AppColors.info, size: 20),
                ),
                title: Text(date),
                subtitle: Text(
                  timeDisplay,
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${hours.toStringAsFixed(1)} hrs',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatLeaveType(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return 'Casual Leave';
      case 'short':
        return 'Short Leave';
      case 'half_day':
        return 'Half Day Leave';
      case 'other':
        return 'Other Leave';
      default:
        return type;
    }
  }
}
