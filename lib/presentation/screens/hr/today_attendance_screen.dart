import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_time_utils.dart';
import 'package:leave_management/providers/time_log_provider.dart';

class TodayAttendanceScreen extends StatefulWidget {
  const TodayAttendanceScreen({super.key});

  @override
  State<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends State<TodayAttendanceScreen> {
  String _filterStatus = 'all'; // all, active, ended

  @override
  void initState() {
    super.initState();
    // Load attendance immediately
    Future.microtask(() {
      if (mounted) {
        _loadAttendance();
      }
    });
  }

  Future<void> _loadAttendance() async {
    try {
      final timeLogProvider = context.read<TimeLogProvider>();
      await timeLogProvider.fetchAllTimeLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<TimeLogProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading attendance',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.errorMessage ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final todayLogs = provider.allTimeLogs.where((log) {
            if (log.startTime == null) return false;
            final today = DateTime.now();
            final logDate = DateTime(
              log.startTime!.year,
              log.startTime!.month,
              log.startTime!.day,
            );
            final todayDate = DateTime(today.year, today.month, today.day);
            return logDate.isAtSameMomentAs(todayDate);
          }).toList();

          // Apply filter
          final filteredLogs = todayLogs.where((log) {
            if (_filterStatus == 'active') {
              return log.endTime == null;
            } else if (_filterStatus == 'ended') {
              return log.endTime != null;
            }
            return true;
          }).toList();

          // Calculate statistics
          final activeCount = todayLogs.where((log) => log.endTime == null).length;
          final endedCount = todayLogs.length - activeCount;

          return Column(
            children: [
              // Statistics Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, 
                          size: 20, 
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'All records: ${provider.allTimeLogs.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            todayLogs.length.toString(),
                            Icons.people,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Active',
                            activeCount.toString(),
                            Icons.work,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Ended',
                            endedCount.toString(),
                            Icons.work_off,
                            AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all', todayLogs.length),
                          _buildFilterChip('Active', 'active', activeCount),
                          _buildFilterChip('Ended', 'ended', endedCount),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Attendance List
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filterStatus == 'all'
                                  ? 'No attendance records today'
                                  : _filterStatus == 'active'
                                      ? 'No active sessions'
                                      : 'No ended sessions',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (provider.allTimeLogs.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Total records in system: ${provider.allTimeLogs.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _handleRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return _buildAttendanceCard(log);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(log) {
    final isActive = log.endTime == null;
    // Use the total duration from API instead of calculating manually
    final totalDuration = log.totalDuration ?? Duration.zero;

    // Get color based on end reason
    Color getEndReasonColor(String? reason) {
      if (reason == null) return AppColors.info;
      switch (reason.toLowerCase()) {
        case 'lunch':
          return AppColors.warning;
        case 'prayer':
          return AppColors.secondary;
        case 'short_leave':
          return AppColors.error;
        case 'half_day':
          return Colors.orange;
        case 'other':
          return Colors.purple;
        default:
          return AppColors.info;
      }
    }

    String getEndReasonLabel(String? reason, String? customReason) {
      if (reason == null) return 'Ended';
      switch (reason.toLowerCase()) {
        case 'lunch':
          return 'Lunch';
        case 'prayer':
          return 'Prayer';
        case 'short_leave':
          return 'Short Leave';
        case 'half_day':
          return 'Half Day';
        case 'other':
          return customReason ?? 'Other';
        default:
          return 'Ended';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isActive
                      ? AppColors.success.withOpacity(0.1)
                      : getEndReasonColor(log.endReason).withOpacity(0.1),
                  child: Icon(
                    isActive ? Icons.work : Icons.work_off,
                    color: isActive
                        ? AppColors.success
                        : getEndReasonColor(log.endReason),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${log.userId}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.1)
                        : getEndReasonColor(log.endReason).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive
                        ? 'Active'
                        : getEndReasonLabel(log.endReason, log.customReason),
                    style: TextStyle(
                      color: isActive
                          ? AppColors.success
                          : getEndReasonColor(log.endReason),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo(
                      'Start Time',
                      log.startTime != null && (log.startTime!.hour != 0 || log.startTime!.minute != 0)
                          ? DateFormat('h:mm a').format(log.startTime!)
                          : 'Not recorded',
                      Icons.login,
                      AppColors.success,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _buildTimeInfo(
                      'End Time',
                      log.endTime != null
                          ? (log.endTime!.hour != 0 || log.endTime!.minute != 0)
                              ? DateFormat('h:mm a').format(log.endTime!)
                              : 'Not recorded'
                          : 'Ongoing',
                      Icons.logout,
                      log.endTime != null
                          ? getEndReasonColor(log.endReason)
                          : AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _buildTimeInfo(
                      'Duration',
                      DateTimeUtils.durationToString(totalDuration),
                      Icons.timer,
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (log.endReason != null && log.customReason != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.customReason!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
