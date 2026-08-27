import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/audit_log.dart';
import 'audit_repository.dart';

class HttpAuditRepository implements AuditRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<AuditLog>> getAuditLogs({
    String? module,
    String? action,
    String? actorRole,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (module != null && module != 'All') queryParams['module'] = module;
      if (action != null && action != 'All') queryParams['action'] = action;
      if (actorRole != null && actorRole != 'All') queryParams['role'] = actorRole;
      if (query != null && query.isNotEmpty) queryParams['query'] = query;

      final response = await _apiClient.get(ApiEndpoints.auditLogs, queryParams: queryParams.isNotEmpty ? queryParams : null);
      if (response is List) {
        return response.map((json) => AuditLog.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpAuditRepo] Error fetching audit logs: $e');
      return [];
    }
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
    try {
      final body = {
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
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _apiClient.post(ApiEndpoints.auditLogs, body: body);
    } catch (e) {
      debugPrint('[HttpAuditRepo] Error logging audit action: $e');
    }
  }
}
