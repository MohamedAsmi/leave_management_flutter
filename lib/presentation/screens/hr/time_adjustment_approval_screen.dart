import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/providers/time_adjustment_provider.dart';
import 'package:leave_management/data/models/time_adjustment_request_model.dart';

class TimeAdjustmentApprovalScreen extends StatefulWidget {
  const TimeAdjustmentApprovalScreen({super.key});

  @override
  State<TimeAdjustmentApprovalScreen> createState() =>
      _TimeAdjustmentApprovalScreenState();
}

class _TimeAdjustmentApprovalScreenState
    extends State<TimeAdjustmentApprovalScreen> {
  String _selectedStatus = 'All';

  final List<String> _statuses = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimeAdjustmentProvider>().fetchAllRequests();
    });
  }

  Future<void> _refresh() async {
    await context.read<TimeAdjustmentProvider>().fetchAllRequests();
  }

  void _onStatusChanged(String? value) {
    if (value != null) {
      setState(() => _selectedStatus = value);
    }
  }

  List<TimeAdjustmentRequestModel> _filterRequests(
    List<TimeAdjustmentRequestModel> requests,
  ) {
    if (_selectedStatus == 'All') return requests;
    return requests
        .where(
          (r) => r.status.toLowerCase() == _selectedStatus.toLowerCase(),
        )
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.approved;
      case 'rejected':
        return AppColors.rejected;
      case 'pending':
      default:
        return AppColors.pending;
    }
  }

  Future<void> _approveRequest(TimeAdjustmentRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
          'Approve time adjustment for ${request.userName} on '
          '${DateFormat('MMM d, yyyy').format(request.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TimeAdjustmentProvider>();
      final success = await provider.approveRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Request approved and time logs updated'
                  : provider.errorMessage?.replaceAll('Exception: ', '') ??
                      'Failed to approve',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) _refresh();
      }
    }
  }

  Future<void> _rejectRequest(TimeAdjustmentRequestModel request) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject time adjustment for ${request.userName} on '
              '${DateFormat('MMM d, yyyy').format(request.date)}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter the reason for rejection...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TimeAdjustmentProvider>();
      final success = await provider.rejectRequest(
        request.id,
        reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Request rejected'
                  : provider.errorMessage?.replaceAll('Exception: ', '') ??
                      'Failed to reject',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) _refresh();
      }
    }

    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Adjustment Requests')),
      body: Consumer<TimeAdjustmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _filterRequests(provider.allRequests);
          // Sort: pending first, then by date descending
          filtered.sort((a, b) {
            if (a.status == 'pending' && b.status != 'pending') return -1;
            if (a.status != 'pending' && b.status == 'pending') return 1;
            return b.date.compareTo(a.date);
          });

          return Column(
            children: [
              // Filter
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _statuses.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: _onStatusChanged,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No requests found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(filtered[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(TimeAdjustmentRequestModel request) {
    final statusColor = _getStatusColor(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(request.date),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Times
            if (request.requestedStartTime != null)
              _buildTimeRow(
                'Start Time',
                DateFormat('h:mm a').format(request.requestedStartTime!),
                Icons.login,
                AppColors.success,
              ),
            if (request.requestedStartTime != null &&
                request.requestedEndTime != null)
              const SizedBox(height: 6),
            if (request.requestedEndTime != null)
              _buildTimeRow(
                'End Time',
                DateFormat('h:mm a').format(request.requestedEndTime!),
                Icons.logout,
                AppColors.error,
              ),
            const SizedBox(height: 10),
            // Reason
            Text(
              request.reason,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
            // Rejection reason
            if (request.status == 'rejected' &&
                request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Text(
                  'Rejection: ${request.rejectionReason}',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            ],
            // Action buttons for pending
            if (request.status == 'pending') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildTimeRow(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        Text(
          time,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
