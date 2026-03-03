import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/time_log_provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/duty_type_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_time_utils.dart';
import 'package:intl/intl.dart';

class HRTimeTrackingScreen extends StatefulWidget {
  const HRTimeTrackingScreen({super.key});

  @override
  State<HRTimeTrackingScreen> createState() => _HRTimeTrackingScreenState();
}

class _HRTimeTrackingScreenState extends State<HRTimeTrackingScreen> {
  @override
  void initState() {
    super.initState();
    _loadTimeTrackingData();
  }

  Future<void> _loadTimeTrackingData() async {
    final timeLogProvider = context.read<TimeLogProvider>();
    final leaveProvider = context.read<LeaveProvider>();
    final dutyTypeProvider = context.read<DutyTypeProvider>();

    await Future.wait([
      timeLogProvider.fetchMyTimeLogs(),
      timeLogProvider.fetchActiveSession(),
      timeLogProvider.fetchTodayWorkingHours(),
      leaveProvider.fetchMyLeaves(),
      dutyTypeProvider.fetchAndCacheDutyTypes(),
    ]);
  }

  Future<void> _handleRefresh() async {
    await _loadTimeTrackingData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Time Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonalTimeTracking(),
              const SizedBox(height: 20),
              _buildLeaveBalanceCards(),
            ],
          ),
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
                SizedBox(
                  height: 48, // Fixed height for a balanced look
                  child: Row(
                    children: [
                      // START BUTTON
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (hasActiveSession ||
                                  (timeLogProvider.hasDutyStartedToday &&
                                      !timeLogProvider.isDutyCompletedToday))
                              ? null // Disable if there's an active session or paused
                              : () async {
                                  _showDutyTypeSelectionDialog();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (hasActiveSession ||
                                    (timeLogProvider.hasDutyStartedToday &&
                                        !timeLogProvider.isDutyCompletedToday))
                                ? Colors.grey
                                : AppColors.success,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero, // Ensures text fits
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.play_arrow, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'Start',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                              : (timeLogProvider.hasDutyStartedToday &&
                                    !timeLogProvider.isDutyCompletedToday)
                              ? () async {
                                  final lastId = timeLogProvider.lastLogId;
                                  if (lastId != null) {
                                    final success = await timeLogProvider
                                        .resumeSession(lastId);
                                    if (context.mounted && success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Session resumed!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      await _loadTimeTrackingData();
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No previous session to resume found.',
                                        ),
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
                                  : (timeLogProvider.hasDutyStartedToday &&
                                            !timeLogProvider
                                                .isDutyCompletedToday
                                        ? AppColors.success
                                        : Colors.grey),
                            ),
                            foregroundColor: hasActiveSession
                                ? AppColors.warning
                                : (timeLogProvider.hasDutyStartedToday &&
                                          !timeLogProvider.isDutyCompletedToday
                                      ? AppColors.success
                                      : Colors.grey),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasActiveSession
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasActiveSession ? 'Pause' : 'Resume',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // END DUTY BUTTON
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              (hasActiveSession ||
                                  (timeLogProvider.hasDutyStartedToday &&
                                      !timeLogProvider.isDutyCompletedToday))
                              ? () => _endDutyToday()
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color:
                                  (hasActiveSession ||
                                      (timeLogProvider.hasDutyStartedToday &&
                                          !timeLogProvider
                                              .isDutyCompletedToday))
                                  ? AppColors.error
                                  : Colors.grey,
                            ),
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'End',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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

  void _showDutyTypeSelectionDialog() {
    final dutyTypeProvider = context.read<DutyTypeProvider>();

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
      await _loadTimeTrackingData();
    }
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
              onTap: () {
                Navigator.pop(context); // close dialog
                _endSession('lunch', context);
              },
            ),
            ListTile(
              title: const Text('Prayer Break'),
              leading: const Icon(Icons.mosque),
              onTap: () {
                Navigator.pop(context); // close dialog
                _endSession('prayer', context);
              },
            ),
            ListTile(
              title: const Text('Short Leave'),
              leading: const Icon(Icons.schedule),
              onTap: () async {
                Navigator.pop(context); // close dialog
                await _endSessionAndApplyShortLeave();
              },
            ),
            ListTile(
              title: const Text('Other'),
              leading: const Icon(Icons.more_horiz),
              onTap: () {
                Navigator.pop(context); // close dialog
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
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
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
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
      await _loadTimeTrackingData();
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
          content: Text('Session ended and short leave applied successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadTimeTrackingData();
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
      leaveMode: halfDayType,
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
      await _loadTimeTrackingData();
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
                // Navigate to full day leave application
                // context.go('/apply-leave');
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
                leaveMode: halfDayType,
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
                await _loadTimeTrackingData();
                await authProvider.refreshUserData();
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
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
            AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBalanceCard(
            'Short',
            user?.shortLeaveBalance ?? 0,
            Icons.schedule,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    String title,
    num count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
