import 'package:go_router/go_router.dart';
import 'package:leave_management/presentation/screens/auth/login_screen.dart';
import 'package:leave_management/presentation/screens/auth/register_screen.dart';
import 'package:leave_management/presentation/screens/staff/staff_dashboard.dart';
import 'package:leave_management/presentation/screens/admin/admin_dashboard.dart';
import 'package:leave_management/presentation/screens/hr/hr_dashboard.dart';
import 'package:leave_management/presentation/screens/hr/leave_approval_screen.dart';
import 'package:leave_management/presentation/screens/staff/apply_leave_screen.dart';
import 'package:leave_management/presentation/screens/staff/my_leaves_screen.dart';
import 'package:leave_management/presentation/screens/staff/leave_detail_screen.dart';
import 'package:leave_management/data/models/leave_model.dart';
import 'package:leave_management/providers/auth_provider.dart';

import 'package:leave_management/presentation/screens/hr/employee_list_screen.dart';
import 'package:leave_management/presentation/screens/hr/user_attendance_detail_screen.dart';
import 'package:leave_management/presentation/screens/hr/staff_management_screen.dart';
import 'package:leave_management/presentation/screens/hr/add_staff_screen.dart';
import 'package:leave_management/presentation/screens/hr/today_attendance_screen.dart';
import 'package:leave_management/presentation/screens/hr/employee_list_screen_for_timelog.dart';
import 'package:leave_management/presentation/screens/hr/hr_time_log_screen.dart';
import 'package:leave_management/presentation/screens/hr/team_reports_screen.dart';
import 'package:leave_management/presentation/screens/hr/user_weekly_report_screen.dart';
import 'package:leave_management/data/models/user_model.dart';
import 'package:leave_management/presentation/screens/staff/staff_projects_screen.dart';
import 'package:leave_management/presentation/screens/staff/project_detail_screen.dart';
import 'package:leave_management/presentation/screens/staff/my_tasks_screen.dart';
import 'package:leave_management/presentation/screens/staff/task_detail_screen.dart';
import 'package:leave_management/presentation/screens/common/notifications_screen.dart';

import 'package:leave_management/presentation/screens/hr/time_adjustment_approval_screen.dart';
import 'package:leave_management/presentation/screens/hr/hr_apply_leave_screen.dart';
import 'package:leave_management/presentation/screens/hr/hr_time_tracking_screen.dart';
import 'package:leave_management/presentation/screens/staff/my_time_adjustments_screen.dart';
import 'package:leave_management/presentation/screens/staff/time_adjustment_request_screen.dart';

// PM Screens
import 'package:leave_management/presentation/screens/pm/pm_dashboard.dart';
import 'package:leave_management/presentation/screens/pm/pm_projects_screen.dart';
import 'package:leave_management/presentation/screens/pm/pm_project_form_screen.dart';
import 'package:leave_management/presentation/screens/pm/pm_project_detail_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) => GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isLoading = authProvider.isLoading;

      // Show splash/loading screen while checking auth status
      if (isLoading) {
        return null; // Stay on current route while loading
      }

      final currentPath = state.uri.path;
      final isOnLoginPage = currentPath == '/login';
      final isOnRegisterPage = currentPath == '/register';

      // If not logged in and not on auth pages, redirect to login
      if (!isLoggedIn && !isOnLoginPage && !isOnRegisterPage) {
        return '/login';
      }

      // If logged in and on auth pages, redirect to appropriate dashboard
      if (isLoggedIn && (isOnLoginPage || isOnRegisterPage)) {
        final user = authProvider.currentUser;
        if (user != null) {
          if (user.isAdmin) return '/admin/dashboard';
          if (user.isHR) return '/hr/dashboard';
          if (user.isProjectManager) return '/pm/dashboard';
          return '/staff/dashboard';
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final user = authProvider.currentUser;
          if (user != null) {
            if (user.isAdmin) return '/admin/dashboard';
            if (user.isHR) return '/hr/dashboard';
            if (user.isProjectManager) return '/pm/dashboard';
            return '/staff/dashboard';
          }
          return '/login';
        },
      ),

      // Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),

      // HR Routes
      GoRoute(
        path: '/hr/dashboard',
        builder: (context, state) => const HRDashboard(),
      ),
      GoRoute(
        path: '/hr/leave-approvals',
        builder: (context, state) => const LeaveApprovalScreen(),
      ),

      GoRoute(
        path: '/hr/attendance',
        builder: (context, state) => const EmployeeListScreen(),
      ),

      GoRoute(
        path: '/hr/EmployeeListScreenForTimeLog',
        builder: (context, state) => const EmployeeListScreenForTimelog(),
      ),

      GoRoute(
        path: '/hr/staff-time-logs',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return HrTimeLogScreen(user: user);
        },
      ),

      GoRoute(
        path: '/hr/attendance-detail',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return UserAttendanceDetailScreen(user: user);
        },
      ),

      GoRoute(
        path: '/hr/staff',
        builder: (context, state) => const StaffManagementScreen(),
      ),

      GoRoute(
        path: '/hr/staff/add',
        builder: (context, state) => const AddStaffScreen(),
      ),

      GoRoute(
        path: '/hr/today-attendance',
        builder: (context, state) => const TodayAttendanceScreen(),
      ),

      GoRoute(
        path: '/hr/team-reports',
        builder: (context, state) => const TeamReportsScreen(),
      ),

      GoRoute(
        path: '/hr/user-weekly-report',
        builder: (context, state) {
          final user = state.extra as UserModel?;
          return UserWeeklyReportScreen(initialUser: user);
        },
      ),

      GoRoute(
        path: '/hr/time-adjustments',
        builder: (context, state) => const TimeAdjustmentApprovalScreen(),
      ),

      GoRoute(
        path: '/hr/apply-leave',
        builder: (context, state) => const HrApplyLeaveScreen(),
      ),

      GoRoute(
        path: '/hr/time-tracking',
        builder: (context, state) => const HRTimeTrackingScreen(),
      ),

      GoRoute(
        path: '/staff/dashboard',
        builder: (context, state) => const StaffDashboard(),
      ),

      // My Leaves
      GoRoute(
        path: '/my-leaves',
        builder: (context, state) => const MyLeavesScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final leave = state.extra as LeaveModel;
              return LeaveDetailScreen(leave: leave);
            },
          ),
        ],
      ),

      // Apply Leave
      GoRoute(
        path: '/apply-leave',
        builder: (context, state) => const ApplyLeaveScreen(),
      ),

      // Time Adjustments
      GoRoute(
        path: '/staff/time-adjustments',
        builder: (context, state) => const TimeAdjustmentRequestScreen(),
      ),
      GoRoute(
        path: '/staff/time-adjustments/request',
        builder: (context, state) => const TimeAdjustmentRequestScreen(),
      ),

      // Notifications (accessible by all roles)
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Staff Projects Routes
      GoRoute(
        path: '/staff/projects',
        builder: (context, state) => const StaffProjectsScreen(),
      ),

      GoRoute(
        path: '/staff/projects/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: projectId);
        },
      ),

      // Staff Tasks Routes
      GoRoute(
        path: '/staff/tasks',
        builder: (context, state) => const MyTasksScreen(),
      ),

      GoRoute(
        path: '/staff/tasks/:id',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),

      // PM Routes
      GoRoute(
        path: '/pm/dashboard',
        builder: (context, state) => const PMDashboard(),
      ),

      GoRoute(
        path: '/pm/projects',
        builder: (context, state) => const PMProjectsScreen(),
      ),

      GoRoute(
        path: '/pm/projects/create',
        builder: (context, state) => const PMProjectFormScreen(),
      ),

      GoRoute(
        path: '/pm/projects/:id/edit',
        builder: (context, state) {
          final projectId = int.parse(state.pathParameters['id']!);
          return PMProjectFormScreen(projectId: projectId);
        },
      ),

      GoRoute(
        path: '/pm/projects/:id',
        builder: (context, state) {
          final projectId = int.parse(state.pathParameters['id']!);
          return PMProjectDetailScreen(projectId: projectId);
        },
      ),
    ],
  );
}
