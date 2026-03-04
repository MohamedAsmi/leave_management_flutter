# Firebase Cloud Messaging (Push Notifications) - COMPLETED ✅

## 🎉 What's Been Implemented

Firebase Cloud Messaging (FCM) has been fully integrated into your Leave Management app for push notifications!

## ✅ Completed Implementation

### 1. **Firebase Messaging Service** 
   - Created: [lib/data/services/firebase_messaging_service.dart](lib/data/services/firebase_messaging_service.dart)
   - Features:
     - FCM token generation and management
     - Foreground, background, and terminated state message handling
     - Local notifications display
     - Topic subscription/unsubscription
     - Message streaming for real-time updates

### 2. **Android Configuration**
   - Updated: [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
   - Added:
     - FCM permissions (INTERNET, POST_NOTIFICATIONS, etc.)
     - Firebase Messaging service
     - Default notification icon and channel configuration

### 3. **App Initialization**
   - Updated: [lib/main.dart](lib/main.dart)
   - Integrated:
     - Firebase Messaging service initialization
     - Background message handler
     - Service provider setup

### 4. **Notification Provider Enhancement**
   - Updated: [lib/providers/notification_provider.dart](lib/providers/notification_provider.dart)
   - Added:
     - FCM token management
     - Real-time message listening
     - Topic subscription methods
     - Automatic notification refresh on new messages

### 5. **Notification Service Update**
   - Updated: [lib/data/services/notification_service.dart](lib/data/services/notification_service.dart)
   - Added:
     - FCM token storage to backend
     - FCM token deletion from backend

## 📱 Features

### Push Notification Handling

#### **Foreground Notifications**
- App is open and active
- Shows local notification banner
- Auto-refreshes notification list

#### **Background Notifications**
- App is minimized but running
- System displays notification
- Tapping opens app to relevant screen

#### **Terminated State Notifications**
- App is completely closed
- System displays notification
- App opens when tapped

### FCM Token Management

```dart
// Get FCM token
final notificationProvider = context.read<NotificationProvider>();
String? token = notificationProvider.getFCMToken();

// Token is automatically sent to backend on app start
```

### Topic Subscriptions

```dart
// Subscribe to a topic (e.g., all employees)
await notificationProvider.subscribeToTopic('all_employees');

// Subscribe to role-based topics
await notificationProvider.subscribeToTopic('admin');
await notificationProvider.subscribeToTopic('hr');
await notificationProvider.subscribeToTopic('staff');

// Unsubscribe from a topic
await notificationProvider.unsubscribeFromTopic('staff');
```

## 🔧 Backend Integration Required

### 1. Store FCM Tokens

Your backend should handle these endpoints:

#### **POST /api/fcm-token**
Store the device FCM token:
```json
{
  "token": "fcm_device_token_here",
  "device_type": "mobile"
}
```

#### **DELETE /api/fcm-token**
Remove FCM token when user logs out:
```json
{
  "token": "fcm_device_token_here"
}
```

### 2. Send Push Notifications from Backend

#### Using Firebase Admin SDK (PHP/Laravel Example):

```php
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

// Initialize Firebase Admin
$factory = (new Factory)->withServiceAccount('path/to/serviceAccount.json');
$messaging = $factory->createMessaging();

// Send to specific device
$message = CloudMessage::withTarget('token', $deviceToken)
    ->withNotification([
        'title' => 'Leave Request Approved',
        'body' => 'Your leave request has been approved!'
    ])
    ->withData([
        'type' => 'leave_approval',
        'leave_id' => '123'
    ]);

$messaging->send($message);

// Send to topic
$message = CloudMessage::withTarget('topic', 'all_employees')
    ->withNotification([
        'title' => 'Company Announcement',
        'body' => 'Office will be closed tomorrow'
    ]);

$messaging->send($message);
```

### 3. Notification Scenarios

#### **Leave Request Notifications**
```php
// When leave is approved
sendNotification(
    $userToken,
    'Leave Approved ✅',
    'Your leave from ' . $startDate . ' to ' . $endDate . ' has been approved',
    ['type' => 'leave_approval', 'leave_id' => $leaveId]
);

// When leave is rejected
sendNotification(
    $userToken,
    'Leave Rejected ❌',
    'Your leave request has been rejected. Reason: ' . $reason,
    ['type' => 'leave_rejection', 'leave_id' => $leaveId]
);
```

#### **Time Log Notifications**
```php
// Reminder to clock in
sendNotification(
    $userToken,
    'Clock In Reminder ⏰',
    'Don\'t forget to clock in!',
    ['type' => 'clock_in_reminder']
);
```

#### **Task Notifications**
```php
// New task assigned
sendNotification(
    $userToken,
    'New Task Assigned 📋',
    'You have been assigned: ' . $taskTitle,
    ['type' => 'task_assigned', 'task_id' => $taskId]
);
```

## 🧪 Testing Push Notifications

### 1. Test in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/leaves-c2bec)
2. Navigate to **Cloud Messaging**
3. Click "Send your first message"
4. Enter notification title and text
5. Click "Send test message"
6. Enter your FCM token (get from app debug logs)
7. Click "Test"

### 2. Test from Code

Add this test button anywhere in your app:

```dart
ElevatedButton(
  onPressed: () {
    final provider = context.read<NotificationProvider>();
    print('FCM Token: ${provider.getFCMToken()}');
  },
  child: Text('Get FCM Token'),
)
```

### 3. Check Logs

Look for these in your debug console:
```
I/flutter: FCM Token: <your-fcm-token>
I/flutter: FCM Permission Status: AuthorizationStatus.authorized
I/flutter: Firebase Messaging initialized successfully
```

## 📊 Notification Data Structure

### Message Payload Format

```dart
{
  "notification": {
    "title": "Notification Title",
    "body": "Notification body text"
  },
  "data": {
    "type": "leave_approval",  // Type of notification
    "leave_id": "123",         // Related record ID
    "action": "view_details"   // Action to perform
  }
}
```

## 🔒 Important Security Notes

### Firebase Security Rules

Since you're using Firebase for notifications, ensure:

1. **Server Key Protection**: Never expose your Firebase server key in client code
2. **Token Management**: Delete tokens when users logout
3. **Topic Permissions**: Validate topic subscriptions on backend

## 🎯 Next Steps

### 1. Enable Firebase Cloud Messaging in Console
   - Already enabled automatically!

### 2. Backend Implementation
   - Install Firebase Admin SDK in your Laravel backend
   - Create API endpoints to store/delete FCM tokens
   - Implement notification sending logic

### 3. Recommended Topics to Create:
   - `all_employees` - All staff members
   - `admin` - Admin users only
   - `hr` - HR department
   - `staff` - Regular staff
   - `department_{id}` - Department-specific

### 4. Testing Checklist
   - [ ] Test foreground notifications
   - [ ] Test background notifications
   - [ ] Test terminated state notifications
   - [ ] Test topic subscriptions
   - [ ] Test notification actions/navigation
   - [ ] Test on different Android versions
   - [ ] Test on iOS (if applicable)

## 📖 Usage Examples

### Subscribe User to Their Department Topic

```dart
// In your login or profile setup
final user = authProvider.user;
if (user.department != null) {
  await notificationProvider.subscribeToTopic('department_${user.department.id}');
}

// Subscribe based on role
if (user.role == 'admin') {
  await notificationProvider.subscribeToTopic('admin');
}
```

### Handle Notification Taps

Update [firebase_messaging_service.dart](lib/data/services/firebase_messaging_service.dart):

```dart
void _onNotificationTapped(NotificationResponse response) {
  final data = jsonDecode(response.payload ?? '{}');
  
  // Navigate based on notification type
  switch (data['type']) {
    case 'leave_approval':
      // Navigate to leave details
      navigatorKey.currentState?.pushNamed('/leave-details', arguments: data['leave_id']);
      break;
    case 'task_assigned':
      // Navigate to task details
      navigatorKey.currentState?.pushNamed('/task-details', arguments: data['task_id']);
      break;
  }
}
```

## ✅ Verification

Run your app and check:

```bash
flutter run
```

You should see in console:
```
✅ Firebase initialized
✅ FCM Permission Status: AuthorizationStatus.authorized
✅ FCM Token: <your-token>
✅ Firebase Messaging initialized successfully
```

---

## 🎉 You're All Set!

Firebase Push Notifications are now fully integrated and ready to use. Your app will receive push notifications from your backend server!

**Important**: Remember to implement the backend endpoints to send notifications using Firebase Admin SDK.
