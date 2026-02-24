import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/providers/auth_provider.dart';
import 'package:leave_management/providers/project_provider.dart';
import 'package:leave_management/providers/notification_provider.dart';
import 'package:leave_management/data/models/task_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _actualHoursController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  @override
  void dispose() {
    _actualHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskDetails() async {
    final projectProvider = context.read<ProjectProvider>();
    final taskId = int.parse(widget.taskId);
    await projectProvider.fetchTaskById(taskId);
    
    // Set actual hours if available
    if (projectProvider.selectedTask?.actualHours != null) {
      _actualHoursController.text = projectProvider.selectedTask!.actualHours.toString();
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    final projectProvider = context.read<ProjectProvider>();
    final taskId = int.parse(widget.taskId);

    setState(() {
      _isSaving = true;
    });

    final success = await projectProvider.updateTask(
      taskId: taskId,
      status: newStatus,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task status updated. Project manager notified.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadTaskDetails();
        // Refresh notifications
        context.read<NotificationProvider>().fetchUnreadCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectProvider.errorMessage ?? 'Failed to update task'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateActualHours() async {
    final projectProvider = context.read<ProjectProvider>();
    final taskId = int.parse(widget.taskId);
    
    final actualHours = double.tryParse(_actualHoursController.text);
    if (actualHours == null || actualHours < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid hours'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await projectProvider.updateTask(
      taskId: taskId,
      actualHours: actualHours,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actual hours updated. Project manager notified.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadTaskDetails();
        // Refresh notifications
        context.read<NotificationProvider>().fetchUnreadCount();
        await _loadTaskDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectProvider.errorMessage ?? 'Failed to update hours'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Screenshot Upload Methods
  void _showUploadOptions() {
    // Check if camera is available (only on mobile)
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isMobile) // Only show camera option on mobile devices
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppColors.primary),
              title: const Text('Browse Files'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAttachment(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAttachment(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        await _uploadAttachment(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadAttachment(File file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final projectProvider = context.read<ProjectProvider>();
      final taskId = int.parse(widget.taskId);

      // For now, show a message that this feature requires backend implementation
      // In production, you would call: await projectProvider.uploadTaskAttachment(taskId: taskId, file: file);
      
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Screenshot upload feature requires backend API implementation. See SCREENSHOT_UPLOAD_IMPLEMENTATION.md for details.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showStatusUpdateDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Task Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('To Do', 'todo', task.status),
            _buildStatusOption('In Progress', 'in_progress', task.status),
            _buildStatusOption('In Review', 'in_review', task.status),
            _buildStatusOption('Completed', 'completed', task.status),
            _buildStatusOption('Blocked', 'blocked', task.status),
          ],
        ),
      ),
    );
  }

  void _showLogHoursDialog(TaskModel task) {
    // Reset controller with current actual hours or empty
    _actualHoursController.text = task.actualHours?.toString() ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Working Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.estimatedHours != null) ...[
              Text(
                'Estimated: ${task.estimatedHours} hours',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _actualHoursController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Actual Hours Worked',
                prefixIcon: const Icon(Icons.access_time),
                suffixText: 'hours',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Enter the actual time spent on this task',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _updateActualHours();
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Hours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String status, String currentStatus) {
    final isSelected = status == currentStatus;
    return ListTile(
      leading: Icon(
        _getTaskStatusIcon(status),
        color: _getTaskStatusColor(status),
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.success)
          : null,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          _updateTaskStatus(status);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTaskDetails,
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.selectedTask == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load task details'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTaskDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final task = provider.selectedTask!;
          final isAssignedToMe = task.assignedTo == authProvider.currentUser?.id;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getTaskStatusColor(task.status).withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTaskStatusColor(task.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getTaskStatusIcon(task.status),
                              size: 32,
                              color: _getTaskStatusColor(task.status),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (task.projectName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Project: ${task.projectName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildPriorityBadge(task.priority),
                          const SizedBox(width: 12),
                          _buildStatusBadge(task.status),
                          if (task.isOverdue) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.error, width: 2),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning, size: 14, color: AppColors.error),
                                  SizedBox(width: 4),
                                  Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Task Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Task Information
                      const Text(
                        'Task Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildInfoRow(Icons.person, 'Assigned To', task.assignedToName ?? 'Unassigned'),
                      _buildInfoRow(Icons.person_outline, 'Created By', task.createdByName ?? 'Unknown'),
                      
                      if (task.dueDate != null)
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Due Date',
                          DateFormat('MMMM dd, yyyy').format(task.dueDate!),
                          isHighlighted: task.isOverdue,
                        ),
                      
                      if (task.completedAt != null)
                        _buildInfoRow(
                          Icons.check_circle,
                          'Completed At',
                          DateFormat('MMMM dd, yyyy HH:mm').format(task.completedAt!),
                        ),

                      const SizedBox(height: 24),

                      // Time Tracking
                      const Text(
                        'Time Tracking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (task.estimatedHours != null)
                        _buildInfoRow(
                          Icons.timer,
                          'Estimated Hours',
                          '${task.estimatedHours} hours',
                        ),

                      // Show Actual Hours if logged
                      if (task.actualHours != null)
                        _buildInfoRow(
                          Icons.access_time,
                          'Actual Hours',
                          '${task.actualHours} hours',
                        ),

                      if (task.hoursVariance != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: task.hoursVariance! > 0
                                ? Colors.orange.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                task.hoursVariance! > 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 20,
                                color: task.hoursVariance! > 0
                                    ? Colors.orange
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Variance: ${task.hoursVariance!.abs()} hours ${task.hoursVariance! > 0 ? "over" : "under"} estimate',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: task.hoursVariance! > 0
                                      ? Colors.orange
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons (only for assigned user)
                      if (isAssignedToMe && task.status != 'completed') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : () => _showStatusUpdateDialog(task),
                                icon: const Icon(Icons.update),
                                label: const Text('Update Status'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSaving ? null : () => _showLogHoursDialog(task),
                                icon: const Icon(Icons.timer),
                                label: const Text('Log Hours'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: AppColors.primary),
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Screenshot Upload Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _showUploadOptions,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_photo_alternate),
                            label: Text(_isUploading ? 'Uploading...' : 'Upload Screenshot'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],

                      if (task.status == 'completed') ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success),
                              SizedBox(width: 12),
                              Text(
                                'This task is completed',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlighted ? AppColors.error : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? AppColors.error : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getTaskStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusLabel(status),
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

  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'todo':
        return Colors.grey;
      case 'in_progress':
        return AppColors.info;
      case 'in_review':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'blocked':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskStatusIcon(String status) {
    switch (status) {
      case 'todo':
        return Icons.radio_button_unchecked;
      case 'in_progress':
        return Icons.timelapse;
      case 'in_review':
        return Icons.rate_review;
      case 'completed':
        return Icons.check_circle;
      case 'blocked':
        return Icons.block;
      default:
        return Icons.task;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return Colors.orange;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'in_progress':
        return 'In Progress';
      case 'in_review':
        return 'In Review';
      case 'completed':
        return 'Completed';
      case 'blocked':
        return 'Blocked';
      default:
        return status;
    }
  }
}
