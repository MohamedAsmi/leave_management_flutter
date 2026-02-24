import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:leave_management/core/theme/app_theme.dart';
import 'package:leave_management/data/services/api_client.dart';
import 'package:leave_management/data/services/auth_service.dart';
import 'package:leave_management/data/services/leave_service.dart';
import 'package:leave_management/data/services/time_log_service.dart';
import 'package:leave_management/data/services/notification_service.dart';
import 'package:leave_management/data/services/storage_service.dart';
import 'package:leave_management/data/services/user_service.dart';
import 'package:leave_management/providers/auth_provider.dart';
import 'package:leave_management/providers/leave_provider.dart';
import 'package:leave_management/providers/time_log_provider.dart';
import 'package:leave_management/providers/notification_provider.dart';
import 'package:leave_management/routes/app_router.dart';
import 'package:leave_management/data/services/duty_type_service.dart';
import 'package:leave_management/data/models/duty_type_model.dart';
import 'package:leave_management/providers/duty_type_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(DutyTypeAdapter());
  await Hive.openBox<DutyType>('duty_types');

  // Initialize Storage Service
  final storageService = StorageService();
  await storageService.init();

  // Initialize Services
  final apiClient = ApiClient(storageService);
  final authService = AuthService(apiClient);
  final leaveService = LeaveService(apiClient);
  final timeLogService = TimeLogService(apiClient);
  final notificationService = NotificationService(apiClient);
  final userService = UserService(apiClient);
  final dutyTypeService = DutyTypeService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        // Storage Service
        Provider<StorageService>.value(value: storageService),

        // API Client
        Provider<ApiClient>.value(value: apiClient),

        // Services
        Provider<AuthService>.value(value: authService),
        Provider<LeaveService>.value(value: leaveService),
        Provider<TimeLogService>.value(value: timeLogService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<UserService>.value(value: userService),
        Provider<DutyTypeService>.value(value: dutyTypeService),

        // Providers
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authService, storageService)..loadUserFromStorage(),
        ),
        ChangeNotifierProvider(create: (_) => LeaveProvider(leaveService)),
        ChangeNotifierProvider(create: (_) => TimeLogProvider(timeLogService)),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = DutyTypeProvider(dutyTypeService);
            provider.fetchAndCacheDutyTypes();
            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'Office Leave Management System',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router(authProvider),
    );
  }
}
