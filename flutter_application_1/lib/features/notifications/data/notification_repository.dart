import 'dart:async';
import '../../../shared/models/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> clearAll();
  Future<void> addNotification(AppNotification notification);
}

class MockNotificationRepository implements NotificationRepository {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'NOTIF-000',
      title: 'Unmapped Location Attempt Blocked',
      message: 'Punch attempt from unmapped location (12.9012, 80.2281) by EMP-101 was safely rejected.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      type: NotificationType.error,
      category: NotificationCategory.unmappedLocation,
      isRead: false,
      targetEmployeeId: 'EMP-101',
    ),
    AppNotification(
      id: 'NOTIF-001',
      title: 'Missing OUT Punch Alert',
      message: 'Employee Vikram Seth (EMP005) has a missing OUT punch for yesterday.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.warning,
      category: NotificationCategory.missingPunch,
      isRead: false,
      targetEmployeeId: 'EMP-005',
    ),
    AppNotification(
      id: 'NOTIF-002',
      title: 'Unmapped Location Attempt',
      message: 'Field staff attempted punch from an unmapped GPS coordinate (13.0827, 80.2707). Rejected.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.error,
      category: NotificationCategory.unmappedLocation,
      isRead: false,
    ),
    AppNotification(
      id: 'NOTIF-003',
      title: 'New Site Mapping Activated',
      message: 'Rajesh Kumar (EMP001) mapped to Cochin SmartCity Project by Sarah Jenkins (HR).',
      timestamp: DateTime.now().subtract(const Duration(hours: 18)),
      type: NotificationType.info,
      category: NotificationCategory.newSiteMapping,
      isRead: true,
      targetEmployeeId: 'EMP-001',
    ),
    AppNotification(
      id: 'NOTIF-004',
      title: 'Biometric Devices Synchronized',
      message: 'HQ Biometric terminal processed 38 office punches successfully.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.info,
      category: NotificationCategory.systemAlert,
      isRead: true,
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_notifications);
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> clearAll() async {
    _notifications.clear();
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
  }
}
