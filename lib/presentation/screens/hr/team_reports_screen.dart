import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../providers/time_log_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/leave_model.dart';
import '../../../data/models/time_log_model.dart';

class TeamReportsScreen extends StatefulWidget {
  const TeamReportsScreen({super.key});

  @override
  State<TeamReportsScreen> createState() => _TeamReportsScreenState();
}

class _TeamReportsScreenState extends State<TeamReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  // Analytics data
  List<UserModel> _allUsers = [];
  List<LeaveModel> _allLeaves = [];
  List<TimeLogModel> _allTimeLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = context.read<UserProvider>();
      final leaveProvider = context.read<LeaveProvider>();
      final timeLogProvider = context.read<TimeLogProvider>();

      await Future.wait([
        userProvider.fetchAllUsers(),
        leaveProvider.fetchAllLeaves(),
        timeLogProvider.fetchAllTimeLogs(),
      ]);

      setState(() {
        _allUsers = userProvider.users;
        _allLeaves = leaveProvider.allLeaves;
        _allTimeLogs = timeLogProvider.allTimeLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  // Calculate statistics
  int get _totalEmployees => _allUsers.length;
  
  int get _activeEmployees => _allUsers.where((u) => u.isActive).length;

  List<LeaveModel> get _filteredLeaves => _allLeaves.where((leave) {
        final leaveDate = leave.startDate;
        return leaveDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            leaveDate.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

  int get _pendingLeaves => _filteredLeaves
      .where((l) => l.status == 'pending')
      .length;

  int get _approvedLeaves => _filteredLeaves
      .where((l) => l.status == 'approved')
      .length;

  int get _rejectedLeaves => _filteredLeaves
      .where((l) => l.status == 'rejected')
      .length;

  List<TimeLogModel> get _filteredTimeLogs => _allTimeLogs.where((log) {
        if (log.startTime == null) return false;
        final logDate = log.startTime!;
        return logDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            logDate.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

  double get _avgWorkingHours {
    if (_filteredTimeLogs.isEmpty) return 0.0;
    final totalMinutes = _filteredTimeLogs.fold<int>(
      0,
      (sum, log) => sum + (log.totalDuration?.inMinutes ?? 0),
    );
    return totalMinutes / _filteredTimeLogs.length / 60;
  }

  Map<String, int> get _departmentDistribution {
    final Map<String, int> distribution = {};
    for (var user in _allUsers) {
      final dept = user.department ?? 'Unassigned';
      distribution[dept] = (distribution[dept] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> get _leaveTypeDistribution {
    final Map<String, int> distribution = {};
    for (var leave in _filteredLeaves) {
      if (leave.status == 'approved') {
        final type = leave.leaveType;
        distribution[type] = (distribution[type] ?? 0) + 1;
      }
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Leave Reports'),
            Tab(text: 'Attendance'),
            Tab(text: 'Departments'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateRangeChip(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildLeaveReportsTab(),
                      _buildAttendanceTab(),
                      _buildDepartmentsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateRangeChip() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _selectDateRange,
            child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Employees',
                    _totalEmployees.toString(),
                    Icons.people,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    _activeEmployees.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Leaves',
                    _filteredLeaves.length.toString(),
                    Icons.event_busy,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Avg Hours/Day',
                    '${_avgWorkingHours.toStringAsFixed(2)} hrs',
                    Icons.access_time,
                    AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveReportsTab() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    _pendingLeaves.toString(),
                    Icons.hourglass_empty,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Approved',
                    _approvedLeaves.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rejected',
                    _rejectedLeaves.toString(),
                    Icons.cancel,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLeaveTypeDistribution(),
            const SizedBox(height: 24),
            _buildTopLeaveUsers(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Total Work Sessions',
              _filteredTimeLogs.length.toString(),
              Icons.work,
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Average Working Hours',
              '${_avgWorkingHours.toStringAsFixed(2)} hrs/session',
              Icons.timer,
              AppColors.info,
            ),
            const SizedBox(height: 24),
            _buildTopWorkingUsers(),
            const SizedBox(height: 24),
            _buildAttendanceTrends(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department-wise Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDepartmentDistribution(),
            const SizedBox(height: 24),
            _buildDepartmentLeaveStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Work Sessions', _filteredTimeLogs.length.toString()),
            const Divider(),
            _buildStatRow('Pending Leave Requests', _pendingLeaves.toString()),
            const Divider(),
            _buildStatRow('Approved Leaves', _approvedLeaves.toString()),
            const Divider(),
            _buildStatRow('Average Hours/Day', '${_avgWorkingHours.toStringAsFixed(2)} hrs'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeDistribution() {
    final distribution = _leaveTypeDistribution;
    
    if (distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No leave data available')),
        ),
      );
    }

    final total = distribution.values.fold<int>(0, (sum, val) => sum + val);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave Type Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatLeaveType(entry.key),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(2)}%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        _getLeaveTypeColor(entry.key),
                      ),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopLeaveUsers() {
    final Map<int, int> userLeaveCount = {};
    
    for (var leave in _filteredLeaves) {
      if (leave.status == 'approved') {
        userLeaveCount[leave.userId] = (userLeaveCount[leave.userId] ?? 0) + 1;
      }
    }

    final sortedEntries = userLeaveCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topUsers = sortedEntries.take(5).toList();

    if (topUsers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No leave data available')),
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
              'Top Leave Takers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final userId = entry.value.key;
              final leaveCount = entry.value.value;
              final user = _allUsers.firstWhere(
                (u) => u.id == userId,
                orElse: () => UserModel(
                  id: userId,
                  name: 'Unknown User',
                  email: '',
                  role: '',
                  casualLeaveBalance: 0,
                  shortLeaveBalance: 0,
                  halfDayLeaveBalance: 0,
                  isActive: true,
                ),
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.department ?? 'No Department'),
                trailing: Chip(
                  label: Text('$leaveCount leaves'),
                  backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                ),
                onTap: () {
                  context.push('/hr/user-weekly-report', extra: user);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopWorkingUsers() {
    final Map<int, double> userWorkHours = {};
    
    for (var log in _filteredTimeLogs) {
      final hours = (log.totalDuration?.inMinutes ?? 0) / 60;
      userWorkHours[log.userId] = (userWorkHours[log.userId] ?? 0) + hours;
    }

    final sortedEntries = userWorkHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topUsers = sortedEntries.take(5).toList();

    if (topUsers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No attendance data available')),
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
              'Top Performers by Hours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final userId = entry.value.key;
              final hours = entry.value.value;
              final user = _allUsers.firstWhere(
                (u) => u.id == userId,
                orElse: () => UserModel(
                  id: userId,
                  name: 'Unknown User',
                  email: '',
                  role: '',
                  casualLeaveBalance: 0,
                  shortLeaveBalance: 0,
                  halfDayLeaveBalance: 0,
                  isActive: true,
                ),
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.department ?? 'No Department'),
                trailing: Chip(
                  label: Text('${hours.toStringAsFixed(2)} hrs'),
                  backgroundColor: AppColors.success.withValues(alpha: 0.2),
                ),
                onTap: () {
                  context.push('/hr/user-weekly-report', extra: user);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTrends() {
    final Map<String, int> dailyAttendance = {};
    
    for (var log in _filteredTimeLogs) {
      if (log.startTime != null) {
        final date = log.startTime!;
        final dateKey = DateFormat('MMM dd').format(date);
        dailyAttendance[dateKey] = (dailyAttendance[dateKey] ?? 0) + 1;
      }
    }

    if (dailyAttendance.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No attendance trends available')),
        ),
      );
    }

    final sortedEntries = dailyAttendance.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Attendance Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.take(10).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / _activeEmployees,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppColors.info),
                        minHeight: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentDistribution() {
    final distribution = _departmentDistribution;

    if (distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No department data available')),
        ),
      );
    }

    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Distribution by Department',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final percentage = (entry.value / _totalEmployees * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(2)}%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentLeaveStats() {
    final Map<String, int> deptLeaves = {};
    
    for (var leave in _filteredLeaves) {
      if (leave.status == 'approved') {
        final user = _allUsers.firstWhere(
          (u) => u.id == leave.userId,
          orElse: () => UserModel(
            id: leave.userId,
            name: 'Unknown',
            email: '',
            role: '',
            casualLeaveBalance: 0,
            shortLeaveBalance: 0,
            halfDayLeaveBalance: 0,
            isActive: true,
          ),
        );
        final dept = user.department ?? 'Unassigned';
        deptLeaves[dept] = (deptLeaves[dept] ?? 0) + 1;
      }
    }

    if (deptLeaves.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No department leave data available')),
        ),
      );
    }

    final sortedEntries = deptLeaves.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaves by Department',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                  child: const Icon(Icons.business, color: AppColors.warning),
                ),
                title: Text(entry.key),
                trailing: Chip(
                  label: Text('${entry.value} leaves'),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
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

  Color _getLeaveTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return AppColors.primary;
      case 'short':
        return AppColors.info;
      case 'half_day':
        return AppColors.warning;
      case 'other':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey[400]!;
      case 2:
        return Colors.brown[300]!;
      default:
        return AppColors.primary;
    }
  }
}
