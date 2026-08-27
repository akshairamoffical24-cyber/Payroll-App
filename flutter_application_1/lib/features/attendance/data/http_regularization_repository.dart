import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/regularization_request.dart';

abstract class RegularizationRepository {
  Future<List<RegularizationRequest>> getAllRequests();
  Future<List<RegularizationRequest>> getRequestsForEmployee(String employeeId);
  Future<RegularizationRequest> submitRequest({
    required String employeeId,
    required String requestType,
    required String reasonCategory,
    required DateTime attendanceDate,
    required String requestedInTime,
    required String requestedOutTime,
    required String remarks,
  });
  Future<RegularizationRequest> reviewRequest({
    required String id,
    required String status,
    required String reviewerName,
    required String reviewerRole,
    String? remarks,
  });
}

class HttpRegularizationRepository implements RegularizationRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<RegularizationRequest>> getAllRequests() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.regularization);
      if (response is List) {
        return response.map((json) => RegularizationRequest.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpRegularizationRepo] Error fetching requests: $e');
      return [];
    }
  }

  @override
  Future<List<RegularizationRequest>> getRequestsForEmployee(String employeeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.regularizationForEmployee(employeeId));
      if (response is List) {
        return response.map((json) => RegularizationRequest.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpRegularizationRepo] Error fetching requests for employee ($employeeId): $e');
      return [];
    }
  }

  @override
  Future<RegularizationRequest> submitRequest({
    required String employeeId,
    required String requestType,
    required String reasonCategory,
    required DateTime attendanceDate,
    required String requestedInTime,
    required String requestedOutTime,
    required String remarks,
  }) async {
    try {
      final body = {
        'employeeId': employeeId,
        'requestType': requestType,
        'reasonCategory': reasonCategory,
        'attendanceDate': '${attendanceDate.year.toString().padLeft(4, '0')}-${attendanceDate.month.toString().padLeft(2, '0')}-${attendanceDate.day.toString().padLeft(2, '0')}',
        'requestedInTime': requestedInTime,
        'requestedOutTime': requestedOutTime,
        'remarks': remarks,
      };
      final response = await _apiClient.post(ApiEndpoints.regularization, body: body);
      if (response is Map<String, dynamic>) {
        return RegularizationRequest.fromJson(response);
      }
      throw ApiException('Unexpected response when submitting regularization.');
    } catch (e) {
      debugPrint('[HttpRegularizationRepo] Error submitting regularization: $e');
      rethrow;
    }
  }

  @override
  Future<RegularizationRequest> reviewRequest({
    required String id,
    required String status,
    required String reviewerName,
    required String reviewerRole,
    String? remarks,
  }) async {
    try {
      final body = {
        'status': status,
        'reviewerName': reviewerName,
        'reviewerRole': reviewerRole,
        'remarks': remarks,
      };
      final response = await _apiClient.post(ApiEndpoints.reviewRegularization(id), body: body);
      if (response is Map<String, dynamic>) {
        return RegularizationRequest.fromJson(response);
      }
      throw ApiException('Unexpected response reviewing regularization.');
    } catch (e) {
      debugPrint('[HttpRegularizationRepo] Error reviewing regularization: $e');
      rethrow;
    }
  }
}
