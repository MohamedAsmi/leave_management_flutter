# Office Leave Management System - Flutter Application

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide constants
│   │   └── colors.dart             # Color palette
│   ├── theme/
│   │   └── app_theme.dart          # App theme configuration
│   └── utils/
│       ├── validators.dart         # Form validators
│       └── date_time_utils.dart    # Date/time utilities
├── data/
│   ├── models/
│   │   ├── user_model.dart         # User data model
│   │   ├── leave_model.dart        # Leave data model
│   │   ├── time_log_model.dart     # Time log data model
│   │   ├── notification_model.dart # Notification model
│   │   └── leave_policy.dart       # Leave policy model
│   └── services/
│       ├── api_client.dart         # HTTP client wrapper
│       ├── storage_service.dart    # Local storage service
│       ├── auth_service.dart       # Authentication API
│       ├── leave_service.dart      # Leave management API
│       ├── time_log_service.dart   # Time tracking API
│       ├── notification_service.dart # Notification API
│       └── user_service.dart       # User management API
├── providers/
│   ├── auth_provider.dart          # Authentication state
│   ├── leave_provider.dart         # Leave management state
│   ├── time_log_provider.dart      # Time tracking state
│   └── notification_provider.dart  # Notification state
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── admin/
│   │   │   ├── admin_dashboard.dart
│   │   │   ├── user_management.dart
│   │   │   ├── leave_approvals.dart
│   │   │   ├── time_logs_monitor.dart
│   │   │   └── settings.dart
│   │   ├── hr/
│   │   │   ├── hr_dashboard.dart
│   │   │   ├── leave_management.dart
│   │   │   ├── attendance_monitor.dart
│   │   │   └── reports.dart
│   │   └── staff/
│   │       ├── staff_dashboard.dart
│   │       ├── apply_leave.dart
│   │       ├── my_leaves.dart
│   │       ├── time_tracker.dart
│   │       └── profile.dart
│   └── widgets/
│       ├── common/
│       │   ├── custom_button.dart
│       │   ├── custom_text_field.dart
│       │   ├── loading_indicator.dart
│       │   └── error_widget.dart
│       ├── leave/
│       │   ├── leave_card.dart
│       │   ├── leave_status_badge.dart
│       │   └── leave_type_selector.dart
│       └── time/
│           ├── time_log_card.dart
│           ├── session_timer.dart
│           └── end_reason_dialog.dart
├── routes/
│   └── app_router.dart             # Navigation configuration
└── main.dart                       # Application entry point
```

## Features Implemented

### ✅ Core Features
- Complete project structure with clean architecture
- Hive for local data caching
- Provider for state management
- Go Router for navigation
- Dio for HTTP requests
- Material 3 design system

### ✅ Services Layer
- **API Client**: Generic HTTP client with interceptors
- **Storage Service**: SharedPreferences wrapper
- **Auth Service**: Login, register, logout, profile management
- **Leave Service**: Leave applications, approvals, balance tracking
- **Time Log Service**: Session tracking, reports
- **Notification Service**: Real-time notifications
- **User Service**: User CRUD operations

### ✅ State Management
- **AuthProvider**: Authentication state
- **LeaveProvider**: Leave management state
- **TimeLogProvider**: Time tracking state
- **NotificationProvider**: Notification state

### ✅ Data Models
- User Model (with Hive annotations)
- Leave Model (with Hive annotations)
- Time Log Model (with Hive annotations)
- Notification Model (with Hive annotations)
- Leave Policy Model

### ✅ UI Screens
- Login Screen
- Dashboard placeholders (Admin, HR, Staff)

## Next Steps to Complete the Application

### 1. Staff Dashboard & Features
- [ ] Complete staff dashboard with stats
- [ ] Apply leave screen
- [ ] My leaves screen with filters
- [ ] Time tracker screen
- [ ] Profile management screen

### 2. Admin Dashboard & Features
- [ ] Admin dashboard with system overview
- [ ] User management (CRUD operations)
- [ ] Leave approvals screen
- [ ] Time logs monitoring
- [ ] Leave policy configuration
- [ ] Reports and analytics

### 3. HR Dashboard & Features
- [ ] HR dashboard with team overview
- [ ] Leave management screen
- [ ] Attendance monitoring
- [ ] Team reports
- [ ] Leave balance updates

### 4. Common Features
- [ ] Notifications screen
- [ ] Notification badges
- [ ] Pull-to-refresh on lists
- [ ] Search and filter functionality
- [ ] Date range pickers
- [ ] Export reports (PDF/Excel)

### 5. Polish & Testing
- [ ] Error handling improvements
- [ ] Loading states
- [ ] Empty states
- [ ] Success/error messages
- [ ] Form validation
- [ ] Offline support
- [ ] Unit tests
- [ ] Widget tests

## Configuration

### Update API Base URL

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://your-api-url.com/api';
```

For local development:
- Android emulator: `http://10.0.2.2:8000/api`
- iOS simulator: `http://localhost:8000/api`
- Physical device: `http://192.168.x.x:8000/api` (your local IP)

## Running the Application

```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Key Dependencies

```yaml
dependencies:
  # State Management
  provider: ^6.1.1
  
  # HTTP & API
  http: ^1.2.0
  dio: ^5.4.0
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Navigation
  go_router: ^14.0.0
  
  # Date & Time
  intl: ^0.19.0
  
  # Notifications
  flutter_local_notifications: ^17.0.0
  
  # Utils
  uuid: ^4.3.3
  logger: ^2.0.2+1
```

## User Roles & Permissions

### Admin
- Full system access
- Manage all users (create, update, delete)
- Configure leave policies
- Approve/reject all leaves
- Monitor all time logs
- View all reports and statistics

### HR
- View employee profiles
- Monitor leave status
- Approve/reject leaves (as permitted)
- Configure casual/short leave limits
- View time logs
- Generate reports

### Staff
- Apply for leave
- View personal leave balance
- View leave history
- Start/end work sessions
- View personal attendance
- Update profile

## API Integration

All API services are already implemented and ready to connect to your Laravel backend. Simply ensure your Laravel API is running and update the `baseUrl` in constants.

### Example: Fetching Leaves

```dart
// In your widget
final leaveProvider = Provider.of<LeaveProvider>(context);

// Fetch my leaves
await leaveProvider.fetchMyLeaves();

// Display leaves
final leaves = leaveProvider.myLeaves;
```

## Documentation

- **[LARAVEL_API_DOCUMENTATION.md](LARAVEL_API_DOCUMENTATION.md)** - Complete Laravel API documentation
- **[LARAVEL_SETUP.md](LARAVEL_SETUP.md)** - Step-by-step Laravel backend setup guide

## Support

For questions or issues, refer to:
- [LARAVEL_API_DOCUMENTATION.md](LARAVEL_API_DOCUMENTATION.md) - Backend API documentation
- [LARAVEL_SETUP.md](LARAVEL_SETUP.md) - Laravel setup guide
- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Documentation](https://pub.dev/packages/provider)

---

**Project Status**: Core architecture complete, ready for UI development  
**Version**: 1.0.0  
**Last Updated**: February 5, 2026
