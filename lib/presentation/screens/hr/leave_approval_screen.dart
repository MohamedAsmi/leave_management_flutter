import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/leave_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/leave_model.dart';
import '../../../core/utils/date_time_utils.dart';

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  String _selectedLeaveType = 'All';
  String _selectedStatus = 'All';
  DateTime? _selectedDate;
  
  final List<String> _leaveTypes = [
    'All',
    'Casual',
    'Sick',
    'Annual',
    'Short',
    'Half Day'
  ];

  final List<String> _statuses = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    // Fetch all leaves initially (status: null gets all)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().fetchAllLeaves();
    });
  }

  void _onLeaveTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedLeaveType = newValue;
      });
    }
  }

  void _onStatusChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedStatus = newValue;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = 'All';
      _selectedLeaveType = 'All';
      _selectedDate = null;
    });
  }

  List<LeaveModel> _filterLeaves(List<LeaveModel> leaves) {
    return leaves.where((leave) {
      // Filter by Status
      if (_selectedStatus != 'All') {
        if (leave.status.toLowerCase() != _selectedStatus.toLowerCase()) return false;
      }

      // Filter by Type
      if (_selectedLeaveType != 'All') {
        String typeToCheck = _selectedLeaveType.toLowerCase();
        if (_selectedLeaveType == 'Half Day') typeToCheck = 'half_day';
        if (_selectedLeaveType == 'Sick') typeToCheck = 'medical';
        
        if (leave.leaveType.toLowerCase() != typeToCheck) return false;
      }

      // Filter by Date
      if (_selectedDate != null) {
        final start = DateTime(leave.startDate.year, leave.startDate.month, leave.startDate.day);
        final end = leave.endDate != null 
            ? DateTime(leave.endDate!.year, leave.endDate!.month, leave.endDate!.day)
            : start;
        final selected = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);

        return (selected.isAtSameMomentAs(start) || selected.isAfter(start)) && 
               (selected.isAtSameMomentAs(end) || selected.isBefore(end));
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaves'),
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, leaveProvider, child) {
          if (leaveProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredLeaves = _filterLeaves(leaveProvider.allLeaves);
          // Sort remaining: Pending first, then by date desc
          filteredLeaves.sort((a, b) {
            if (a.status == 'pending' && b.status != 'pending') return -1;
            if (a.status != 'pending' && b.status == 'pending') return 1;
            return b.startDate.compareTo(a.startDate);
          });

          return Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Status Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _statuses.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: _onStatusChanged,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Type Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLeaveType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _leaveTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: _onLeaveTypeChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date Filter and Clear Button
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: _selectedDate != null 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: _clearDateFilter,
                                      )
                                    : const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _selectedDate != null
                                    ? DateFormat('MMM d, y').format(_selectedDate!)
                                    : 'All Dates',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        if (_selectedStatus != 'All' || _selectedLeaveType != 'All' || _selectedDate != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _clearAllFilters,
                            icon: const Icon(Icons.filter_alt_off),
                            tooltip: 'Clear All Filters',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // List
              Expanded(
                child: filteredLeaves.isEmpty
                    ? const Center(
                        child: Text(
                          'No leaves found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLeaves.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final leave = filteredLeaves[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                context.push('/my-leaves/detail', extra: leave).then((_) {
                                  // Refresh list when returning from detail (in case approved/rejected)
                                  context.read<LeaveProvider>().fetchAllLeaves();
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          leave.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            // Status Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(leave.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                leave.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: _getStatusColor(leave.status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Type Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _formatLeaveType(leave.leaveType),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('MMM d').format(leave.startDate)} ${leave.endDate != null && !leave.startDate.isAtSameMomentAs(leave.endDate!) ? '- ${DateFormat('MMM d').format(leave.endDate!)}' : ''}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.timelapse,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getDurationText(leave),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      leave.reason,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }

  String _formatLeaveType(String type) {
    return type.split('_').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  String _getDurationText(LeaveModel leave) {
    if (leave.leaveType == 'short') return '2 Hours';
    if (leave.leaveType == 'half_day') return '4 Hours';
    return '${leave.totalDays} Day(s)';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }
}
