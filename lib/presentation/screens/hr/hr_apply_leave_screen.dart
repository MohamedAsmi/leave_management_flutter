import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/providers/leave_provider.dart';
import 'package:leave_management/providers/user_provider.dart';
import 'package:leave_management/data/models/user_model.dart';

class HrApplyLeaveScreen extends StatefulWidget {
  const HrApplyLeaveScreen({super.key});

  @override
  State<HrApplyLeaveScreen> createState() => _HrApplyLeaveScreenState();
}

class _HrApplyLeaveScreenState extends State<HrApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  UserModel? _selectedStaff;
  String _leaveType = 'casual'; // casual, medical, annual, short
  String _leaveMode = 'full'; // full, first_half, second_half, short
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();

  // Constants
  static const Map<String, String> _leaveTypeLabels = {
    'casual': 'Casual Leave',
    'medical': 'Medical Leave',
    'annual': 'Annual Leave',
    'short': 'Short Leave',
  };

  @override
  void initState() {
    super.initState();
    // Fetch users when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchAllUsers();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
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
    final initialDate = isStart ? _startDate : (_endDate ?? _startDate);

    final firstDate = DateTime.now().subtract(
      const Duration(days: 30),
    ); // Allow past 30 days
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

  void _showStaffSelectionPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final userProvider = context.watch<UserProvider>();

            // Filter users based on search text
            final query = _searchController.text.toLowerCase();
            final filteredUsers = userProvider.activeUsers.where((user) {
              return user.name.toLowerCase().contains(query) ||
                  (user.email.toLowerCase().contains(query)) ||
                  (user.phone?.toLowerCase().contains(query) ?? false);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 0,
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Staff Member',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Search specific to popup
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or phone',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setStateModal(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (val) {
                      setStateModal(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // List
                  Expanded(
                    child: userProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'No active staff found matching your search.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredUsers.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (user.phone != null &&
                                        user.phone!.isNotEmpty)
                                      Text(
                                        user.phone!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine:
                                    user.phone != null &&
                                    user.phone!.isNotEmpty,
                                onTap: () {
                                  setState(() {
                                    _selectedStaff = user;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Clear search when modal closes
      _searchController.clear();
    });
  }

  Future<void> _submitLimit() async {
    if (_selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

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
      userId: _selectedStaff!.id, // Pass explicit target user ID
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Leave application for ${_selectedStaff!.name} submitted successfully',
            ),
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
      appBar: AppBar(title: const Text('Apply Staff Leave')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Select Staff Member Banner/Button
              InkWell(
                onTap: isLoading ? null : _showStaffSelectionPopup,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedStaff == null
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: _selectedStaff == null
                            ? AppColors.primary
                            : AppColors.success,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedStaff == null
                                  ? 'Select Staff Member'
                                  : 'Applying leave for:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            if (_selectedStaff != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedStaff!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              if (_selectedStaff == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16),
                  child: Text(
                    '* Required',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Leave Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _leaveType,
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _leaveTypeLabels.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: isLoading ? null : _onLeaveTypeChanged,
              ),
              const SizedBox(height: 16),

              // Half-Day Timings Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Half-Day Leave Timings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• First Half: 8:00 AM - 12:00 PM\n• Second Half: 12:00 PM - 4:00 PM',
                            style: TextStyle(
                              height: 1.4,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Duration / Mode Selection
              // Hide mode selection for 'short' (auto-selected)
              if (_leaveType != 'short')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                      () => _selectDate(context, true),
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
                        () => _selectDate(context, false),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Staff Application',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
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
    VoidCallback onTap,
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
          style: TextStyle(color: date != null ? Colors.black87 : Colors.grey),
        ),
      ),
    );
  }
}
