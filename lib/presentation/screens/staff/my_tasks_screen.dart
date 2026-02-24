import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/providers/auth_provider.dart';
import 'package:leave_management/providers/project_provider.dart';
import 'package:leave_management/data/models/task_model.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _selectedFilter = 'all';
  String _selectedPriority = 'all';

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    final projectProvider = context.read<ProjectProvider>();
    await projectProvider.fetchMyTasks();
  }

  void _filterTasks(String? filter) {
    if (filter == null) return;
    setState(() {
      _selectedFilter = filter;
    });

    final projectProvider = context.read<ProjectProvider>();
    projectProvider.fetchMyTasks(
      status: filter == 'all' ? null : filter,
      priority: _selectedPriority == 'all' ? null : _selectedPriority,
    );
  }

  void _filterByPriority(String? priority) {
    if (priority == null) return;
    setState(() {
      _selectedPriority = priority;
    });

    final projectProvider = context.read<ProjectProvider>();
    projectProvider.fetchMyTasks(
      status: _selectedFilter == 'all' ? null : _selectedFilter,
      priority: priority == 'all' ? null : priority,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<ProjectProvider>(
              builder: (context, provider, _) {
                final tasks = provider.myTasks;
                final todoCount = tasks.where((t) => t.status == 'todo').length;
                final inProgressCount = tasks.where((t) => t.status == 'in_progress').length;
                final completedCount = tasks.where((t) => t.status == 'completed').length;
                final overdueCount = tasks.where((t) => t.isOverdue).length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'To Do',
                        todoCount.toString(),
                        Icons.radio_button_unchecked,
                        Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'In Progress',
                        inProgressCount.toString(),
                        Icons.timelapse,
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Completed',
                        completedCount.toString(),
                        Icons.check_circle,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Overdue',
                        overdueCount.toString(),
                        Icons.warning,
                        AppColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Filter Chips - Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all', _selectedFilter, _filterTasks),
                const SizedBox(width: 8),
                _buildFilterChip('To Do', 'todo', _selectedFilter, _filterTasks),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'in_progress', _selectedFilter, _filterTasks),
                const SizedBox(width: 8),
                _buildFilterChip('In Review', 'in_review', _selectedFilter, _filterTasks),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed', _selectedFilter, _filterTasks),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips - Priority
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Priority: ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all', _selectedPriority, _filterByPriority),
                const SizedBox(width: 8),
                _buildFilterChip('Urgent', 'urgent', _selectedPriority, _filterByPriority),
                const SizedBox(width: 8),
                _buildFilterChip('High', 'high', _selectedPriority, _filterByPriority),
                const SizedBox(width: 8),
                _buildFilterChip('Medium', 'medium', _selectedPriority, _filterByPriority),
                const SizedBox(width: 8),
                _buildFilterChip('Low', 'low', _selectedPriority, _filterByPriority),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tasks List
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMyTasks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.myTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks assigned',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have no tasks assigned to you yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort tasks: overdue first, then by due date
                final sortedTasks = List<TaskModel>.from(provider.myTasks);
                sortedTasks.sort((a, b) {
                  if (a.isOverdue && !b.isOverdue) return -1;
                  if (!a.isOverdue && b.isOverdue) return 1;
                  if (a.dueDate != null && b.dueDate != null) {
                    return a.dueDate!.compareTo(b.dueDate!);
                  }
                  return 0;
                });

                return RefreshIndicator(
                  onRefresh: _loadMyTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedTasks.length,
                    itemBuilder: (context, index) {
                      final task = sortedTasks[index];
                      return _buildTaskCard(task, authProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    Function(String?) onSelected,
  ) {
    final isSelected = selectedValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onSelected(value),
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: task.isOverdue
            ? BorderSide(color: AppColors.error, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/staff/tasks/${task.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTaskStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTaskStatusIcon(task.status),
                      color: _getTaskStatusColor(task.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.projectName != null)
                          Text(
                            task.projectName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              const SizedBox(height: 12),

              // Task Description
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Task Details Row
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: task.isOverdue ? AppColors.error : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue ? AppColors.error : Colors.grey[600],
                        fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                  if (task.isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (task.estimatedHours != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${task.estimatedHours}h',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Badge
              _buildStatusBadge(task.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
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
