import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/attendance_punch.dart';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/site.dart';
import '../../biometric/data/biometric_adapter.dart';
import 'attendance_repository.dart';

class HttpAttendanceRepository implements AttendanceRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<AttendancePunch>> getAllPunches() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.allPunches);
      if (response is List) {
        return response.map((json) => AttendancePunch.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpAttendanceRepo] Error fetching punches: $e');
      return [];
    }
  }

  @override
  Future<List<DailyAttendance>> getDailyAttendanceList({
    DateTime? date,
    String? employeeId,
    String? department,
    AttendanceStatus? status,
    AttendanceSourceType? sourceType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      if (employeeId != null && employeeId.isNotEmpty) {
        queryParams['employeeId'] = employeeId;
      }

      final response = await _apiClient.get(ApiEndpoints.dailyAttendance, queryParams: queryParams.isNotEmpty ? queryParams : null);
      if (response is List) {
        var list = response.map((json) => DailyAttendance.fromJson(json as Map<String, dynamic>)).toList();
        if (status != null) {
          list = list.where((d) => d.status == status).toList();
        }
        if (sourceType != null) {
          list = list.where((d) => d.sourceType == sourceType).toList();
        }
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('[HttpAttendanceRepo] Error fetching daily attendance: $e');
      return [];
    }
  }

  @override
  Future<DailyAttendance?> getDailyAttendanceForEmployee(String employeeId, DateTime date) async {
    try {
      final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiClient.get(
        ApiEndpoints.dailyAttendanceForEmployee(employeeId),
        queryParams: {'date': dateStr},
      );
      if (response is Map<String, dynamic>) {
        return DailyAttendance.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('[HttpAttendanceRepo] Error fetching daily record for employee ($employeeId): $e');
      return null;
    }
  }

  @override
  Future<AttendancePunch> recordMobilePunch({
    required String employeeId,
    required PunchType type,
    required Site site,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double distanceMeters,
    bool isOfflineQueued = false,
  }) async {
    try {
      final body = {
        'employeeId': employeeId,
        'type': type.name,
        'siteId': site.id,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'distanceMeters': distanceMeters,
        'timestamp': DateTime.now().toIso8601String(),
        'isOfflineQueued': isOfflineQueued,
      };
      final response = await _apiClient.post(ApiEndpoints.mobilePunch, body: body);
      if (response is Map<String, dynamic>) {
        return AttendancePunch.fromJson(response);
      }
      throw ApiException('Unexpected response when recording punch.');
    } catch (e) {
      debugPrint('[HttpAttendanceRepo] Error recording mobile punch: $e');
      rethrow;
    }
  }

  @override
  Future<void> ingestBiometricPunch(RawBiometricPunch rawPunch, Employee employee) async {
    try {
      final body = {
        'employeeCode': employee.code,
        'timestamp': rawPunch.timestamp.toIso8601String(),
        'deviceSerial': rawPunch.deviceSerial,
        'terminalLocation': rawPunch.terminalLocation,
      };
      await _apiClient.post(ApiEndpoints.ingestBiometric, body: body);
    } catch (e) {
      debugPrint('[HttpAttendanceRepo] Error ingesting biometric punch: $e');
      rethrow;
    }
  }

  @override
  Future<int> syncOfflinePunches() async {
    return 0;
  }

  @override
  Future<DailyAttendance> correctAttendanceRecord({
    required String dailyAttendanceId,
    required String employeeId,
    required DateTime date,
    DateTime? correctedInTime,
    DateTime? correctedOutTime,
    AttendanceStatus? correctedStatus,
    required String reason,
    required String reviewerName,
    required String reviewerRole,
  }) async {
    try {
      final body = {
        'dailyAttendanceId': dailyAttendanceId,
        'employeeId': employeeId,
        'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'correctedInTime': correctedInTime?.toIso8601String(),
        'correctedOutTime': correctedOutTime?.toIso8601String(),
        'correctedStatus': correctedStatus?.name,
        'reason': reason,
        'reviewerName': reviewerName,
        'reviewerRole': reviewerRole,
      };
      final response = await _apiClient.post('${ApiEndpoints.dailyAttendance}/correct', body: body);
      if (response is Map<String, dynamic>) {
        return DailyAttendance.fromJson(response);
      }
      throw ApiException('Unexpected response correcting attendance.');
    } catch (e) {
      debugPrint('[HttpAttendanceRepo] Error submitting attendance correction: $e');
      rethrow;
    }
  }
}
