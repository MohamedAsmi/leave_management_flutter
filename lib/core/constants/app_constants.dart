class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://31.97.71.5/leave-api'; // Change to your Laravel API URL
  // static const String baseUrl = 'http://localhost:8000/api'; // Change to your Laravel API URL
  static const String apiVersion = 'v1';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String userRoleKey = 'user_role';
  
  // Leave Types
  static const String casualLeave = 'casual';
  static const String shortLeave = 'short';
  static const String halfDayLeave = 'half_day';
  static const String otherLeave = 'other';
  
  // Session End Reasons
  static const String lunchBreak = 'lunch';
  static const String prayerBreak = 'prayer';
  static const String sessionShortLeave = 'short_leave';
  static const String sessionHalfDay = 'half_day';
  static const String sessionOther = 'other';
  
  // User Roles
  static const String adminRole = 'admin';
  static const String hrRole = 'hr';
  static const String staffRole = 'staff';
  
  // Leave Status
  static const String pendingStatus = 'pending';
  static const String approvedStatus = 'approved';
  static const String rejectedStatus = 'rejected';
  
  // Notification Types
  static const String leaveApplicationNotification = 'leave_application';
  static const String leaveApprovalNotification = 'leave_approval';
  static const String leaveRejectionNotification = 'leave_rejection';
  static const String timeManagementNotification = 'time_management';
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'hh:mm a';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
