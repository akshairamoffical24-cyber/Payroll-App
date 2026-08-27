import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/import_job.dart';
import 'employee_repository.dart';

class HttpEmployeeRepository implements EmployeeRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.employees);
      if (response is List) {
        return response.map((json) => Employee.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error fetching employees: $e');
      rethrow;
    }
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.employeeById(id));
      if (response is Map<String, dynamic>) {
        return Employee.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error fetching employee by id ($id): $e');
      return null;
    }
  }

  @override
  Future<Employee?> getEmployeeByCode(String code) async {
    try {
      final all = await getAllEmployees();
      return all.where((e) => e.code.toLowerCase() == code.toLowerCase().trim()).firstOrNull;
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error finding employee by code ($code): $e');
      return null;
    }
  }

  @override
  Future<Employee> addEmployee(Employee employee) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.employees, body: employee.toJson());
      if (response is Map<String, dynamic>) {
        return Employee.fromJson(response);
      }
      throw ApiException('Unexpected response format when creating employee.');
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error adding employee: $e');
      rethrow;
    }
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.employeeById(employee.id), body: employee.toJson());
      if (response is Map<String, dynamic>) {
        return Employee.fromJson(response);
      }
      throw ApiException('Unexpected response format when updating employee.');
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error updating employee: $e');
      rethrow;
    }
  }

  @override
  Future<List<Employee>> importEmployees(List<Employee> employees, ImportMode mode) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.importEmployees,
        body: {
          'mode': mode.name,
          'employees': employees.map((e) => e.toJson()).toList(),
        },
      );
      if (response is List) {
        return response.map((json) => Employee.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error importing employees: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleEmployeeStatus(String id) async {
    try {
      await _apiClient.patch(ApiEndpoints.toggleEmployeeStatus(id));
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error toggling status: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.employeeById(id));
    } catch (e) {
      debugPrint('[HttpEmployeeRepo] Error deleting employee: $e');
      rethrow;
    }
  }
}
