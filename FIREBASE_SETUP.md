# Firebase Setup Guide - COMPLETED ✅

## ✅ What's Already Done

1. **Firebase dependencies added** to pubspec.yaml
2. **Firebase packages installed** (flutter pub get completed)
3. **FlutterFire CLI installed**
4. **firebase_options.dart template created**
5. **main.dart updated** with Firebase initialization

## 🔥 Quick Setup - Choose One Method

### Method 1: Automatic Configuration (Recommended)

#### Step 1: Login to Firebase
```powershell
firebase login
```

#### Step 2: Run FlutterFire Configure
```powershell
$env:PATH = "C:\Users\SMASMI\AppData\Local\Pub\Cache\bin;$env:PATH"
flutterfire configure
```

This will:
- Show your Firebase projects
- Let you create a new project or select existing one  
- Automatically update `lib/firebase_options.dart` with real credentials

---

### Method 2: Manual Configuration (If automatic fails)

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `leave-management`
4. Disable Google Analytics (or enable if you want)
5. Click "Create project"

#### Step 2: Add Apps to Your Firebase Project

##### For Web:
1. In Firebase Console, click "Web" icon (</>) 
2. Register app with nickname: "Leave Management Web"
3. Copy the configuration values
4. Open `lib/firebase_options.dart`
5. Replace `web` section with your values

##### For Android:
1. In Firebase Console, click Android icon
2. Android package name: `com.example.leave_management`
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. Copy configuration values to `lib/firebase_options.dart` android section

##### For Windows:
1. Use the same Web configuration
2. Update `windows` section in `lib/firebase_options.dart`

#### Step 3: Update firebase_options.dart
Replace the placeholder values in `lib/firebase_options.dart`:
```dart
projectId: 'your-project-id'
apiKey: 'your-api-key'
appId: 'your-app-id'
messagingSenderId: 'your-sender-id'
```

---

## 📋 Install Firebase CLI (if not done)
```powershell
npm install -g firebase-tools
```

## 📋 Install FlutterFire CLI (if not done)
```powershell
dart pub global activate flutterfire_cli
```

## 🔧 Add to PATH (for PowerShell)
```powershell
$env:PATH = "C:\Users\SMASMI\AppData\Local\Pub\Cache\bin;$env:PATH"
```

### 7. Enable Firebase Services

#### Firebase Authentication
1. Go to Firebase Console → Authentication
2. Click "Get started"
3. Enable desired sign-in methods:
   - Email/Password (recommended)
   - Google Sign-In (optional)
   - Phone (optional)

#### Cloud Firestore
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select a location (choose closest to your users)

#### Firebase Cloud Messaging (for notifications)
1. Go to Firebase Console → Cloud Messaging
2. The setup is automatic for Android and iOS

#### Firebase Storage (for file uploads)
1. Go to Firebase Console → Storage
2. Click "Get started"
3. Start in test mode for development

#### Firebase Analytics
- Already enabled by default when you create a Firebase project

### 8. Configure Android (if targeting Android)

#### Update `android/build.gradle.kts`:
```kotlin
buildscript {
    dependencies {
        // Add this line
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

#### Update `android/app/build.gradle.kts`:
```kotlin
plugins {
    // ... existing plugins
    id("com.google.gms.google-services")
}
```

### 9. Test Firebase Connection
Run your app to verify Firebase is connected:
```powershell
flutter run
```

Check for any Firebase initialization errors in the console.

## Firebase Services Added

### 1. **firebase_core** (^3.8.1)
   - Core Firebase SDK

### 2. **firebase_auth** (^5.3.3)
   - User authentication
   - Email/password, Google, Phone authentication

### 3. **cloud_firestore** (^5.5.2)
   - NoSQL cloud database
   - Real-time data synchronization

### 4. **firebase_messaging** (^15.1.6)
   - Push notifications
   - Background and foreground messaging

### 5. **firebase_storage** (^12.3.8)
   - Cloud file storage
   - Image uploads, document storage

### 6. **firebase_analytics** (^11.3.8)
   - App analytics
   - User behavior tracking

## Security Rules (Production)

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Next Steps

1. Run `flutter pub get` to install all Firebase packages
2. Run `flutterfire configure` to generate Firebase configuration
3. Test your app with `flutter run`
4. Start integrating Firebase services into your app

## Common Issues

### Issue: firebase_options.dart not found
**Solution:** Run `flutterfire configure` again

### Issue: Google Services plugin error
**Solution:** Make sure you've added the Google Services plugin to your Android build files

### Issue: Firebase initialization fails
**Solution:** Check that `firebase_options.dart` exists and contains valid configuration

## Useful Commands

```powershell
# Reconfigure Firebase
flutterfire configure

# Check Firebase CLI version
firebase --version

# Update Firebase CLI
npm install -g firebase-tools

# Update FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Documentation Links

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
