import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/core/utils/date_time_utils.dart';
import 'package:leave_management/providers/auth_provider.dart';
import 'package:leave_management/providers/project_provider.dart';
import 'package:leave_management/providers/notification_provider.dart';
import 'package:leave_management/providers/leave_provider.dart';
import 'package:leave_management/providers/time_log_provider.dart';
import 'package:leave_management/providers/duty_type_provider.dart';

class PMDashboard extends StatefulWidget {
  const PMDashboard({super.key});

  @override
  State<PMDashboard> createState() => _PMDashboardState();
}

class _PMDashboardState extends State<PMDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final projectProvider = context.read<ProjectProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final leaveProvider = context.read<LeaveProvider>();
    final timeLogProvider = context.read<TimeLogProvider>();

    await Future.wait([
      projectProvider.fetchProjects(),
      projectProvider.fetchProjectStatistics(),
      projectProvider.fetchMyTasks(),
      notificationProvider.fetchUnreadCount(),
      leaveProvider.fetchMyLeaves(),
      timeLogProvider.fetchActiveSession(),
      timeLogProvider.fetchTodayWorkingHours(),
    ]);
  }

  void _startDuty(BuildContext context) async {
    final dutyTypeProvider = context.read<DutyTypeProvider>();
    await dutyTypeProvider.fetchAndCacheDutyTypes();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Duty Type'),
        content: Consumer<DutyTypeProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (provider.dutyTypes.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(child: Text('No duty types available')),
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
                      Navigator.pop(context);
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
          content: Text('Duty started successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(timeLogProvider.errorMessage ?? 'Failed to start duty'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showPauseSessionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select reason for ending session:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Lunch Break'),
              leading: const Icon(Icons.restaurant),
              onTap: () => _pauseDuty('lunch', dialogContext),
            ),
            ListTile(
              title: const Text('Prayer Break'),
              leading: const Icon(Icons.mosque),
              onTap: () => _pauseDuty('prayer', dialogContext),
            ),
            ListTile(
              title: const Text('Short Leave'),
              leading: const Icon(Icons.schedule),
              onTap: () async {
                Navigator.pop(dialogContext);
                await _pauseDutyAndApplyShortLeave();
              },
            ),
            ListTile(
              title: const Text('Other'),
              leading: const Icon(Icons.more_horiz),
              onTap: () {
                Navigator.pop(dialogContext);
                _showCustomPauseReasonDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomPauseReasonDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
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
              _pauseDuty('other', dialogContext, customReason: customReason);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _pauseDuty(
    String reason,
    BuildContext dialogContext, {
    String? customReason,
  }) async {
    Navigator.pop(dialogContext);
    final timeLogProvider = context.read<TimeLogProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await timeLogProvider.endSession(
      endReason: reason,
      customReason: customReason,
    );

    if (!mounted) return;

    Navigator.of(context).pop();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session paused successfully'),
          backgroundColor: AppColors.warning,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            timeLogProvider.errorMessage ?? 'Failed to pause session',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pauseDutyAndApplyShortLeave() async {
    final timeLogProvider = context.read<TimeLogProvider>();
    final leaveProvider = context.read<LeaveProvider>();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await leaveProvider.applyLeave(
      leaveType: 'short',
      startDate: DateTime.now(),
      reason: 'Short leave taken during work hours',
      totalDays: 1,
    );

    if (success) {
      await timeLogProvider.endSession(endReason: 'short_leave');

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Session ended and short leave applied successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
      await authProvider.refreshUserData();
    } else {
      final errorMessage =
          leaveProvider.errorMessage ?? 'Failed to apply leave';
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _resumeDuty(BuildContext context) async {
    final timeLogProvider = context.read<TimeLogProvider>();

    final lastLogId = timeLogProvider.lastLogId;
    if (lastLogId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No previous session to resume'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await timeLogProvider.resumeSession(lastLogId);
    if (context.mounted) {
      Navigator.of(context).pop();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session resumed'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadData();
      }
    }
  }

  void _endDuty(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Duty'),
        content: const Text(
          'Are you sure you want to end your duty for today?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('End Duty'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final timeLogProvider = context.read<TimeLogProvider>();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await timeLogProvider.endSession(
        endReason: 'other',
        customReason: 'End of workday',
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Duty ended successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          await _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo_icon.png'),
        ),
        title: const Text('Dashboard'),
        centerTitle: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Projects', icon: Icon(Icons.folder, size: 20)),
          ],
        ),
        actions: [
          // Notification Bell
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
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
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'PM',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                context.push('/profile');
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
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildProjectsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/pm/projects/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildOverviewTab() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(user?.name ?? 'Project Manager'),
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

            // My Tasks Section
            _buildMyTasksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsTab() {
    final authProvider = context.watch<AuthProvider>();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            _buildStatisticsCards(),
            const SizedBox(height: 24),

            // All Projects
            _buildAllProjects(),
          ],
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
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(color: Colors.white70, fontSize: 14),
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

  Widget _buildStatisticsCards() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        final stats = provider.projectStatistics;
        final totalProjects = stats['total_projects'] ?? 0;
        final inProgress = stats['in_progress'] ?? 0;
        final completed = stats['completed'] ?? 0;
        final onHold = stats['on_hold'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Projects',
                    totalProjects.toString(),
                    Icons.folder,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    inProgress.toString(),
                    Icons.trending_up,
                    AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    completed.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'On Hold',
                    onHold.toString(),
                    Icons.pause_circle,
                    Colors.orange,
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
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
              'My Projects',
              Icons.folder_open,
              AppColors.primary,
              () => context.push('/pm/projects'),
            ),
            _buildActionCard(
              'My Tasks',
              Icons.task_alt,
              AppColors.info,
              () => context.push('/pm/tasks'),
            ),
            _buildActionCard(
              'Apply Leave',
              Icons.event_note,
              AppColors.success,
              () => context.push('/staff/leave/apply'),
            ),
            _buildActionCard(
              'Time Logs',
              Icons.access_time,
              Colors.purple,
              () => context.push('/staff/time-logs'),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planning':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'on_hold':
        return Colors.orange;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTimeTrackingCard() {
    return Consumer<TimeLogProvider>(
      builder: (context, timeLogProvider, _) {
        final hasActiveSession = timeLogProvider.hasActiveSession;
        final todayHours = timeLogProvider.todayWorkingHours;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Today's Hours
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Hours',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateTimeUtils.durationToString(
                          todayHours ?? Duration.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            !hasActiveSession &&
                                !timeLogProvider.hasDutyStartedToday
                            ? () => _startDuty(context)
                            : null,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: hasActiveSession
                            ? () => _showPauseSessionDialog()
                            : timeLogProvider.hasDutyStartedToday &&
                                  !hasActiveSession
                            ? () => _resumeDuty(context)
                            : null,
                        icon: Icon(
                          hasActiveSession ? Icons.pause : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(hasActiveSession ? 'Pause' : 'Resume'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            timeLogProvider.hasDutyStartedToday &&
                                !timeLogProvider.isDutyCompletedToday
                            ? () => _endDuty(context)
                            : null,
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('End'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
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
            Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    String label,
    double balance,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              balance.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasksSection() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        final tasks = provider.myTasks.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Tasks', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.push('/pm/tasks'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (tasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks assigned',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...tasks.map(
                (task) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTaskPriorityColor(
                        task.priority,
                      ).withOpacity(0.2),
                      child: Icon(
                        Icons.task,
                        color: _getTaskPriorityColor(task.priority),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      task.projectName ?? 'No project',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: _buildTaskStatusChip(task.status),
                    onTap: () => context.push('/staff/tasks/${task.id}'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAllProjects() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        final projects = provider.projects;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Projects', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (projects.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No projects yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/pm/projects/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Project'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...projects.map(
                (project) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(
                        project.status,
                      ).withOpacity(0.2),
                      child: Icon(
                        Icons.folder,
                        color: _getStatusColor(project.status),
                      ),
                    ),
                    title: Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${project.statusLabel} • ${project.progress}% complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: project.progress / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(project.status),
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    onTap: () => context.push('/pm/projects/${project.id}'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getTaskPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTaskStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = AppColors.info;
        icon = Icons.timelapse;
        break;
      case 'pending':
        color = AppColors.warning;
        icon = Icons.pending;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
