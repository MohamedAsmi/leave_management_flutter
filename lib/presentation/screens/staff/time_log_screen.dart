import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/core/utils/date_time_utils.dart';
import 'package:leave_management/providers/time_log_provider.dart';
import 'package:leave_management/data/models/time_log_model.dart';

class TimeLogScreen extends StatefulWidget {
  const TimeLogScreen({super.key});

  @override
  State<TimeLogScreen> createState() => _TimeLogScreenState();
}

class _TimeLogScreenState extends State<TimeLogScreen> {
  late DateTime _selectedDate;
  final ScrollController _dateScrollController = ScrollController();

  // Cache the last 14 days
  late final List<DateTime> _last14Days;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Generate last 14 days list (reversed so today is first/last depending on design)
    // Design: Horizontal list. Let's put today first or last? "Last 14 days".
    // Usually convenient to see today first.
    _last14Days = List.generate(14, (index) {
      return DateTime.now().subtract(Duration(days: index));
    });

    // Fetch logs for the selected date on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogs();
    });
  }

  Future<void> _fetchLogs() async {
    final provider = context.read<TimeLogProvider>();
    // The provider's fetchMyTimeLogs replaces the list.
    // So we just fetch for the specific date range (start of day to end of day)
    // Actually the backend filters by date range.

    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    await provider.fetchMyTimeLogs(startDate: startOfDay, endDate: endOfDay);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchLogs();
  }

  Future<void> _selectDateFromCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      _onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDateFromCalendar,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const Divider(height: 1),
          Expanded(child: _buildLogsList()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 90,
      color: Theme.of(context).cardColor,
      child: ListView.separated(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _last14Days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = _last14Days[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date), // Mon, Tue
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date), // 12
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogsList() {
    return Consumer<TimeLogProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myTimeLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No records found for\n${DateFormat('MMMM d, y').format(_selectedDate)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // Calculate total duration for the day
        final totalDuration = provider.myTimeLogs.fold<Duration>(
          Duration.zero,
          (prev, log) => prev + (log.totalDuration ?? Duration.zero),
        );

        return RefreshIndicator(
          onRefresh: _fetchLogs,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card for the day
              _buildDaySummaryCard(totalDuration, provider.myTimeLogs.length),
              const SizedBox(height: 24),

              const Text(
                'Session History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.myTimeLogs.length,
                itemBuilder: (context, index) {
                  final log = provider.myTimeLogs[index];
                  return _buildSessionCardsForLog(log);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaySummaryCard(Duration totalDuration, int sessionCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradient,
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, MMMM d, y').format(_selectedDate),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${(totalDuration.inMinutes / 60).toStringAsFixed(2)} hrs',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Total Duration',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$sessionCount Session${sessionCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCardsForLog(TimeLogModel log) {
    List<Widget> cards = [];

    if (log.sessions.isNotEmpty) {
      for (var session in log.sessions) {
        cards.add(
          _buildSessionCard(
            startTime: session.startTime,
            endTime: session.endTime,
            duration: Duration(seconds: session.duration),
            reason: session.reason,
            customReason: session.customReason,
            isActive: false,
          ),
        );
      }
      if (log.isActive && log.startTime != null) {
        cards.add(
          _buildSessionCard(
            startTime: log.startTime,
            endTime: null,
            duration: null,
            reason: null,
            customReason: null,
            isActive: true,
          ),
        );
      }
    } else {
      cards.add(
        _buildSessionCard(
          startTime: log.startTime,
          endTime: log.endTime,
          duration: log.totalDuration,
          reason: log.endReason,
          customReason: log.customReason,
          isActive: log.isActive,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
    );
  }

  Widget _buildSessionCard({
    required DateTime? startTime,
    required DateTime? endTime,
    required Duration? duration,
    required String? reason,
    required String? customReason,
    required bool isActive,
  }) {
    final startStr = startTime != null
        ? DateTimeUtils.formatTime(startTime.toLocal(), format: 'h:mm a')
        : '--:--';
    final endStr = endTime != null
        ? DateTimeUtils.formatTime(endTime.toLocal(), format: 'h:mm a')
        : (isActive ? 'Active' : '--:--');

    final durationStr = duration != null
        ? '${(duration.inMinutes / 60).toStringAsFixed(2)} hrs'
        : (isActive ? 'Running...' : '0.00 hrs');

    final isSystemReason = [
      'lunch',
      'prayer',
      'short_leave',
      'half_day',
    ].contains(reason);

    final reasonText =
        customReason ??
        (isSystemReason ? _formatReason(reason) : 'Session Ended');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? AppColors.success.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 16,
                      color: isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$startStr - $endStr',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.success : AppColors.primary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    durationStr,
                    style: TextStyle(
                      color: isActive ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (reason != null || isActive) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    isActive ? Icons.play_circle : Icons.stop_circle,
                    size: 16,
                    color: isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isActive ? 'Currently Active' : reasonText,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  String _formatReason(String? reason) {
    if (reason == null) return '';
    return reason
        .split('_')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
