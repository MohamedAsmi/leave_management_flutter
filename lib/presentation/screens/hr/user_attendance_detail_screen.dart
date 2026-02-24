import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/time_log_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/time_log_service.dart';
import '../../../core/utils/date_time_utils.dart';

class UserAttendanceDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserAttendanceDetailScreen({super.key, required this.user});

  @override
  State<UserAttendanceDetailScreen> createState() => _UserAttendanceDetailScreenState();
}

class _UserAttendanceDetailScreenState extends State<UserAttendanceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TimeLogService _timeLogService;
  bool _isLoading = true;
  List<TimeLogModel> _logs = [];
  Map<String, dynamic>? _reportData;

  // Weekly selector state
  late List<WeekRange> _weeks;
  WeekRange? _selectedWeek;

  // Monthly selector state
  late List<DateTime> _months;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _timeLogService = TimeLogService(context.read<ApiClient>());
    
    _initializeDateRanges();
    _fetchData();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchData();
      }
    });
  }

  void _initializeDateRanges() {
    final now = DateTime.now();
    
    // Initialize Weeks for current year
    _weeks = _generateWeeks(now.year);
    
    // Default to previous week if available, else current week
    final previousWeekIndex = _getPreviousWeekIndex(_weeks, now);
    _selectedWeek = _weeks[previousWeekIndex];

    // Initialize Months for current year
    _months = List.generate(12, (index) => DateTime(now.year, index + 1));
    _selectedMonth = _months[now.month - 1];
  }

  List<WeekRange> _generateWeeks(int year) {
    List<WeekRange> weeks = [];
    DateTime firstDayOfYear = DateTime(year, 1, 1);
    
    // Find first Monday
    DateTime current = firstDayOfYear;
    while (current.weekday != DateTime.monday) {
      current = current.add(const Duration(days: 1));
    }

    int weekNum = 1;
    while (current.year == year) {
      DateTime weekEnd = current.add(const Duration(days: 6));
      weeks.add(WeekRange(
        number: weekNum++,
        start: current,
        end: weekEnd,
      ));
      current = current.add(const Duration(days: 7));
    }
    return weeks;
  }

  int _getPreviousWeekIndex(List<WeekRange> weeks, DateTime now) {
    for (int i = 0; i < weeks.length; i++) {
      if (now.isAfter(weeks[i].start) && now.isBefore(weeks[i].end.add(const Duration(days: 1)))) {
        return i > 0 ? i - 1 : i;
      }
    }
    return weeks.length - 1;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      DateTime startDate;
      DateTime endDate;

      if (_tabController.index == 0) {
        // Weekly
        startDate = _selectedWeek!.start;
        endDate = _selectedWeek!.end;
      } else {
        // Monthly
        startDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
        endDate = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0);
      }

      final logs = await _timeLogService.getAllTimeLogs(
        userId: widget.user.id,
        startDate: startDate,
        endDate: endDate,
      );

      final report = await _timeLogService.getWorkingHoursReport(
        startDate: startDate,
        endDate: endDate,
        userId: widget.user.id,
      );

      if (!mounted) return;
      setState(() {
        _logs = logs;
        _reportData = report.isNotEmpty ? report.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching attendance: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.name}\'s Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          const Text(
                            'Daily Logs',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildLogsList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    if (_tabController.index == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: DropdownButtonFormField<WeekRange>(
          value: _selectedWeek,
          decoration: const InputDecoration(
            labelText: 'Select Week',
            border: OutlineInputBorder(),
          ),
          items: _weeks.map((week) {
            return DropdownMenuItem(
              value: week,
              child: Text('Week ${week.number}: ${DateFormat('MMM d').format(week.start.toLocal())} - ${DateFormat('MMM d').format(week.end.toLocal())}'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedWeek = val);
            _fetchData();
          },
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: DropdownButtonFormField<DateTime>(
          value: _selectedMonth,
          decoration: const InputDecoration(
            labelText: 'Select Month',
            border: OutlineInputBorder(),
          ),
          items: _months.map((month) {
            return DropdownMenuItem(
              value: month,
              child: Text(DateFormat('MMMM yyyy').format(month.toLocal())),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedMonth = val);
            _fetchData();
          },
        ),
      );
    }
  }

  Widget _buildSummaryCards() {
    final totalHours = _reportData?['total_hours'] ?? 0.0;
    final totalDays = _reportData?['total_days'] ?? 0;
    final avgHours = _reportData?['average_hours'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Hours',
            '${totalHours.toStringAsFixed(1)}h',
            Icons.access_time,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Days Worked',
            '$totalDays',
            Icons.work_outline,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg. Hours',
            '${avgHours.toStringAsFixed(1)}h',
            Icons.analytics_outlined,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    if (_logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No logs found for this period'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _logs[index];
        final duration = log.totalDuration ?? Duration.zero;
        
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(
              DateTimeUtils.formatDate(log.date, format: 'EEEE, MMM d'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                if (log.startTime != null) ...[
                  const Icon(Icons.login, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(DateTimeUtils.formatTime(log.startTime!)),
                  const SizedBox(width: 12),
                ],
                if (log.endTime != null) ...[
                  const Icon(Icons.logout, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(DateTimeUtils.formatTime(log.endTime!)),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateTimeUtils.durationToString(duration),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (log.endReason != null)
                  Text(
                    log.endReason!.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WeekRange {
  final int number;
  final DateTime start;
  final DateTime end;

  WeekRange({required this.number, required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekRange && runtimeType == other.runtimeType && number == other.number && start == other.start;

  @override
  int get hashCode => number.hashCode ^ start.hashCode;
}
