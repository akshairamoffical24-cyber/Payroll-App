import 'dart:async';
import '../../../shared/models/employee.dart';
import '../../../shared/models/import_job.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getAllEmployees();
  Future<Employee?> getEmployeeById(String id);
  Future<Employee?> getEmployeeByCode(String code);
  Future<Employee> addEmployee(Employee employee);
  Future<Employee> updateEmployee(Employee employee);
  Future<List<Employee>> importEmployees(List<Employee> employees, ImportMode mode);
  Future<void> toggleEmployeeStatus(String id);
  Future<void> deleteEmployee(String id);
}

class MockEmployeeRepository implements EmployeeRepository {
  // In-memory data store for custom created / Excel-imported employees
  static final List<Employee> _employees = [];

  static List<Employee> get seedEmployees => _employees;

  @override
  Future<List<Employee>> getAllEmployees() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<Employee>.from(_employees);
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _employees.where((e) => e.id.toLowerCase() == id.toLowerCase()).firstOrNull;
  }

  @override
  Future<Employee?> getEmployeeByCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _employees.where((e) => e.code.toLowerCase() == code.toLowerCase()).firstOrNull;
  }

  @override
  Future<Employee> addEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _employees.indexWhere((e) => e.id.toLowerCase() == employee.id.toLowerCase());
    if (index != -1) {
      _employees[index] = employee;
    } else {
      _employees.add(employee);
    }
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _employees.indexWhere((e) => e.id.toLowerCase() == employee.id.toLowerCase());
    if (index != -1) {
      _employees[index] = employee;
    } else {
      _employees.add(employee);
    }
    return employee;
  }

  @override
  Future<List<Employee>> importEmployees(List<Employee> imported, ImportMode mode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final emp in imported) {
      final index = _employees.indexWhere(
        (e) => e.id.toLowerCase() == emp.id.toLowerCase() || e.code.toLowerCase() == emp.code.toLowerCase(),
      );

      if (index != -1) {
        if (mode == ImportMode.updateExisting || mode == ImportMode.addAndUpdate) {
          _employees[index] = emp;
        }
      } else {
        if (mode == ImportMode.addNew || mode == ImportMode.addAndUpdate) {
          _employees.add(emp);
        }
      }
    }
    return List<Employee>.from(_employees);
  }

  @override
  Future<void> toggleEmployeeStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _employees.indexWhere((e) => e.id.toLowerCase() == id.toLowerCase());
    if (index != -1) {
      final cur = _employees[index];
      _employees[index] = cur.copyWith(
        status: cur.status == EmployeeStatus.active ? EmployeeStatus.inactive : EmployeeStatus.active,
      );
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _employees.removeWhere((e) => e.id.toLowerCase() == id.toLowerCase());
  }
}
