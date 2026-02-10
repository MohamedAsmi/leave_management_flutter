import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../providers/time_log_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_time_utils.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final leaveProvider = context.read<LeaveProvider>();
    final timeLogProvider = context.read<TimeLogProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    await Future.wait([
      leaveProvider.fetchAllLeaves(),
      leaveProvider.fetchMyLeaves(), // Add personal leaves
      timeLogProvider.fetchAllTimeLogs(),
      timeLogProvider.fetchActiveSession(), // Add personal session
      timeLogProvider.fetchTodayWorkingHours(), // Add personal hours
      notificationProvider.fetchNotifications(),
    ]);
  }

  Future<void> _handleRefresh() async {
    await _loadDashboardData();
  }

  void _showNotifications() {
    final notificationProvider = context.read<NotificationProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notifications'),
            TextButton(
              onPressed: () async {
                await notificationProvider.markAllAsRead();
              },
              child: const Text('Mark all read'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.notifications.isEmpty) {
                return const Center(child: Text('No notifications'));
              }

              return ListView.builder(
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return Card(
                    color: notification.isRead
                        ? null
                        : AppColors.info.withOpacity(0.1),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.isRead
                            ? Colors.grey
                            : AppColors.primary,
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notification.message),
                          const SizedBox(height: 4),
                          Text(
                            notification.createdAt != null
                                ? DateFormat(
                                    'MMM d, y h:mm a',
                                  ).format(notification.createdAt!)
                                : '',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (!notification.isRead) {
                          await provider.markAsRead(notification.id);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
        title: const Text('Admin Dashboard'),
        actions: [
          // Notifications
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final unreadCount = provider.notifications
                  .where((n) => !n.isRead)
                  .length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      _showNotifications();
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
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
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onSelected: (value) async {
              if (value == 'settings') {
                // Navigate to settings
              } else if (value == 'logout') {
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 12),
                    Text(user?.name ?? 'Admin'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(user?.name ?? 'Admin'),
              const SizedBox(height: 20),
              _buildPersonalTimeTracking(), // Add personal time tracking
              const SizedBox(height: 20),
              _buildLeaveBalanceCards(),
              const SizedBox(height: 20),
              _buildStatisticsCards(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildPendingApprovals(),
              const SizedBox(height: 20),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String name) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12
        ? 'Morning'
        : now.hour < 17
        ? 'Afternoon'
        : 'Evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good $timeOfDay,',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
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
            DateFormat('EEEE, MMMM d, y').format(now),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer2<LeaveProvider, TimeLogProvider>(
      builder: (context, leaveProvider, timeLogProvider, _) {
        final allLeaves = leaveProvider.allLeaves;
        final pendingLeaves = allLeaves
            .where((l) => l.status == 'pending')
            .length;

        // Count employees on leave today (including short, half-day, and full-day)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final onLeaveToday = allLeaves.where((l) {
          if (l.status != 'approved') return false;

          final startDate = DateTime(
            l.startDate.year,
            l.startDate.month,
            l.startDate.day,
          );
          final endDate = l.endDate != null
              ? DateTime(l.endDate!.year, l.endDate!.month, l.endDate!.day)
              : startDate;

          // Check if today is within the leave period
          return today.isAtSameMomentAs(startDate) ||
              today.isAtSameMomentAs(endDate) ||
              (today.isAfter(startDate) && today.isBefore(endDate));
        }).length;

        final activeEmployees = timeLogProvider.allTimeLogs
            .where((log) => log.startTime != null && log.endTime == null)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending Approvals',
                    '$pendingLeaves',
                    Icons.pending_actions,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'On Leave Today',
                    '$onLeaveToday',
                    Icons.beach_access,
                    AppColors.info,
                    onTap: onLeaveToday > 0
                        ? () => _showOnLeaveTodayDetails(allLeaves)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Now',
                    '$activeEmployees',
                    Icons.people_outline,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Leaves',
                    '${allLeaves.length}',
                    Icons.calendar_today,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showOnLeaveTodayDetails(List leaves) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final onLeaveToday = leaves.where((l) {
      if (l.status != 'approved') return false;

      final startDate = DateTime(
        l.startDate.year,
        l.startDate.month,
        l.startDate.day,
      );
      final endDate = l.endDate != null
          ? DateTime(l.endDate!.year, l.endDate!.month, l.endDate!.day)
          : startDate;

      return today.isAtSameMomentAs(startDate) ||
          today.isAtSameMomentAs(endDate) ||
          (today.isAfter(startDate) && today.isBefore(endDate));
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Employees on Leave Today'),
        content: SizedBox(
          width: double.maxFinite,
          child: onLeaveToday.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No employees on leave today'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: onLeaveToday.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final leave = onLeaveToday[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.info.withOpacity(0.1),
                        child: Icon(
                          leave.leaveType == 'half_day'
                              ? Icons.schedule
                              : leave.leaveType == 'short'
                              ? Icons.access_time
                              : Icons.beach_access,
                          color: AppColors.info,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        leave.userName ?? 'Employee #${leave.userId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.leaveType == 'half_day'
                                ? 'Half Day (${leave.halfDayType?.replaceAll('_', ' ')})'
                                : leave.leaveType == 'short'
                                ? 'Short Leave (2 hours)'
                                : 'Casual Leave',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (leave.endDate != null &&
                              leave.endDate!.isAfter(leave.startDate))
                            Text(
                              '${DateFormat('MMM d').format(leave.startDate)} - ${DateFormat('MMM d, y').format(leave.endDate!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          Text(
                            leave.reason,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
              Icons.event_note,
              AppColors.warning,
              _showApplyLeaveDialog,
            ),
            _buildActionCard(
              'Manage Users',
              Icons.people,
              AppColors.primary,
              () {
                // Navigate to user management
              },
            ),
            _buildActionCard(
              'Leave Policies',
              Icons.policy,
              AppColors.secondary,
              () {
                // Navigate to leave policies
              },
            ),
            _buildActionCard('Reports', Icons.assessment, AppColors.info, () {
              // Navigate to reports
            }),
            _buildActionCard(
              'Time Logs',
              Icons.access_time,
              AppColors.success,
              () {
                // Navigate to time logs
              },
            ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals() {
    return Consumer<LeaveProvider>(
      builder: (context, provider, _) {
        final pendingLeaves = provider.allLeaves
            .where((leave) => leave.status == 'pending')
            .take(5)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Approvals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (pendingLeaves.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Navigate to all pending approvals
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (pendingLeaves.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No pending approvals',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingLeaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final leave = pendingLeaves[index];
                  return _buildPendingLeaveCard(leave);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPendingLeaveCard(leave) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  leave.userId.toString(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User #${leave.userId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      leave.leaveType.toUpperCase(),
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
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  leave.leaveType == 'half_day'
                      ? 'Half Day'
                      : '${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                leave.leaveType == 'half_day'
                    ? '${DateFormat('MMM d, y').format(leave.startDate)} - Half Day'
                    : '${DateFormat('MMM d').format(leave.startDate)} - ${DateFormat('MMM d, y').format(leave.endDate ?? leave.startDate)}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                leave.leaveType == 'half_day'
                    ? 'Half Day'
                    : '${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          if (leave.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              leave.reason,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final provider = context.read<LeaveProvider>();
                    await provider.rejectLeave(
                      leaveId: leave.id,
                      reason: 'Rejected by admin',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Leave request rejected')),
                      );
                    }
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final provider = context.read<LeaveProvider>();
                    await provider.approveLeave(leave.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Leave request approved')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<LeaveProvider>(
      builder: (context, provider, _) {
        final recentLeaves = provider.allLeaves.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (recentLeaves.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentLeaves.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final leave = recentLeaves[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          leave.status,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getStatusIcon(leave.status),
                          color: _getStatusColor(leave.status),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'User #${leave.userId} - ${leave.leaveType.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        leave.leaveType == 'half_day'
                            ? '${DateFormat('MMM d, y').format(leave.startDate)} - Half Day'
                            : leave.endDate != null
                            ? '${DateFormat('MMM d').format(leave.startDate)} - ${DateFormat('MMM d').format(leave.endDate!)} (${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''})'
                            : '${DateFormat('MMM d').format(leave.startDate)} (${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''})',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(leave.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          leave.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(leave.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLeaveBalanceCards() {
    final authProvider = context.watch<AuthProvider>();
    final leaveProvider = context.watch<LeaveProvider>();
    final user = authProvider.currentUser;

    // Count half-day leaves from myLeaves (exclude rejected/cancelled)
    final halfDayLeaves = leaveProvider.myLeaves
        .where(
          (leave) =>
              leave.leaveType == 'half_day' &&
              leave.status != 'rejected' &&
              leave.status != 'cancelled',
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildBalanceCard(
            'Casual Leave',
            user?.casualLeaveBalance ?? 0,
            Icons.beach_access,
            AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBalanceCard(
            'Short Leave',
            user?.shortLeaveBalance ?? 0,
            Icons.schedule,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBalanceCard(
            'Half Day',
            halfDayLeaves,
            Icons.event_busy,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTimeTracking() {
    return Consumer<TimeLogProvider>(
      builder: (context, timeLogProvider, _) {
        final hasActiveSession = timeLogProvider.activeSession != null;
        final activeSession = timeLogProvider.activeSession;
        final todayHours = timeLogProvider.todayWorkingHours;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 8),
                    const Text(
                      'My Time Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Session Status
                if (hasActiveSession)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: AppColors.success),
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
                          'Started: ${DateTimeUtils.formatTime(activeSession!.startTime ?? DateTime.now())}',
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

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: hasActiveSession
                            ? null
                            : () async {
                                final success = await timeLogProvider
                                    .startSession();
                                if (context.mounted && success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Session started!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: !hasActiveSession
                            ? null
                            : () async {
                                _showEndSessionDialog();
                              },
                        icon: const Icon(Icons.stop),
                        label: const Text('End'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            ListTile(
              title: const Text('Half Day'),
              leading: const Icon(Icons.event_busy),
              onTap: () async {
                Navigator.pop(context);
                await _endSessionAndApplyHalfDay();
              },
            ),
            ListTile(
              title: const Text('End Work Today'),
              leading: const Icon(Icons.work_off),
              onTap: () {
                Navigator.pop(context);
                _endSession('other', context, customReason: 'End of workday');
              },
            ),
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
              Navigator.pop(context);
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
      await _loadDashboardData();
    }
  }

  Future<void> _endSessionAndApplyShortLeave() async {
    final timeLogProvider = context.read<TimeLogProvider>();
    final leaveProvider = context.read<LeaveProvider>();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int shortLeaveCount = 0;
    List<int> todayShortLeaveIds = [];

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

      if (todayDate.isAtSameMomentAs(startDate) ||
          todayDate.isAtSameMomentAs(endDate) ||
          (todayDate.isAfter(startDate) && todayDate.isBefore(endDate))) {
        if (leave.leaveType == 'short') {
          shortLeaveCount++;
          todayShortLeaveIds.add(leave.id);
        }
      }
    }

    await timeLogProvider.endSession(endReason: 'short_leave');

    if (shortLeaveCount >= 1) {
      for (final leaveId in todayShortLeaveIds) {
        await leaveProvider.cancelLeave(leaveId);
      }

      final halfDayType = 'first_half';

      final success = await leaveProvider.applyLeave(
        leaveType: 'half_day',
        startDate: DateTime.now(),
        reason:
            'Half day leave (converted from ${shortLeaveCount + 1} short leaves)',
        totalDays: 1,
        halfDayType: halfDayType,
      );

      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Converted ${shortLeaveCount + 1} short leaves to half-day leave!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadDashboardData();
        await authProvider.refreshUserData();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to apply leave'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      final success = await leaveProvider.applyLeave(
        leaveType: 'short',
        startDate: DateTime.now(),
        reason: 'Short leave taken during work hours',
        totalDays: 1,
      );

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Session ended and short leave applied successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadDashboardData();
        await authProvider.refreshUserData();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to apply leave'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _endSessionAndApplyHalfDay() async {
    final timeLogProvider = context.read<TimeLogProvider>();
    final leaveProvider = context.read<LeaveProvider>();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final hasActiveSession = timeLogProvider.activeSession != null;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    bool hasHalfDayToday = false;

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

      if (todayDate.isAtSameMomentAs(startDate) ||
          todayDate.isAtSameMomentAs(endDate) ||
          (todayDate.isAfter(startDate) && todayDate.isBefore(endDate))) {
        if (leave.leaveType == 'half_day') {
          hasHalfDayToday = true;
          break;
        }
      }
    }

    if (hasHalfDayToday) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('You already have a half-day leave for today!'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final halfDayType = hasActiveSession ? 'second_half' : 'first_half';
    final reason = hasActiveSession
        ? 'Second half leave - ending work early'
        : 'First half leave';

    if (hasActiveSession) {
      await timeLogProvider.endSession(endReason: 'half_day');
    }

    final success = await leaveProvider.applyLeave(
      leaveType: 'half_day',
      startDate: DateTime.now(),
      reason: reason,
      totalDays: 1,
      halfDayType: halfDayType,
    );

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            hasActiveSession
                ? 'Session ended and second half leave applied!'
                : 'First half leave applied successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadDashboardData();
      await authProvider.refreshUserData();
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to apply leave'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showApplyLeaveDialog() {
    final timeLogProvider = context.read<TimeLogProvider>();
    final hasActiveSession = timeLogProvider.activeSession != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select leave type:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Half Day Leave'),
              subtitle: Text(
                hasActiveSession
                    ? 'Will apply for Second Half (afternoon)'
                    : 'Will apply for First Half (morning)',
                style: TextStyle(
                  color: hasActiveSession ? AppColors.warning : AppColors.info,
                  fontSize: 12,
                ),
              ),
              leading: Icon(
                Icons.schedule,
                color: hasActiveSession ? AppColors.warning : AppColors.info,
              ),
              onTap: () {
                Navigator.pop(context);
                _showHalfDayLeaveForm(hasActiveSession);
              },
            ),
            ListTile(
              title: const Text('Full Day Leave'),
              leading: const Icon(Icons.event_available),
              onTap: () {
                Navigator.pop(context);
                context.go('/apply-leave');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHalfDayLeaveForm(bool hasActiveSession) {
    final TextEditingController reasonController = TextEditingController();
    final halfDayType = hasActiveSession ? 'second_half' : 'first_half';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          hasActiveSession ? 'Second Half Leave' : 'First Half Leave',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (hasActiveSession ? AppColors.warning : AppColors.info)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasActiveSession
                        ? AppColors.warning
                        : AppColors.info,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: hasActiveSession
                          ? AppColors.warning
                          : AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasActiveSession
                            ? 'Applying for second half (afternoon) because you have an active session'
                            : 'Applying for first half (morning) - no active session detected',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasActiveSession
                              ? AppColors.warning
                              : AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Date: ${DateFormat('MMM d, y').format(DateTime.now())}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter reason for half-day leave...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final leaveProvider = context.read<LeaveProvider>();
              final authProvider = context.read<AuthProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              Navigator.pop(context);

              final success = await leaveProvider.applyLeave(
                leaveType: 'half_day',
                startDate: DateTime.now(),
                reason: reason,
                totalDays: 1,
                halfDayType: halfDayType,
              );

              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Half-day leave applied for ${hasActiveSession ? "second half (afternoon)" : "first half (morning)"}',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                await _loadDashboardData();
                await authProvider.refreshUserData();
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info;
    }
  }
}
