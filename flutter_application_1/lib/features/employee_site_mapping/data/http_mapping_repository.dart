import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/employee_site_mapping.dart';
import 'mapping_repository.dart';

class HttpMappingRepository implements MappingRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<EmployeeSiteMapping>> getAllMappings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.mappings);
      if (response is List) {
        return response.map((json) => EmployeeSiteMapping.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpMappingRepo] Error fetching mappings: $e');
      rethrow;
    }
  }

  @override
  Future<List<EmployeeSiteMapping>> getMappingsForEmployee(String employeeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.mappingsByEmployee(employeeId));
      if (response is List) {
        return response.map((json) => EmployeeSiteMapping.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpMappingRepo] Error fetching employee mappings: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getActiveSiteIdsForEmployee(String employeeId, [DateTime? date]) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      final response = await _apiClient.get(
        ApiEndpoints.activeSiteIdsForEmployee(employeeId),
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response is List) {
        return response.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpMappingRepo] Error fetching active site ids: $e');
      return [];
    }
  }

  @override
  Future<void> saveEmployeeMappings({
    required String employeeId,
    required List<String> siteIds,
    required DateTime fromDate,
    DateTime? toDate,
    required String actorName,
  }) async {
    try {
      final body = {
        'employeeId': employeeId,
        'siteIds': siteIds,
        'fromDate': '${fromDate.year.toString().padLeft(4, '0')}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}',
        'toDate': toDate != null ? '${toDate.year.toString().padLeft(4, '0')}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}' : null,
        'actorName': actorName,
      };
      await _apiClient.post(ApiEndpoints.mappings, body: body);
    } catch (e) {
      debugPrint('[HttpMappingRepo] Error saving employee mappings: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleMappingStatus(String mappingId) async {
    try {
      await _apiClient.patch(ApiEndpoints.toggleMappingStatus(mappingId));
    } catch (e) {
      debugPrint('[HttpMappingRepo] Error toggling mapping status: $e');
      rethrow;
    }
  }
}
