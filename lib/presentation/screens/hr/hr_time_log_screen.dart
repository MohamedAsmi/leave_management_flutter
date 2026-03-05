import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/time_log_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/time_log_service.dart';

class HrTimeLogScreen extends StatefulWidget {
  final UserModel user;

  const HrTimeLogScreen({super.key, required this.user});

  @override
  State<HrTimeLogScreen> createState() => _HrTimeLogScreenState();
}

class _HrTimeLogScreenState extends State<HrTimeLogScreen> {
  late DateTime _selectedDate;
  final ScrollController _dateScrollController = ScrollController();
  late TimeLogService _timeLogService;

  // Cache the last 14 days
  late final List<DateTime> _last14Days;
  List<TimeLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _timeLogService = TimeLogService(context.read<ApiClient>());

    _last14Days = List.generate(14, (index) {
      return DateTime.now().subtract(Duration(days: index));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogs();
    });
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);

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

    try {
      final logs = await _timeLogService.getAllTimeLogs(
        userId: widget.user.id,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading time logs: $e')));
      }
    }
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

  void _showEditLogDialog(TimeLogModel log) {
    List<Map<String, dynamic>> sessionDrafts = [];

    if (log.sessions.isNotEmpty) {
      for (var session in log.sessions) {
        sessionDrafts.add({
          'startController': TextEditingController(
            text: DateFormat('HH:mm').format(session.startTime.toLocal()),
          ),
          'endController': TextEditingController(
            text: DateFormat('HH:mm').format(session.endTime.toLocal()),
          ),
          'reason': session.reason,
          'customReasonController': TextEditingController(
            text: session.customReason ?? '',
          ),
        });
      }
    } else {
      sessionDrafts.add({
        'startController': TextEditingController(
          text: log.startTime != null
              ? DateFormat('HH:mm').format(log.startTime!.toLocal())
              : '',
        ),
        'endController': TextEditingController(
          text: log.endTime != null
              ? DateFormat('HH:mm').format(log.endTime!.toLocal())
              : '',
        ),
        'reason':
            [
              'work',
              'lunch',
              'prayer',
              'short_leave',
              'meeting',
              'other',
            ].contains(log.endReason)
            ? log.endReason
            : 'other',
        'customReasonController': TextEditingController(
          text: log.customReason ?? '',
        ),
      });
    }

    final reasonOptions = [
      'work',
      'lunch',
      'prayer',
      'short_leave',
      'meeting',
      'other',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Time Log Sessions'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessionDrafts.length,
                  itemBuilder: (context, index) {
                    final draft = sessionDrafts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Session ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      sessionDrafts.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: draft['startController'],
                                    decoration: const InputDecoration(
                                      labelText: 'Start (HH:mm)',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: draft['endController'],
                                    decoration: const InputDecoration(
                                      labelText: 'End (HH:mm)',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value:
                                  reasonOptions.contains(
                                    draft['reason'] ?? 'work',
                                  )
                                  ? (draft['reason'] ?? 'work')
                                  : 'other',
                              decoration: const InputDecoration(
                                labelText: 'Reason',
                              ),
                              items: reasonOptions
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  draft['reason'] = val;
                                });
                              },
                            ),
                            if (draft['reason'] == 'other') ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: draft['customReasonController'],
                                decoration: const InputDecoration(
                                  labelText: 'Custom Reason',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      sessionDrafts.add({
                        'startController': TextEditingController(),
                        'endController': TextEditingController(),
                        'reason': 'work',
                        'customReasonController': TextEditingController(),
                      });
                    });
                  },
                  child: const Text('Add Session'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _updateLogWithSessions(
                      log: log,
                      sessionDrafts: sessionDrafts,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateLogWithSessions({
    required TimeLogModel log,
    required List<Map<String, dynamic>> sessionDrafts,
  }) async {
    setState(() => _isLoading = true);
    try {
      final logDate = log.date.toLocal();
      List<Map<String, dynamic>> finalSessions = [];
      DateTime? parentStart;
      DateTime? parentEnd;

      for (var draft in sessionDrafts) {
        DateTime? sStart;
        DateTime? sEnd;

        final startStr = draft['startController'].text;
        if (startStr.isNotEmpty) {
          final parts = startStr.split(':');
          sStart = DateTime(
            logDate.year,
            logDate.month,
            logDate.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }

        final endStr = draft['endController'].text;
        if (endStr.isNotEmpty) {
          final parts = endStr.split(':');
          sEnd = DateTime(
            logDate.year,
            logDate.month,
            logDate.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }

        if (sStart != null && sEnd != null) {
          finalSessions.add({
            'start_time': sStart
                .toIso8601String()
                .replaceAll('T', ' ')
                .split('.')[0],
            'end_time': sEnd
                .toIso8601String()
                .replaceAll('T', ' ')
                .split('.')[0],
            'reason': draft['reason'],
            'custom_reason': draft['reason'] == 'other'
                ? draft['customReasonController'].text
                : null,
          });

          if (parentStart == null || sStart.isBefore(parentStart)) {
            parentStart = sStart;
          }
          if (parentEnd == null || sEnd.isAfter(parentEnd)) {
            parentEnd = sEnd;
          }
        } else if (sStart != null && sEnd == null) {
          finalSessions.add({
            'start_time': sStart
                .toIso8601String()
                .replaceAll('T', ' ')
                .split('.')[0],
            'end_time': null,
            'reason': draft['reason'],
            'custom_reason': draft['reason'] == 'other'
                ? draft['customReasonController'].text
                : null,
          });
          if (parentStart == null || sStart.isBefore(parentStart)) {
            parentStart = sStart;
          }
        }
      }

      final payload = {
        'sessions': finalSessions.isNotEmpty ? finalSessions : null,
        'start_time': parentStart
            ?.toIso8601String()
            .replaceAll('T', ' ')
            .split('.')[0],
        'end_time': parentEnd
            ?.toIso8601String()
            .replaceAll('T', ' ')
            .split('.')[0],
        'end_reason': finalSessions.isNotEmpty ? 'other' : null,
        'custom_reason': finalSessions.isNotEmpty ? 'Edited by HR' : null,
      };

      await _timeLogService.updateTimeLog(log.id, payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time log updated successfully')),
        );
        _fetchLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update time log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddSessionDialog() {
    final startController = TextEditingController();
    final endController = TextEditingController();
    final customReasonController = TextEditingController(text: 'Added by HR');

    String selectedAction = 'End Duty';
    final actions = ['End Duty', 'Custom Reason'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: startController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time (HH:mm)',
                        hintText: 'e.g. 09:00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: endController,
                      decoration: const InputDecoration(
                        labelText: 'End Time (HH:mm)',
                        hintText: 'e.g. 17:00 (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedAction,
                      decoration: const InputDecoration(labelText: 'Action'),
                      items: actions
                          .map(
                            (a) => DropdownMenuItem(value: a, child: Text(a)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val != null) {
                            selectedAction = val;
                            if (selectedAction == 'Custom Reason' &&
                                customReasonController.text.isEmpty) {
                              customReasonController.text = 'Added by HR';
                            } else if (selectedAction == 'End Duty') {
                              customReasonController.text = '';
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedAction == 'Custom Reason')
                      TextField(
                        controller: customReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Reason',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (startController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Start time is required')),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext);
                    await _addSession(
                      startTimeStr: startController.text,
                      endTimeStr: endController.text,
                      endReason: 'other',
                      customReason: selectedAction == 'Custom Reason'
                          ? customReasonController.text
                          : 'End of workday',
                    );
                  },
                  child: const Text('Add Session'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addSession({
    required String startTimeStr,
    required String endTimeStr,
    required String? endReason,
    required String customReason,
  }) async {
    setState(() => _isLoading = true);
    try {
      final logDate = _selectedDate.toLocal();

      DateTime? newStart;
      if (startTimeStr.isNotEmpty) {
        final parts = startTimeStr.split(':');
        newStart = DateTime(
          logDate.year,
          logDate.month,
          logDate.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      DateTime? newEnd;
      if (endTimeStr.isNotEmpty) {
        final parts = endTimeStr.split(':');
        newEnd = DateTime(
          logDate.year,
          logDate.month,
          logDate.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      await _timeLogService.createTimeLogHr({
        'user_id': widget.user.id,
        'date': DateFormat('yyyy-MM-dd').format(logDate),
        'start_time': newStart
            ?.toIso8601String()
            .replaceAll('T', ' ')
            .split('.')[0],
        'end_time': newEnd
            ?.toIso8601String()
            .replaceAll('T', ' ')
            .split('.')[0],
        'end_reason': endReason,
        'custom_reason': customReason,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session added successfully')),
      );
      _fetchLogs();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add session: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.name}\'s Time Logs'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSessionDialog,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add Session'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                    DateFormat('E').format(date),
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
                    DateFormat('d').format(date),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logs.isEmpty) {
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final totalDuration = _logs.fold<Duration>(
      Duration.zero,
      (prev, log) => prev + (log.totalDuration ?? Duration.zero),
    );

    return RefreshIndicator(
      onRefresh: _fetchLogs,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDaySummaryCard(totalDuration, _logs.length),
          const SizedBox(height: 24),

          const Text(
            'Session History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return _buildSessionCardsForLog(log);
            },
          ),
        ],
      ),
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
            log: log,
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
            log: log,
            startTime: log.startTime!,
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
          log: log,
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
    required TimeLogModel log,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isActive ? AppColors.success : AppColors.primary)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        durationStr,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.blue,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditLogDialog(log),
                    ),
                  ],
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
