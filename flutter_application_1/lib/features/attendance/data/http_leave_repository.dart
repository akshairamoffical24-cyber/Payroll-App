import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/leave_request.dart';

abstract class LeaveRepository {
  Future<List<LeaveRequest>> getAllLeaves();
  Future<List<LeaveRequest>> getLeavesForEmployee(String employeeId);
  Future<LeaveRequest> submitLeaveRequest({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  });
  Future<LeaveRequest> approveLeave(String id, {String? reviewer, String? remarks});
  Future<LeaveRequest> rejectLeave(String id, {String? reviewer, String? reason});
}

class HttpLeaveRepository implements LeaveRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<LeaveRequest>> getAllLeaves() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.leaves);
      if (response is List) {
        return response
            .map((json) => LeaveRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpLeaveRepo] Error fetching all leaves: $e');
      return [];
    }
  }

  @override
  Future<List<LeaveRequest>> getLeavesForEmployee(String employeeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.leavesForEmployee(employeeId));
      if (response is List) {
        return response
            .map((json) => LeaveRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpLeaveRepo] Error fetching leaves for employee ($employeeId): $e');
      return [];
    }
  }

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final body = {
        'employeeId': employeeId,
        'leaveType': leaveType,
        'startDate':
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'endDate':
            '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'reason': reason ?? 'Personal requirement',
      };
      final response = await _apiClient.post(ApiEndpoints.leaves, body: body);
      if (response is Map<String, dynamic>) {
        return LeaveRequest.fromJson(response);
      }
      throw ApiException('Unexpected response when submitting leave request.');
    } catch (e) {
      debugPrint('[HttpLeaveRepo] Error submitting leave: $e');
      rethrow;
    }
  }

  @override
  Future<LeaveRequest> approveLeave(String id, {String? reviewer, String? remarks}) async {
    try {
      final body = {
        'reviewer': reviewer ?? 'HR Manager',
        'remarks': remarks ?? 'Approved',
      };
      final response = await _apiClient.put('${ApiEndpoints.leaves}/$id/approve', body: body);
      if (response is Map<String, dynamic>) {
        return LeaveRequest.fromJson(response);
      }
      throw ApiException('Unexpected response approving leave.');
    } catch (e) {
      debugPrint('[HttpLeaveRepo] Error approving leave: $e');
      rethrow;
    }
  }

  @override
  Future<LeaveRequest> rejectLeave(String id, {String? reviewer, String? reason}) async {
    try {
      final body = {
        'reviewer': reviewer ?? 'HR Manager',
        'reason': reason ?? 'Rejected',
      };
      final response = await _apiClient.put('${ApiEndpoints.leaves}/$id/reject', body: body);
      if (response is Map<String, dynamic>) {
        return LeaveRequest.fromJson(response);
      }
      throw ApiException('Unexpected response rejecting leave.');
    } catch (e) {
      debugPrint('[HttpLeaveRepo] Error rejecting leave: $e');
      rethrow;
    }
  }
}
