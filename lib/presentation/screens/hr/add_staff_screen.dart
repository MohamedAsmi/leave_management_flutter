import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import 'package:leave_management/providers/user_provider.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _joinedDateController = TextEditingController();
  final _casualLeaveController = TextEditingController();
  final _medicalLeaveController = TextEditingController();
  final _annualLeaveController = TextEditingController();
  final _shortLeaveController = TextEditingController();
  final _halfDayLeaveController = TextEditingController();

  String _selectedRole = 'staff';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedJoinedDate;

  final List<String> _roles = ['staff', 'hr', 'admin', 'project_manager'];
  final List<String> _departments = [
    'Ceo',
    'Deputy Ceo',
    'Tech Lead',
    'Project Manager',
    'HR',
    'Admin Manager',
    'Senior Software Engineer',
    'Associate Software Engineer',
    'Senior Software Developer',
    'Software Developer',
    'Trainee Software Developer',
    'Trainee'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _joinedDateController.dispose();
    _casualLeaveController.dispose();
    _medicalLeaveController.dispose();
    _annualLeaveController.dispose();
    _shortLeaveController.dispose();
    _halfDayLeaveController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final newUser = await userProvider.createUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      department: _departmentController.text.trim().isEmpty
          ? null
          : _departmentController.text.trim(),
      designation: _designationController.text.trim().isEmpty
          ? null
          : _designationController.text.trim(),
      joinedDate: _selectedJoinedDate,
      casualLeaveBalance: _casualLeaveController.text.trim().isEmpty
          ? 7.0
          : double.tryParse(_casualLeaveController.text.trim()) ?? 7.0,
      medicalLeaveBalance: _medicalLeaveController.text.trim().isEmpty
          ? 7.0
          : double.tryParse(_medicalLeaveController.text.trim()) ?? 7.0,
      annualLeaveBalance: _annualLeaveController.text.trim().isEmpty
          ? 7.0
          : double.tryParse(_annualLeaveController.text.trim()) ?? 7.0,
      shortLeaveBalance: _shortLeaveController.text.trim().isEmpty
          ? 24.0
          : double.tryParse(_shortLeaveController.text.trim()) ?? 24.0,
      halfDayLeaveBalance: _halfDayLeaveController.text.trim().isEmpty
          ? 24.0
          : double.tryParse(_halfDayLeaveController.text.trim()) ?? 24.0,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (newUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff ${newUser.name} added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add staff: ${userProvider.error ?? "Unknown error"}',
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
        title: const Text('Add New Staff'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Register New Staff',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the details below to add a new staff member',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter full name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number (Optional)',
                hint: 'Enter phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Work Information Section
              _buildSectionHeader('Work Information'),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 16),
              _buildDepartmentField(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _designationController,
                label: 'Designation (Optional)',
                hint: 'e.g., Senior Developer, Manager',
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(),
              const SizedBox(height: 24),

              // Leave Information Section
              _buildSectionHeader('Leave Information'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLeaveBalanceField(
                      controller: _casualLeaveController,
                      label: 'Casual Leave',
                      hint: '7.0',
                      defaultValue: '7.0',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLeaveBalanceField(
                      controller: _medicalLeaveController,
                      label: 'Medical Leave',
                      hint: '7.0',
                      defaultValue: '7.0',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLeaveBalanceField(
                      controller: _annualLeaveController,
                      label: 'Annual Leave',
                      hint: '7.0',
                      defaultValue: '7.0',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLeaveBalanceField(
                      controller: _shortLeaveController,
                      label: 'Short Leave',
                      hint: '24.0',
                      defaultValue: '24.0',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLeaveBalanceField(
                      controller: _halfDayLeaveController,
                      label: 'Half Day Leave',
                      hint: '24.0',
                      defaultValue: '24.0',
                    ),
                  ),
                  const Expanded(child: SizedBox()), // Empty space to maintain layout
                ],
              ),
              const SizedBox(height: 24),

              // Security Section
              _buildSectionHeader('Security'),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter password',
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter password',
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(
                    _isLoading ? 'Adding Staff...' : 'Add Staff',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _roles.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Row(
            children: [
              Icon(
                _getRoleIcon(role),
                size: 20,
                color: _getRoleColor(role),
              ),
              const SizedBox(width: 12),
              Text(
                role.substring(0, 1).toUpperCase() + role.substring(1),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
        });
      },
    );
  }

  Widget _buildDepartmentField() {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _departments;
        }
        return _departments.where((option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (selection) {
        _departmentController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        _departmentController.text = controller.text;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Department (Optional)',
            hintText: 'Select or enter department',
            prefixIcon: const Icon(Icons.business_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onEditingComplete: onEditingComplete,
        );
      },
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'hr':
        return Icons.people;
      case 'project_manager':
        return Icons.account_tree;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'hr':
        return AppColors.secondary;
      case 'project_manager':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedJoinedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() {
            _selectedJoinedDate = pickedDate;
            _joinedDateController.text = 
                "${pickedDate.day.toString().padLeft(2, '0')}/"
                "${pickedDate.month.toString().padLeft(2, '0')}/"
                "${pickedDate.year}";
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _joinedDateController,
          decoration: InputDecoration(
            labelText: 'Joined Date (Optional)',
            hintText: 'Select joining date',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            suffixIcon: _selectedJoinedDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedJoinedDate = null;
                        _joinedDateController.clear();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String defaultValue,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '$label (Optional)',
        hintText: hint,
        helperText: 'Default: $defaultValue days',
        helperStyle: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(Icons.beach_access_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final doubleValue = double.tryParse(value.trim());
          if (doubleValue == null) {
            return 'Enter a valid number';
          }
          if (doubleValue < 0) {
            return 'Cannot be negative';
          }
          if (doubleValue > 365) {
            return 'Cannot exceed 365 days';
          }
        }
        return null;
      },
    );
  }
}
