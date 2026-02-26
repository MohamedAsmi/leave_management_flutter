import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/core/utils/date_time_utils.dart';
import 'package:leave_management/providers/auth_provider.dart';
import 'package:leave_management/providers/leave_provider.dart';
import 'package:leave_management/providers/time_log_provider.dart';
import 'package:leave_management/providers/notification_provider.dart';
import 'package:leave_management/providers/duty_type_provider.dart';
import 'package:leave_management/presentation/screens/staff/time_log_screen.dart';
import 'package:leave_management/presentation/screens/staff/apply_leave_screen.dart';
import 'package:leave_management/presentation/screens/staff/leave_detail_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final leaveProvider = context.read<LeaveProvider>();
    final timeLogProvider = context.read<TimeLogProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    await Future.wait([
      leaveProvider.fetchMyLeaves(),
      timeLogProvider.fetchActiveSession(),
      timeLogProvider.fetchTodayWorkingHours(),
      timeLogProvider.fetchMyTimeLogs(),
      notificationProvider.fetchUnreadCount(),
      notificationProvider.fetchNotifications(),
    ]);
  }

  void _showNotifications() {
    context.push('/notifications');
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'leave_application':
        return Icons.event_note;
      case 'leave_approval':
        return Icons.check_circle;
      case 'leave_rejection':
        return Icons.cancel;
      case 'time_management':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Notifications
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      _showNotifications();
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notifProvider.unreadCount > 9
                              ? '9+'
                              : '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Profile Menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                // TODO: Navigate to profile
              } else if (value == 'logout') {
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(user?.name ?? 'User'),
              const SizedBox(height: 24),

              // Time Tracking Card
              _buildTimeTrackingCard(),
              const SizedBox(height: 16),

              // Leave Balance Cards
              _buildLeaveBalanceCards(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Recent Leaves
              _buildRecentLeaves(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String name) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateTimeUtils.formatDate(
                DateTime.now(),
                format: 'EEEE, MMMM dd, yyyy',
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTrackingCard() {
    return Consumer<TimeLogProvider>(
      builder: (context, timeLogProvider, _) {
        final hasActiveSession = timeLogProvider.hasActiveSession;
        final activeSession = timeLogProvider.activeSession;
        final todayHours = timeLogProvider.todayWorkingHours;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasActiveSession
                          ? Icons.access_time
                          : Icons.access_time_outlined,
                      color: hasActiveSession
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time Tracking',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Session Status
                if (hasActiveSession && activeSession != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: AppColors.success,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Session Active',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Started: ${DateTimeUtils.formatTime(activeSession.startTime ?? DateTime.now())}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle_outlined, size: 12),
                        SizedBox(width: 8),
                        Text('No Active Session'),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Today's Hours
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Working Hours:",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      todayHours != null
                          ? DateTimeUtils.durationToString(todayHours)
                          : '0h 0m',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Hours Breakdown
                _buildHoursBreakdown(),

                const SizedBox(height: 16),

                // Action Buttons
                SizedBox(
                  height: 48, // Fixed height for a balanced look
                  child: Row(
                    children: [
                      // START BUTTON
                      Expanded(
                        child: ElevatedButton(
                          onPressed: timeLogProvider.hasDutyStartedToday
                              ? null // Disable if duty started today (permanently for the day)
                              : () async {
                                  _showDutyTypeSelectionDialog();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: timeLogProvider.isDutyCompletedToday
                                ? Colors.grey // Visual cue for ended duty
                                : AppColors.success,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero, // Ensures text fits
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                timeLogProvider.isDutyCompletedToday ? Icons.check_circle : Icons.play_arrow,
                                size: 20
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeLogProvider.isDutyCompletedToday ? 'Completed' : 'Start',
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // PAUSE / RESUME BUTTON
                      Expanded(
                        child: OutlinedButton(
                          onPressed: hasActiveSession
                              ? () => _showEndSessionDialog()
                              : (timeLogProvider.hasDutyStartedToday && !timeLogProvider.isDutyCompletedToday)
                                  ? () async {
                                      final lastId = timeLogProvider.lastLogId;
                                      if (lastId != null) {
                                        final success = await timeLogProvider.resumeSession(lastId);
                                        if (context.mounted && success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Session resumed!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                          await _loadData();
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('No previous session to resume found.'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: hasActiveSession
                                  ? AppColors.warning
                                  : (timeLogProvider.hasDutyStartedToday && !timeLogProvider.isDutyCompletedToday
                                      ? AppColors.success
                                      : Colors.grey),
                            ),
                            foregroundColor: hasActiveSession
                                ? AppColors.warning
                                : (timeLogProvider.hasDutyStartedToday && !timeLogProvider.isDutyCompletedToday
                                    ? AppColors.success
                                    : Colors.grey),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(hasActiveSession ? Icons.pause : Icons.play_arrow, size: 20),
                              SizedBox(width: 4),
                              Text(
                                hasActiveSession ? 'Pause' : 'Resume',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // END DUTY BUTTON
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (hasActiveSession || (timeLogProvider.hasDutyStartedToday && !timeLogProvider.isDutyCompletedToday))
                              ? () => _endDutyToday()
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: (hasActiveSession || (timeLogProvider.hasDutyStartedToday && !timeLogProvider.isDutyCompletedToday))
                                  ? AppColors.error
                                  : Colors.grey,
                            ),
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop, size: 20),
                              SizedBox(width: 4),
                              Text('End', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaveBalanceCards() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Row(
      children: [
        Expanded(
          child: _buildBalanceCard(
            'Annual',
            user?.annualLeaveBalance ?? 0,
            Icons.calendar_month,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBalanceCard(
            'Medical',
            user?.medicalLeaveBalance ?? 0,
            Icons.medical_services,
            Colors.redAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBalanceCard(
            'Casual',
            user?.casualLeaveBalance ?? 0,
            Icons.beach_access,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBalanceCard(
            'Short',
            user?.shortLeaveBalance ?? 0,
            Icons.schedule,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
      String title, num count, IconData icon, Color color) {
    // Format to remove trailing .0 if generic integer
    String formattedCount = count % 1 == 0 ? count.toInt().toString() : count.toString();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            formattedCount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHoursBreakdown() {
    final timeLogProvider = context.watch<TimeLogProvider>();

    // Required daily hours
    const int requiredMinutes = 8 * 60; // 8 hours in minutes

    // Get today's worked time
    final todayHours = timeLogProvider.todayWorkingHours;
    final workedMinutes = todayHours != null ? todayHours.inMinutes : 0;

    // Calculate breaks taken today from time logs
    int prayerMinutes = 0;
    int lunchMinutes = 0;

    // Check today's logs for prayer and lunch breaks
    final today = DateTime.now();
    final todayLogs = timeLogProvider.myTimeLogs.where((log) {
      if (log.startTime == null) return false;
      final logDate = DateTime(
        log.startTime!.year,
        log.startTime!.month,
        log.startTime!.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);
      return logDate.isAtSameMomentAs(todayDate);
    }).toList();

    for (final log in todayLogs) {
      if (log.endReason == 'prayer') {
        prayerMinutes += 15; // 15 mins for prayer
      } else if (log.endReason == 'lunch') {
        lunchMinutes += 60; // 1 hour for lunch
      }
    }

    // Check if short leave or half day is applied for today
    final leaveProvider = context.watch<LeaveProvider>();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Count short leaves for today
    int shortLeaveCount = 0;
    int halfDayMinutes = 0;

    for (final leave in leaveProvider.myLeaves) {
      if (leave.status == 'rejected') continue;

      final startDate = DateTime(
        leave.startDate.year,
        leave.startDate.month,
        leave.startDate.day,
      );
      final endDate = leave.endDate != null
          ? DateTime(
              leave.endDate!.year,
              leave.endDate!.month,
              leave.endDate!.day,
            )
          : startDate;

      // Check if today falls within the leave period
      if (todayDate.isAtSameMomentAs(startDate) ||
          todayDate.isAtSameMomentAs(endDate) ||
          (todayDate.isAfter(startDate) && todayDate.isBefore(endDate))) {
        if (leave.leaveType == 'short') {
          shortLeaveCount++;
        } else if (leave.leaveType == 'half_day') {
          halfDayMinutes = 4 * 60; // 4 hours
        }
      }
    }

    // Calculate short leave minutes
    // 2 or more short leaves = half day (4 hours)
    int shortLeaveMinutes = 0;
    if (shortLeaveCount >= 2) {
      halfDayMinutes = 4 * 60; // 2 short leaves = half day
      shortLeaveMinutes = 0; // Don't count short leaves separately
    } else if (shortLeaveCount == 1) {
      shortLeaveMinutes = 2 * 60; // 1 short leave = 2 hours
    }

    // Calculate balance
    final totalDeductions =
        prayerMinutes + lunchMinutes + shortLeaveMinutes + halfDayMinutes;
    final balanceMinutes = requiredMinutes - workedMinutes - totalDeductions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remaining Hours',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: balanceMinutes > 0
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Balance: ${_formatMinutes(balanceMinutes)}',
                  style: TextStyle(
                    color: balanceMinutes > 0
                        ? AppColors.error
                        : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Required hours
          _buildBreakdownRow(
            'Required Hours',
            '8h 0m',
            Icons.work_outline,
            AppColors.primary,
            isRequired: true,
          ),
          const SizedBox(height: 8),

          // Worked hours
          _buildBreakdownRow(
            'Worked Hours',
            DateTimeUtils.durationToString(todayHours ?? Duration.zero),
            Icons.timer,
            AppColors.success,
          ),

          // Prayer time (if taken)
          if (prayerMinutes > 0) ...[
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'Prayer Time',
              _formatMinutes(prayerMinutes),
              Icons.mosque,
              AppColors.secondary,
            ),
          ],

          // Lunch time (if taken)
          if (lunchMinutes > 0) ...[
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'Lunch Break',
              _formatMinutes(lunchMinutes),
              Icons.restaurant,
              AppColors.warning,
            ),
          ],

          // Short leave (if applied)
          if (shortLeaveMinutes > 0) ...[
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'Short Leave',
              _formatMinutes(shortLeaveMinutes),
              Icons.schedule,
              AppColors.error,
            ),
          ],

          // Half day (if applied)
          if (halfDayMinutes > 0) ...[
            const SizedBox(height: 8),
            _buildBreakdownRow(
              shortLeaveCount >= 2
                  ? 'Half Day ($shortLeaveCount Short Leaves)'
                  : 'Half Day Leave',
              _formatMinutes(halfDayMinutes),
              Icons.event_busy,
              Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String time,
    IconData icon,
    Color color, {
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 0) {
      return '0h 0m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Apply Leave',
              Icons.event_available,
              AppColors.primary,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ApplyLeaveScreen(),
                  ),
                ).then((_) => _loadData());
              },
            ),
            _buildActionCard(
              'My Leaves',
              Icons.list_alt,
              AppColors.secondary,
              () {
                context.push('/my-leaves');
              },
            ),
            _buildActionCard(
              'My Projects',
              Icons.folder,
              Colors.purple,
              () {
                context.push('/staff/projects');
              },
            ),
            _buildActionCard(
              'My Tasks',
              Icons.task_alt,
              Colors.orange,
              () {
                context.push('/staff/tasks');
              },
            ),
            _buildActionCard(
              'Time Logs',
              Icons.history,
              AppColors.info,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TimeLogScreen()),
                );
              },
            ),
            _buildActionCard('Profile', Icons.person, AppColors.warning, () {
              // TODO: Navigate to profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile - Coming Soon')),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLeaves() {
    return Consumer<LeaveProvider>(
      builder: (context, leaveProvider, _) {
        final leaves = leaveProvider.myLeaves.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Leaves',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    context.push('/my-leaves');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (leaves.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No leave applications yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeaveDetailScreen(leave: leave),
                          ),
                        ).then((_) => _loadData());
                      },
                      leading: CircleAvatar(
                        backgroundColor: _getLeaveStatusColor(
                          leave.status,
                        ).withOpacity(0.2),
                        child: Icon(
                          _getLeaveIcon(leave.leaveType),
                          color: _getLeaveStatusColor(leave.status),
                        ),
                      ),
                      title: Text(
                        _getLeaveTypeLabel(leave.leaveType),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        (leave.leaveType == 'half_day' ||
                                leave.leaveMode == 'first_half' ||
                                leave.leaveMode == 'second_half')
                            ? '${DateTimeUtils.formatDate(leave.startDate)} - ${leave.formattedLeaveMode}'
                            : '${DateTimeUtils.formatDate(leave.startDate)} - ${leave.endDate != null ? DateTimeUtils.formatDate(leave.endDate!) : 'Same day'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(
                              leave.status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: _getLeaveStatusColor(
                              leave.status,
                            ).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _getLeaveStatusColor(leave.status),
                            ),
                          ),
                          if (leave.status == 'pending')
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'cancel') {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Cancel Leave'),
                                      content: const Text(
                                        'Are you sure you want to cancel this leave application?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('No'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error,
                                          ),
                                          child: const Text('Yes, Cancel'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true && context.mounted) {
                                    final leaveProvider = context
                                        .read<LeaveProvider>();
                                    final authProvider = context
                                        .read<AuthProvider>();
                                    final scaffoldMessenger =
                                        ScaffoldMessenger.of(context);

                                    final success = await leaveProvider
                                        .cancelLeave(leave.id);

                                    if (success) {
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Leave cancelled successfully',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      await _loadData();
                                      await authProvider.refreshUserData();
                                    } else {
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            leaveProvider.errorMessage !=
                                                        null &&
                                                    leaveProvider.errorMessage!
                                                        .contains(
                                                          'No query results',
                                                        )
                                                ? 'Leave not found. Refreshing list...'
                                                : 'Failed to cancel leave. Please try again.',
                                          ),
                                          backgroundColor: AppColors.error,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                      // Refresh the list even on error
                                      await _loadData();
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Cancel Leave'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select reason for ending session:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Lunch Break'),
              leading: const Icon(Icons.restaurant),
              onTap: () => _endSession('lunch', context),
            ),
            ListTile(
              title: const Text('Prayer Break'),
              leading: const Icon(Icons.mosque),
              onTap: () => _endSession('prayer', context),
            ),
            ListTile(
              title: const Text('Short Leave'),
              leading: const Icon(Icons.schedule),
              onTap: () async {
                Navigator.pop(context);
                await _endSessionAndApplyShortLeave();
              },
            ),
            // ListTile(
            //   title: const Text('Half Day'),
            //   leading: const Icon(Icons.event_busy),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _showHalfDaySelectionDialog();
            //   },
            // ),
            // ListTile(
            //   title: const Text('End Work Today'),
            //   leading: const Icon(Icons.work_off),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _endSession('other', context, customReason: 'End of workday');
            //   },
            // ),
            ListTile(
              title: const Text('Other'),
              leading: const Icon(Icons.more_horiz),
              onTap: () {
                Navigator.pop(context);
                _showCustomReasonDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _endDutyToday() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: const [
          Icon(Icons.stop_circle, color: AppColors.error),
          SizedBox(width: 8),
          Text(
            'End Duty Today',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to end your duty for today? '
        'This will finalize your working hours and stop time tracking.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: () {
                _endSession('other', context, customReason: 'End of workday');
              },
          child: const Text('End'),
        ),
      ],
    ),
  );
}


  void _showCustomReasonDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Reason'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Custom Reason',
            hintText: 'Please specify your reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final customReason = reasonController.text.trim();
              if (customReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              _endSession('other', context, customReason: customReason);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession(
    String reason,
    BuildContext dialogContext, {
    String? customReason,
  }) async {
    Navigator.pop(dialogContext);
    final timeLogProvider = context.read<TimeLogProvider>();
    final success = await timeLogProvider.endSession(
      endReason: reason,
      customReason: customReason,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session ended successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
    }
  }

  Future<void> _endSessionAndApplyShortLeave() async {
    final timeLogProvider = context.read<TimeLogProvider>();
    final leaveProvider = context.read<LeaveProvider>();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Apply short leave directly (backend handles logic)
    final success = await leaveProvider.applyLeave(
      leaveType: 'short',
      startDate: DateTime.now(),
      reason: 'Short leave taken during work hours',
      totalDays: 1,
    );

    if (success) {
      // ONLY end session if leave application succeeds
      await timeLogProvider.endSession(endReason: 'short_leave');
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Session ended and short leave applied successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
      await authProvider.refreshUserData();
    } else {
      final errorMessage = leaveProvider.errorMessage ?? 'Failed to apply leave';
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDutyTypeSelectionDialog() {
    final dutyTypeProvider = context.read<DutyTypeProvider>();
    // Ensure we have latest data from storage
    dutyTypeProvider.loadFromCache(); 
    // Actually provider loads on main. Be safe and just use what's there or trigger load if empty.
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Duty Type'),
        content: Consumer<DutyTypeProvider>(
          builder: (context, DutyTypeProvider provider, _) {
            if (provider.isLoading) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (provider.dutyTypes.isEmpty) {
               // Try fetching if empty
               provider.fetchAndCacheDutyTypes();
               return const SizedBox(
                 height: 100,
                 child: Center(child: CircularProgressIndicator()),
               );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.dutyTypes.length,
                itemBuilder: (context, index) {
                  final type = provider.dutyTypes[index];
                  return ListTile(
                    title: Text(type.name),
                    subtitle: type.type != null ? Text(type.type!) : null,
                    leading: const Icon(Icons.work),
                    onTap: () async {
                      Navigator.pop(context); // Close dialog
                      await _startSession(type.id);
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(int dutyTypeId) async {
    final timeLogProvider = context.read<TimeLogProvider>();
    final success = await timeLogProvider.startSession(dutyTypeId: dutyTypeId);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session started!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
    }
  }




  Color _getLeaveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.approved;
      case 'rejected':
        return AppColors.rejected;
      case 'pending':
      default:
        return AppColors.pending;
    }
  }

  IconData _getLeaveIcon(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return Icons.beach_access;
      case 'short':
        return Icons.schedule;
      case 'half_day':
        return Icons.event_busy;
      default:
        return Icons.event_available;
    }
  }

  String _getLeaveTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return 'Casual Leave';
      case 'short':
        return 'Short Leave';
      case 'half_day':
        return 'Half Day Leave';
      default:
        return 'Leave';
    }
  }
}
