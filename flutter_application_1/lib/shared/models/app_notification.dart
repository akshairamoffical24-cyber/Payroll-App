enum NotificationType {
  info,
  warning,
  error,
  success,
}

enum NotificationCategory {
  missingPunch,
  unmappedLocation,
  newSiteMapping,
  attendanceSuccess,
  systemAlert,
  regularization,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationCategory category;
  final bool isRead;
  final String? targetEmployeeId;
  final String? targetSiteId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.category,
    this.isRead = false,
    this.targetEmployeeId,
    this.targetSiteId,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    NotificationCategory? category,
    bool? isRead,
    String? targetEmployeeId,
    String? targetSiteId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      targetEmployeeId: targetEmployeeId ?? this.targetEmployeeId,
      targetSiteId: targetSiteId ?? this.targetSiteId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'category': category.name,
      'isRead': isRead,
      'targetEmployeeId': targetEmployeeId,
      'targetSiteId': targetSiteId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => NotificationCategory.systemAlert,
      ),
      isRead: json['isRead'] as bool? ?? false,
      targetEmployeeId: json['targetEmployeeId'] as String?,
      targetSiteId: json['targetSiteId'] as String?,
    );
  }
}
