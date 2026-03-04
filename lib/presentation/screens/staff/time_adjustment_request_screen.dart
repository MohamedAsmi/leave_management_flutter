import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/providers/time_adjustment_provider.dart';
import 'package:flutter/cupertino.dart';


class TimeAdjustmentRequestScreen extends StatefulWidget {
  const TimeAdjustmentRequestScreen({super.key});

  @override
  State<TimeAdjustmentRequestScreen> createState() =>
      _TimeAdjustmentRequestScreenState();
}

class _TimeAdjustmentRequestScreenState
    extends State<TimeAdjustmentRequestScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 450,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateChanged: (DateTime date) {
                    Navigator.pop(context, date);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

Future<void> _pickStartTime() async {
  TimeOfDay tempPickedTime = _selectedStartTime ?? TimeOfDay.fromDateTime(DateTime.now());
  await showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // Done button
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Done"),
                    onPressed: () { // ✅ Commit the last value (even if not scrolled) 
                    setState(() => _selectedStartTime = tempPickedTime); 
                    Navigator.of(context).pop(); 
                    },
                  ),
                ],
              ),
            ),
            // Cupertino time picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime.now(), // ✅ current time
                use24hFormat: false,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    _selectedStartTime = TimeOfDay.fromDateTime(newDateTime);
                  });
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _pickEndTime() async {
  TimeOfDay tempPickedTime = _selectedEndTime ?? TimeOfDay.fromDateTime(DateTime.now());
  await showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // Done button
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Done"),
                    onPressed: () { 
                      setState(() => _selectedEndTime = tempPickedTime); 
                      Navigator.of(context).pop(); 
                      },
                  ),
                ],
              ),
            ),
            // Cupertino time picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime.now(), // ✅ current time
                use24hFormat: false,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    _selectedStartTime = TimeOfDay.fromDateTime(newDateTime);
                  });
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}



bool _isTimeInFuture(DateTime date, TimeOfDay time) {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return dateTime.isAfter(DateTime.now());
  }
  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String? _buildDateTimeString(DateTime date, TimeOfDay? time) {
    if (time == null) return null;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedStartTime == null && _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least a start time or end time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate end time is after start time
    if (_selectedStartTime != null && _selectedEndTime != null) {
      final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
      final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
      
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Validate that times are not in the future
    if (_selectedStartTime != null && _isTimeInFuture(_selectedDate!, _selectedStartTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start time cannot be in the future'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedEndTime != null && _isTimeInFuture(_selectedDate!, _selectedEndTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time cannot be in the future'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<TimeAdjustmentProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    final success = await provider.submitRequest(
      date: dateStr,
      requestedStartTime: _buildDateTimeString(_selectedDate!, _selectedStartTime),
      requestedEndTime: _buildDateTimeString(_selectedDate!, _selectedEndTime),
      reason: _reasonController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time adjustment request submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage?.replaceAll('Exception: ', '') ??
                  'Failed to submit request',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Time Adjustment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select the date and the time(s) you want to adjust. '
                        'You can adjust start time, end time, or both.',
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker
              const Text(
                'Date *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                    hintText: 'Select date',
                    errorText: null,
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                        : 'Tap to select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Start Time Picker
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickStartTime,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedStartTime != null)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _selectedStartTime = null,
                                        );
                                      },
                                    ),
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                            child: Text(
                              _selectedStartTime != null
                                  ? _formatTimeOfDay(_selectedStartTime!)
                                  : 'Not set',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedStartTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // End Time Picker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickEndTime,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedEndTime != null)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _selectedEndTime = null,
                                        );
                                      },
                                    ),
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                            child: Text(
                              _selectedEndTime != null
                                  ? _formatTimeOfDay(_selectedEndTime!)
                                  : 'Not set',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedEndTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reason
              const Text(
                'Reason *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Explain why you need this time adjustment...',
                  contentPadding: EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
