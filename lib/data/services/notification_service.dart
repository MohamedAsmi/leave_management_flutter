import 'package:leave_management/data/models/notification_model.dart';
import 'package:leave_management/data/services/api_client.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  // Get All Notifications
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool? isRead,
  }) async {
    final response = await _apiClient.get('/notifications', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (isRead != null) 'is_read': isRead,
    });

    final notificationsData = response.data['notifications'] as List;
    return notificationsData
        .map((notification) => NotificationModel.fromJson(notification))
        .toList();
  }

  // Get Unread Notifications Count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    return response.data['count'] ?? 0;
  }

  // Mark Notification as Read
  Future<void> markAsRead(int notificationId) async {
    await _apiClient.post('/notifications/$notificationId/read');
  }

  // Mark All as Read
  Future<void> markAllAsRead() async {
    await _apiClient.post('/notifications/read-all');
  }

  // Delete Notification
  Future<void> deleteNotification(int notificationId) async {
    await _apiClient.delete('/notifications/$notificationId');
  }

  // Clear All Notifications
  Future<void> clearAllNotifications() async {
    await _apiClient.delete('/notifications/clear-all');
  }
}
