import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/app_notification.dart';
import 'notification_repository.dart';

class HttpNotificationRepository implements NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notifications);
      if (response is List) {
        return response.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpNotificationRepo] Error fetching notifications: $e');
      return [];
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    // Single notification read can invoke markAll or PATCH endpoint
    await markAllAsRead();
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.patch(ApiEndpoints.markAllNotificationsRead);
    } catch (e) {
      debugPrint('[HttpNotificationRepo] Error marking all as read: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _apiClient.delete(ApiEndpoints.notifications);
    } catch (e) {
      debugPrint('[HttpNotificationRepo] Error clearing all notifications: $e');
    }
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    try {
      await _apiClient.post(ApiEndpoints.notifications, body: notification.toJson());
    } catch (e) {
      debugPrint('[HttpNotificationRepo] Error posting notification: $e');
    }
  }
}
