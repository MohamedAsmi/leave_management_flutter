import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/colors.dart';
import 'package:leave_management/providers/project_provider.dart';
import 'package:leave_management/providers/auth_provider.dart';

class PMProjectFormScreen extends StatefulWidget {
  final int? projectId; // null for create, non-null for edit

  const PMProjectFormScreen({
    super.key,
    this.projectId,
  });

  @override
  State<PMProjectFormScreen> createState() => _PMProjectFormScreenState();
}

class _PMProjectFormScreenState extends State<PMProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  String _status = 'planning';
  String _priority = 'medium';
  DateTime? _startDate;
  DateTime? _endDate;
  int _progress = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadProject();
    }
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    final projectProvider = context.read<ProjectProvider>();
    await projectProvider.fetchProjectById(widget.projectId!);
    
    if (mounted && projectProvider.selectedProject != null) {
      final project = projectProvider.selectedProject!;
      _nameController.text = project.name;
      _descriptionController.text = project.description;
      _budgetController.text = project.budget?.toString() ?? '';
      _status = project.status;
      _priority = project.priority;
      _startDate = project.startDate;
      _endDate = project.endDate;
      _progress = project.progress;
    }
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final projectProvider = context.read<ProjectProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? 0;

    bool success;

    if (widget.projectId == null) {
      // Create new project
      success = await projectProvider.createProject(
        name: _nameController.text,
        description: _descriptionController.text,
        status: _status,
        startDate: _startDate!,
        endDate: _endDate!,
        projectManagerId: currentUserId,
        budget: double.tryParse(_budgetController.text),
        progress: _progress,
        priority: _priority,
      );
    } else {
      // Update existing project
      success = await projectProvider.updateProject(
        projectId: widget.projectId!,
        name: _nameController.text,
        description: _descriptionController.text,
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        budget: double.tryParse(_budgetController.text),
        progress: _progress,
        priority: _priority,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.projectId == null
                  ? 'Project created successfully'
                  : 'Project updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              projectProvider.errorMessage ?? 'Operation failed',
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
      appBar: AppBar(
        title: Text(widget.projectId == null ? 'Create Project' : 'Edit Project'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Project Name *',
                        hintText: 'Enter project name',
                        prefixIcon: const Icon(Icons.folder),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter project name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Enter project description',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'planning', child: Text('Planning')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Priority Dropdown
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: const Icon(Icons.priority_high),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                        DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                        DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                        DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Fields Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Date *',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _startDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                    : 'Select Date',
                                style: TextStyle(
                                  color: _startDate != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date *',
                                prefixIcon: const Icon(Icons.event),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                    : 'Select Date',
                                style: TextStyle(
                                  color: _endDate != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Budget Field
                    TextFormField(
                      controller: _budgetController,
                      decoration: InputDecoration(
                        labelText: 'Budget',
                        hintText: 'Enter budget amount',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final budget = double.tryParse(value);
                          if (budget == null || budget < 0) {
                            return 'Please enter a valid budget';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Progress Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress: $_progress%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Slider(
                          value: _progress.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$_progress%',
                          onChanged: (value) {
                            setState(() => _progress = value.toInt());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProject,
                        icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.save),
                        label: Text(
                          widget.projectId == null ? 'Create Project' : 'Save Changes',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
