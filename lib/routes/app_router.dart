import 'package:go_router/go_router.dart';
import 'package:leave_management/presentation/screens/auth/login_screen.dart';
import 'package:leave_management/presentation/screens/auth/register_screen.dart';
import 'package:leave_management/presentation/screens/staff/staff_dashboard.dart';
import 'package:leave_management/presentation/screens/admin/admin_dashboard.dart';
import 'package:leave_management/presentation/screens/hr/hr_dashboard.dart';
import 'package:leave_management/presentation/screens/staff/my_leaves_screen.dart';
import 'package:leave_management/presentation/screens/staff/leave_detail_screen.dart';
import 'package:leave_management/data/models/leave_model.dart';
import 'package:leave_management/providers/auth_provider.dart';

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
    ],
  );
}
