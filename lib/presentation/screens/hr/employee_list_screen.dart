import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/user_service.dart';

import '../../../data/services/time_log_service.dart';
import '../../../core/utils/csv_export_utils.dart';
import 'package:intl/intl.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  late UserService _userService;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _userService = UserService(apiClient);
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        final phone = (user.phone ?? '').toLowerCase();
        return name.contains(query) || email.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  Future<void> _generateWeeklyReport() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select any date in the target week',
    );
    if (pickedDate == null) return;

    int daysToSubtract = pickedDate.weekday - 1;
    DateTime startOfWeek = pickedDate.subtract(Duration(days: daysToSubtract));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    _generateReport(startOfWeek, endOfWeek, 'Weekly_Report_${DateFormat('yyyy_MM_dd').format(startOfWeek)}');
  }

  Future<void> _generateMonthlyReport() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select any date in the target month',
    );
    if (pickedDate == null) return;

    DateTime startOfMonth = DateTime(pickedDate.year, pickedDate.month, 1);
    DateTime endOfMonth = DateTime(pickedDate.year, pickedDate.month + 1, 0);

    _generateReport(startOfMonth, endOfMonth, 'Monthly_Report_${DateFormat('yyyy_MM').format(startOfMonth)}');
  }

  Future<void> _generateReport(DateTime startDate, DateTime endDate, String reportName) async {
    setState(() => _isLoading = true);
    try {
      final timeLogService = TimeLogService(context.read<ApiClient>());
      final reportData = await timeLogService.getComprehensiveReport(
        startDate: startDate,
        endDate: endDate,
      );
      
      await CsvExportUtils.exportAndShareReport(reportData, reportName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Employee'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'weekly') {
                _generateWeeklyReport();
              } else if (value == 'monthly') {
                _generateMonthlyReport();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'weekly',
                  child: Text('Generate Weekly Report'),
                ),
                const PopupMenuItem(
                  value: 'monthly',
                  child: Text('Generate Monthly Report'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No employees found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
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
                                  const SizedBox(height: 4),
                                  Text(user.email, style: TextStyle(color: AppColors.textSecondary)),
                                  if (user.phone != null) ...[
                                    const SizedBox(height: 2),
                                    Text(user.phone!, style: TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                context.push('/hr/attendance-detail', extra: user);
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
}
