import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:leave_management/data/models/notification_model.dart';
import 'package:leave_management/data/services/notification_service.dart';
import 'package:leave_management/data/services/firebase_messaging_service.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;
  final FirebaseMessagingService? _fcmService;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  NotificationProvider(this._notificationService, [this._fcmService]) {
    _initializeFCM();
  }

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnreadNotifications => _unreadCount > 0;
  String? get fcmToken => _fcmToken;

  // Initialize FCM
  void _initializeFCM() {
    if (_fcmService != null) {
      _fcmToken = _fcmService?.fcmToken;
      
      // Send token to backend
      if (_fcmToken != null) {
        _sendTokenToBackend(_fcmToken!);
      }
      
      // Listen to messages
      _messageSubscription = _fcmService?.messageStream.listen((message) {
        // When a new message arrives, refresh notifications
        fetchNotifications();
        fetchUnreadCount();
      });
    }
  }

  // Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _notificationService.saveFCMToken(token);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM token to backend: $e');
      }
    }
  }

  // Delete FCM token from backend
  Future<void> deleteFCMToken() async {
    if (_fcmToken != null) {
      try {
        await _notificationService.deleteFCMToken(_fcmToken!);
        await _fcmService?.deleteToken();
        _fcmToken = null;
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting FCM token: $e');
        }
      }
    }
  }

  // Get FCM Token
  String? getFCMToken() {
    return _fcmService?.fcmToken;
  }

  // Subscribe to FCM topics
  Future<void> subscribeToTopic(String topic) async {
    await _fcmService?.subscribeToTopic(topic);
  }

  // Unsubscribe from FCM topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcmService?.unsubscribeFromTopic(topic);
  }

  // Get All Notifications
  Future<void> fetchNotifications({bool? isRead}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _notifications = await _notificationService.getNotifications(
        isRead: isRead,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Get Unread Count
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Mark as Read
  Future<bool> markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark All as Read
  Future<bool> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Update all local notifications
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete Notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      }

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear All Notifications
  Future<bool> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
