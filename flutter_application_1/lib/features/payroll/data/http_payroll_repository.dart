import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/payroll_record.dart';
import 'payroll_repository.dart';

class HttpPayrollRepository implements PayrollRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<PayrollRecord>> getPayrollSummaryForMonth(int month, int year) async {
    try {
      final monthStr = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
      final response = await _apiClient.get(
        ApiEndpoints.payroll,
        queryParams: {'month': monthStr},
      );
      if (response is List) {
        return response.map((json) => PayrollRecord.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpPayrollRepo] Error fetching payroll records: $e');
      return [];
    }
  }

  @override
  Future<void> updatePayrollStatus(String recordId, PayrollStatus status) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.updatePayrollStatus(recordId),
        queryParams: {'status': status.name},
      );
    } catch (e) {
      debugPrint('[HttpPayrollRepo] Error updating payroll status: $e');
      rethrow;
    }
  }
}
