import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/leave_model.dart';

class LeaveDetailScreen extends StatelessWidget {
  final LeaveModel leave;

  const LeaveDetailScreen({super.key, required this.leave});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.info;
    }
  }

  IconData _getLeaveIcon(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return Icons.beach_access;
      case 'short':
        return Icons.access_time;
      case 'half_day':
        return Icons.event_busy;
      default:
        return Icons.event_note;
    }
  }

  String _formatLeaveType(String type) {
    return type.split('_').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  String _getDurationText(LeaveModel leave) {
    switch (leave.leaveType.toLowerCase()) {
      case 'short':
        return '2 Hours';
      case 'half_day':
        return '4 Hours';
      default:
        return '${leave.totalDays} Day(s)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(leave.status);
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getLeaveIcon(leave.leaveType),
                        size: 48,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatLeaveType(leave.leaveType),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Applied Date',
                      DateFormat('MMM d, y').format((leave.createdAt ?? DateTime.now()).toLocal()),
                      Icons.calendar_today,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Duration',
                      _getDurationText(leave),
                      Icons.timelapse,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Leave Mode',
                      leave.formattedLeaveMode,
                      Icons.grid_view,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Start Date',
                      DateFormat('MMM d, y').format(leave.startDate.toLocal()),
                      Icons.date_range,
                    ),
                    if (leave.endDate != null &&
                        !leave.startDate.isAtSameMomentAs(leave.endDate!)) ...[
                      const Divider(),
                      _buildDetailRow(
                        context,
                        'End Date',
                        DateFormat('MMM d, y').format(leave.endDate!.toLocal()),
                        Icons.date_range,
                      ),
                    ],
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Reason',
                      leave.reason,
                      Icons.description,
                    ),
                    if (leave.status == 'rejected' &&
                        leave.rejectionReason != null) ...[
                      const Divider(),
                      _buildDetailRow(
                        context,
                        'Rejection Reason',
                        leave.rejectionReason!,
                        Icons.warning,
                        valueColor: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Approve/Reject Buttons (for HR/Admin on pending leaves)
            if (leave.status == 'pending' &&
                context.read<AuthProvider>().canApproveLeaves) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectLeave(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveLeave(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (leave.status == 'pending' &&
                user != null &&
                user.id == leave.userId) ...[
              // Cancel Button (only for owner of the leave)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmCancel(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    'Cancel Leave Application',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approveLeave(BuildContext context) async {
    final success = await context.read<LeaveProvider>().approveLeave(leave.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Leave Approved Successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Failed to approve leave'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectLeave(BuildContext context) async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Reason is required'), backgroundColor: AppColors.error),
                );
                return;
              }
              Navigator.pop(context); // Close dialog
              final success = await context.read<LeaveProvider>().rejectLeave(
                leaveId: leave.id, 
                reason: reasonController.text.trim()
              );
              
              if (context.mounted) {
                if (success) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Leave Rejected'), backgroundColor: AppColors.success),
                  );
                  Navigator.pop(context); // Close detail screen
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Failed to reject leave'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave?'),
        content: const Text(
          'Are you sure you want to cancel this leave application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep it'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              _cancelLeave(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelLeave(BuildContext context) async {
    final success = await context.read<LeaveProvider>().cancelLeave(leave.id);
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Go back to list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel leave'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
