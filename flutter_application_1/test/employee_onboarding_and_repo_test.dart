import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/models/employee.dart';
import 'package:flutter_application_1/shared/models/daily_attendance.dart';
import 'package:flutter_application_1/features/employees/data/http_employee_repository.dart';

void main() {
  group('Employee Onboarding & Persistence Tests', () {
    late HttpEmployeeRepository repo;

    setUp(() {
      repo = HttpEmployeeRepository();
    });

    test('1. Verify adding a new onboarded employee stores record in repository', () async {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final newEmp = Employee(
        id: 'EMP-ONBOARD-$uniqueSuffix',
        code: 'E$uniqueSuffix',
        name: 'Vignesh Sundaram',
        department: 'Operations',
        designation: 'Site Manager',
        type: EmployeeType.field,
        phone: '9840123456',
        email: 'vignesh.$uniqueSuffix@workpulse.io',
        officialEmail: 'vignesh.$uniqueSuffix@workpulse.io',
        personalEmail: 'vignesh.personal@gmail.com',
        workLocation: 'Chennai Campus',
        joiningDate: DateTime(2026, 8, 25),
        status: EmployeeStatus.active,
        gender: 'Male',
        dob: DateTime(1993, 5, 12),
        fatherName: 'Sundaram K',
        address: '12, Anna Salai, Chennai, TN',
        bankName: 'ICICI Bank',
        accountNumber: '123456789012',
        ifsc: 'ICIC0001234',
        pan: 'ABCDE1234F',
        uan: '100987654321',
        monthlyCtc: 45000.0,
        annualCtc: 540000.0,
        basicSalary: 22500.0,
        hra: 11250.0,
        specialAllowance: 11250.0,
        incrementCycle: 'Annual',
        incrementPercentage: 12.0,
        attendanceType: AttendanceSourceType.mobile,
        creationSource: EmployeeCreationSource.manual,
      );

      final added = await repo.addEmployee(newEmp);
      expect(added.id, equals('EMP-ONBOARD-$uniqueSuffix'));
      expect(added.name, equals('Vignesh Sundaram'));

      final all = await repo.getAllEmployees();
      final found = all.where((e) => e.id == 'EMP-ONBOARD-$uniqueSuffix').firstOrNull;
      expect(found, isNotNull);
      expect(found!.code, equals('E$uniqueSuffix'));
      expect(found.department, equals('Operations'));
      expect(found.monthlyCtc, equals(45000.0));
      expect(found.incrementPercentage, equals(12.0));
    });
  });
}
