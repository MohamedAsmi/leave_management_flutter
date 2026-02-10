# Quick Start Guide - Office Leave Management System

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Flutter SDK installed
- Dart SDK installed
- Android Studio / VS Code
- Laravel (for backend)
- MySQL/PostgreSQL

---

## Step 1: Run the Flutter App (2 minutes)

```bash
# Navigate to project
cd d:\laragon\www\leave_management

# Install dependencies (if not already done)
flutter pub get

# Run the app
flutter run
```

The app will open with a **Login Screen**.

---

## Step 2: Set Up Laravel Backend (Optional - 15 minutes)

### Quick Setup

```bash
# Navigate to Laragon www folder
cd d:\laragon\www

# Create Laravel project
composer create-project laravel/laravel leave-management-api

# Navigate to project
cd leave-management-api

# Install Sanctum
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# Configure .env
# Set database credentials

# Create database
# In MySQL: CREATE DATABASE leave_management;

# Follow LARAVEL_SETUP.md for detailed steps
```

For complete backend setup, see **[LARAVEL_SETUP.md](LARAVEL_SETUP.md)**

---

## Step 3: Connect Flutter to API (30 seconds)

### Update API Base URL

Edit: `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // Change this to your Laravel API URL
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  // OR
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS Simulator
  // OR
  // static const String baseUrl = 'http://192.168.1.100:8000/api'; // Physical Device
  
  // ... rest of the code
}
```

### API URLs for Different Platforms

| Platform | URL |
|----------|-----|
| Android Emulator | `http://10.0.2.2:8000/api` |
| iOS Simulator | `http://localhost:8000/api` |
| Physical Device | `http://YOUR_LOCAL_IP:8000/api` |
| Production | `https://your-api-domain.com/api` |

---

## Step 4: Test the App

### Using Mock Mode (Without Backend)

The app is designed to work with placeholder data for testing. You can:

1. Open the app
2. View the login screen
3. Navigate to dashboard placeholders

### Using Real Backend

Once Laravel is set up:

1. Start Laravel server: `php artisan serve`
2. Open Flutter app
3. Login with credentials from seeded data:
   - Email: `admin@example.com`
   - Password: `password`

---

## 📂 Project Files Overview

| File | Purpose |
|------|---------|
| `README.md` | Main project documentation |
| `LARAVEL_API_DOCUMENTATION.md` | Complete API reference (42+ endpoints) |
| `LARAVEL_SETUP.md` | Step-by-step Laravel setup |
| `PROJECT_SUMMARY.md` | Comprehensive project summary |
| `QUICK_START.md` | This file - Quick start guide |

---

## 🎯 What You Can Do Now

### ✅ Already Working
- Login Screen UI
- Authentication state management
- API service layer
- Navigation between roles
- Theme and styling

### 🔨 Build Next (In Order)
1. **Staff Dashboard** - Start here
2. **Leave Application Screen**
3. **Time Tracker Screen**
4. **My Leaves List**
5. **Admin Dashboard**
6. **HR Dashboard**

---

## 📱 User Roles & Access

### Admin
- Email: `admin@example.com`
- Access: Everything (user management, policies, all leaves, all logs)

### HR
- Email: `hr@example.com`
- Access: Team management, leave approvals, reports

### Staff
- Email: `staff@example.com`
- Access: Personal leave, time tracking, profile

---

## 🛠️ Development Tools

### Recommended VS Code Extensions
- Flutter
- Dart
- Error Lens
- GitLens

### Recommended Commands

```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Dependencies Error
**Solution**: Run `flutter pub get` again

### Issue 2: Cannot Connect to API
**Solution**: 
- Check API base URL in `app_constants.dart`
- Ensure Laravel server is running
- Check firewall settings

### Issue 3: Build Errors
**Solution**: 
- Run `flutter clean`
- Then `flutter pub get`
- Then `flutter run`

---

## 📚 Documentation Reference

### For Flutter Development
- [Flutter Docs](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [GoRouter Package](https://pub.dev/packages/go_router)
- [Dio Package](https://pub.dev/packages/dio)

### For Laravel Backend
- [Laravel Docs](https://laravel.com/docs)
- [Laravel Sanctum](https://laravel.com/docs/sanctum)

---

## 🎨 Design System

### Colors
- Primary: `#6366F1` (Indigo)
- Secondary: `#10B981` (Green)
- Error: `#EF4444` (Red)
- Warning: `#F59E0B` (Amber)

All colors defined in: `lib/core/constants/colors.dart`

### Typography
- Font Family: Inter (system default)
- Material 3 typography scale

---

## 📊 Feature Status

| Feature | Status | Location |
|---------|--------|----------|
| Authentication | ✅ Complete | `lib/providers/auth_provider.dart` |
| Leave Management | ✅ Service Ready | `lib/data/services/leave_service.dart` |
| Time Tracking | ✅ Service Ready | `lib/data/services/time_log_service.dart` |
| Notifications | ✅ Service Ready | `lib/data/services/notification_service.dart` |
| UI Screens | ⏳ In Progress | `lib/presentation/screens/` |

---

## 🚀 Next Steps

1. **Run the app** to see the current state
2. **Review** the code structure
3. **Read** LARAVEL_API_DOCUMENTATION.md for API details
4. **Start building** staff dashboard screen
5. **Test** with Laravel backend

---

## 💡 Tips

1. **Start Small**: Build one screen at a time
2. **Use Providers**: Already set up for state management
3. **Check Services**: All API calls are ready to use
4. **Follow Structure**: Keep same folder organization
5. **Test Often**: Run the app frequently

---

## 📞 Need Help?

- Check `PROJECT_SUMMARY.md` for detailed overview
- Review `LARAVEL_API_DOCUMENTATION.md` for API details
- See `LARAVEL_SETUP.md` for backend setup
- Read `README.md` for project documentation

---

**Happy Coding! 🎉**

Start building amazing features on this solid foundation!
