import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/providers/leave_provider.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Fields
  String _leaveType = 'casual'; // casual, medical, annual, short
  String _leaveMode = 'full'; // full, first_half, second_half, short
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  // Constants
  static const Map<String, String> _leaveTypeLabels = {
    'casual': 'Casual Leave',
    'medical': 'Medical Leave',
    'annual': 'Annual Leave',
    'short': 'Short Leave',
  };

  static const Map<String, String> _leaveModeLabels = {
    'full': 'Full Day',
    'first_half': 'First Half',
    'second_half': 'Second Half',
    'short': 'Short Duration',
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onLeaveTypeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _leaveType = value;
      // Reset mode based on type
      if (_leaveType == 'annual') {
        _leaveMode = 'full'; // Annual is always full day
        _endDate = null; // Reset end date to force re-selection or keep null
      } else if (_leaveType == 'short') {
        _leaveMode = 'short';
        _endDate = null; // Short leave is always same day
      } else {
        _leaveMode = 'full'; // Default to full for others
      }
    });
  }

  void _onLeaveModeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _leaveMode = value;
      if (_leaveMode != 'full') {
        _endDate = null; // Half/Short are always single day
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? _startDate
        : (_endDate ?? _startDate);
        
    final firstDate = DateTime.now().subtract(const Duration(days: 30)); // Allow past 30 days
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // If end date is before new start date, reset it
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLimit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<LeaveProvider>();
    
    double? totalDays;
    if (_leaveMode == 'first_half' || _leaveMode == 'second_half') {
      totalDays = 0.5;
    }

    final success = await provider.applyLeave(
      leaveType: _leaveType,
      leaveMode: _leaveMode, 
      startDate: _startDate,
      endDate: _leaveMode == 'full' ? (_endDate ?? _startDate) : _startDate,
      reason: _reasonController.text.trim(),
      totalDays: totalDays,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave application submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to apply leave'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaveProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leave Type Dropdown
              DropdownButtonFormField<String>(
                value: _leaveType,
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _leaveTypeLabels.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: isLoading ? null : _onLeaveTypeChanged,
              ),
              const SizedBox(height: 16),

              // Duration / Mode Selection
              // Hide mode selection for 'short' (auto-selected)
              if (_leaveType != 'short')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildModeChip('full', 'Full Day'),
                        // Annual leave is Full Day only
                        if (_leaveType != 'annual') ...[
                           _buildModeChip('first_half', 'First Half'),
                           _buildModeChip('second_half', 'Second Half'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Date Selection
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      context, 
                      'Start Date', 
                      _startDate, 
                      () => _selectDate(context, true)
                    ),
                  ),
                  // Show End Date only for Full Day mode
                  if (_leaveMode == 'full') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePicker(
                        context, 
                        'End Date', 
                        _endDate, 
                        () => _selectDate(context, false)
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Reason Input
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : _submitLimit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Text(
                        'Submit Application',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String value, String label) {
    final isSelected = _leaveMode == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) _onLeaveModeChanged(value);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildDatePicker(
    BuildContext context, 
    String label, 
    DateTime? date, 
    VoidCallback onTap
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null 
              ? DateFormat('MMM dd, yyyy').format(date) 
              : 'Select Date',
          style: TextStyle(
            color: date != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}
