import 'dart:async';
import '../../../shared/models/audit_log.dart';

abstract class AuditRepository {
  Future<List<AuditLog>> getAuditLogs({
    String? module,
    String? action,
    String? actorRole,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<void> logAction({
    required String action,
    String? userId,
    required String actorName,
    required String actorRole,
    String module = 'General',
    String? entityType,
    String? entityId,
    String? description,
    required String details,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? targetEntity,
    String? ipAddress,
    String? deviceInfo,
    bool isSuccess = true,
  });
}

class MockAuditRepository implements AuditRepository {
  final List<AuditLog> _logs = [
    AuditLog(
      id: 'AUD-001',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      action: 'MAP',
      module: 'Mappings',
      entityType: 'EmployeeSiteMapping',
      entityId: 'MAP-001',
      actorName: 'Sarah Jenkins',
      actorRole: 'HR Manager',
      description: 'Assigned work site CTS Chennai Campus to Alex Morgan (EMP001)',
      details: 'Mapped Alex Morgan (EMP-001) to CTS Chennai Campus with Active status.',
      oldValues: {'status': 'Inactive'},
      newValues: {'status': 'Active', 'site': 'CTS Chennai Campus', 'fromDate': '2026-08-01'},
      targetEntity: 'EMP-001',
      isSuccess: true,
    ),
    AuditLog(
      id: 'AUD-002',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      action: 'PUNCH',
      module: 'Attendance',
      entityType: 'AttendancePunch',
      entityId: 'PUNCH-002',
      actorName: 'System Security Engine',
      actorRole: 'Automated Rule Guard',
      description: 'Blocked attendance attempt at unauthorized location (GPS Geofence violation).',
      details: 'Blocked punch attempt outside mapped geofence. No automatic site creation allowed.',
      targetEntity: 'SECURITY_ALERT',
      isSuccess: false,
    ),
    AuditLog(
      id: 'AUD-003',
      timestamp: DateTime.now().subtract(const Duration(hours: 26)),
      action: 'CREATE',
      module: 'Sites',
      entityType: 'Site',
      entityId: 'SITE-001',
      actorName: 'Alexander Wright',
      actorRole: 'Administrator',
      description: 'Created new site location: CTS Chennai Campus',
      details: 'Created site CTS Chennai Campus with 200m geofence radius at coordinates (12.9012, 80.2281)',
      newValues: {'code': 'SITE001', 'name': 'CTS Chennai Campus', 'radius': 200, 'client': 'CTS'},
      targetEntity: 'SITE-001',
      isSuccess: true,
    ),
    AuditLog(
      id: 'AUD-004',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      action: 'UPDATE',
      module: 'Employees',
      entityType: 'Employee',
      entityId: 'EMP-048',
      actorName: 'Sarah Jenkins',
      actorRole: 'HR Manager',
      description: 'Updated employee master details for Praveen Kumar (E048)',
      details: 'Updated department from Accounts to FINANCE & ACCOUNTS',
      oldValues: {'department': 'Accounts'},
      newValues: {'department': 'FINANCE & ACCOUNTS'},
      targetEntity: 'EMP-048',
      isSuccess: true,
    ),
  ];

  @override
  Future<List<AuditLog>> getAuditLogs({
    String? module,
    String? action,
    String? actorRole,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var list = List<AuditLog>.from(_logs);

    if (module != null && module != 'All') {
      list = list.where((l) => l.module.toLowerCase() == module.toLowerCase()).toList();
    }
    if (action != null && action != 'All') {
      list = list.where((l) => l.action.toLowerCase() == action.toLowerCase()).toList();
    }
    if (actorRole != null && actorRole != 'All') {
      list = list.where((l) => l.actorRole.toLowerCase().contains(actorRole.toLowerCase())).toList();
    }
    if (fromDate != null) {
      list = list.where((l) => l.timestamp.isAfter(fromDate.subtract(const Duration(seconds: 1)))).toList();
    }
    if (toDate != null) {
      list = list.where((l) => l.timestamp.isBefore(toDate.add(const Duration(days: 1)))).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((l) =>
          l.id.toLowerCase().contains(q) ||
          l.actorName.toLowerCase().contains(q) ||
          l.details.toLowerCase().contains(q) ||
          (l.description?.toLowerCase().contains(q) ?? false) ||
          (l.targetEntity?.toLowerCase().contains(q) ?? false)).toList();
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<void> logAction({
    required String action,
    String? userId,
    required String actorName,
    required String actorRole,
    String module = 'General',
    String? entityType,
    String? entityId,
    String? description,
    required String details,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? targetEntity,
    String? ipAddress,
    String? deviceInfo,
    bool isSuccess = true,
  }) async {
    _logs.insert(
      0,
      AuditLog(
        id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        action: action,
        userId: userId,
        actorName: actorName,
        actorRole: actorRole,
        module: module,
        entityType: entityType,
        entityId: entityId,
        description: description,
        details: details,
        oldValues: oldValues,
        newValues: newValues,
        targetEntity: targetEntity,
        ipAddress: ipAddress ?? '127.0.0.1',
        deviceInfo: deviceInfo ?? 'Web/Desktop Client',
        isSuccess: isSuccess,
      ),
    );
  }
}
