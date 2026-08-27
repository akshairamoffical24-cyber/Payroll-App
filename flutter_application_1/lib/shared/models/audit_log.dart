class AuditLog {
  final String id;
  final DateTime timestamp;
  final String action; // CREATE, UPDATE, DELETE, ACTIVATE, DEACTIVATE, IMPORT, EXPORT, LOGIN, LOGOUT, MAP, UNMAP, PUNCH, ATTENDANCE_CORRECTION, SETTINGS_CHANGED
  final String? userId;
  final String actorName;
  final String actorRole;
  final String module; // Employees, Sites, Mappings, Attendance, Reports, Auth, Settings
  final String? entityType;
  final String? entityId;
  final String? description;
  final String details;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? targetEntity;
  final String? ipAddress;
  final String? deviceInfo;
  final bool isSuccess;

  const AuditLog({
    required this.id,
    required this.timestamp,
    required this.action,
    this.userId,
    required this.actorName,
    required this.actorRole,
    this.module = 'General',
    this.entityType,
    this.entityId,
    this.description,
    required this.details,
    this.oldValues,
    this.newValues,
    this.targetEntity,
    this.ipAddress,
    this.deviceInfo,
    this.isSuccess = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'userId': userId,
      'actorName': actorName,
      'actorRole': actorRole,
      'module': module,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'details': details,
      'oldValues': oldValues,
      'newValues': newValues,
      'targetEntity': targetEntity,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'isSuccess': isSuccess,
    };
  }

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      userId: json['userId'] as String?,
      actorName: json['actorName'] as String? ?? 'System',
      actorRole: json['actorRole'] as String? ?? 'Admin',
      module: json['module'] as String? ?? 'General',
      entityType: json['entityType'] as String?,
      entityId: json['entityId'] as String?,
      description: json['description'] as String?,
      details: json['details'] as String? ?? '',
      oldValues: json['oldValues'] as Map<String, dynamic>?,
      newValues: json['newValues'] as Map<String, dynamic>?,
      targetEntity: json['targetEntity'] as String?,
      ipAddress: json['ipAddress'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
      isSuccess: json['isSuccess'] as bool? ?? true,
    );
  }
}
