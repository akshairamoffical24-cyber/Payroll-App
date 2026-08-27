import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/network/api_endpoints.dart';
import 'package:flutter_application_1/features/employees/data/http_employee_repository.dart';
import 'package:flutter_application_1/features/sites/data/http_site_repository.dart';
import 'package:flutter_application_1/features/attendance/data/http_attendance_repository.dart';
import 'package:flutter_application_1/features/employee_site_mapping/data/http_mapping_repository.dart';
import 'package:flutter_application_1/features/payroll/data/http_payroll_repository.dart';
import 'package:flutter_application_1/features/notifications/data/http_notification_repository.dart';
import 'package:flutter_application_1/features/audit_logs/data/http_audit_repository.dart';
import 'package:flutter_application_1/features/authentication/data/http_auth_repository.dart';
import 'package:flutter_application_1/features/authentication/data/google_auth_service.dart';
import 'package:flutter_application_1/shared/models/employee.dart';
import 'package:flutter_application_1/shared/models/attendance_punch.dart';
import 'package:flutter_application_1/shared/models/import_job.dart';
import 'package:flutter_application_1/shared/models/user.dart';

void main() {
  group('Backend Live API Integration Tests', () {
    late HttpEmployeeRepository employeeRepo;
    late HttpSiteRepository siteRepo;
    late HttpAttendanceRepository attendanceRepo;
    late HttpMappingRepository mappingRepo;
    late HttpPayrollRepository payrollRepo;
    late HttpNotificationRepository notifRepo;
    late HttpAuditRepository auditRepo;
    late HttpAuthRepository authRepo;

    setUp(() {
      employeeRepo = HttpEmployeeRepository();
      siteRepo = HttpSiteRepository();
      attendanceRepo = HttpAttendanceRepository();
      mappingRepo = HttpMappingRepository();
      payrollRepo = HttpPayrollRepository();
      notifRepo = HttpNotificationRepository();
      auditRepo = HttpAuditRepository();
      authRepo = HttpAuthRepository();
    });

    test('1. Verify ApiEndpoints configuration', () {
      expect(ApiEndpoints.employees, contains('/api/employees'));
      expect(ApiEndpoints.sites, contains('/api/sites'));
      expect(ApiEndpoints.mobilePunch, contains('/api/attendance/punches/mobile'));
      expect(ApiEndpoints.mappings, contains('/api/mappings'));
      expect(ApiEndpoints.payroll, contains('/api/payroll'));
      expect(ApiEndpoints.googleLogin, contains('/api/auth/google'));
    });

    test('2. Verify HTTP Employee Repository adds and fetches employee data from backend', () async {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final newEmp = Employee(
        id: 'EMP-INTEG-$uniqueSuffix',
        code: 'INT$uniqueSuffix',
        name: 'Integration Test User',
        department: 'Engineering',
        designation: 'Staff Engineer',
        type: EmployeeType.field,
        phone: '9840123456',
        email: 'integ.$uniqueSuffix@workpulse.io',
        joiningDate: DateTime(2026, 8, 25),
        status: EmployeeStatus.active,
      );

      // 1. Manually add an employee
      final added = await employeeRepo.addEmployee(newEmp);
      expect(added.id, equals('EMP-INTEG-$uniqueSuffix'));

      // 2. Bulk import CSV/Excel employees
      final bulkEmp1 = Employee(
        id: 'EMP-BULK-1-$uniqueSuffix',
        code: 'B1-$uniqueSuffix',
        name: 'Bulk Imported User 1',
        department: 'Operations',
        designation: 'Field Technician',
        type: EmployeeType.field,
        phone: '9840111111',
        email: 'bulk1.$uniqueSuffix@workpulse.io',
        joiningDate: DateTime(2026, 8, 25),
        status: EmployeeStatus.active,
      );
      final bulkEmp2 = Employee(
        id: 'EMP-BULK-2-$uniqueSuffix',
        code: 'B2-$uniqueSuffix',
        name: 'Bulk Imported User 2',
        department: 'Human Resources',
        designation: 'HR Executive',
        type: EmployeeType.office,
        phone: '9840222222',
        email: 'bulk2.$uniqueSuffix@workpulse.io',
        joiningDate: DateTime(2026, 8, 25),
        status: EmployeeStatus.active,
      );

      final importedList = await employeeRepo.importEmployees([bulkEmp1, bulkEmp2], ImportMode.addNew);
      expect(importedList.length, equals(2));

      // 3. Fetch all employees and verify BOTH manual and imported employees are listed
      final allEmployees = await employeeRepo.getAllEmployees();
      expect(allEmployees, isNotEmpty);
      expect(allEmployees.any((e) => e.id == 'EMP-INTEG-$uniqueSuffix'), isTrue);
      expect(allEmployees.any((e) => e.id == 'EMP-BULK-1-$uniqueSuffix'), isTrue);
      expect(allEmployees.any((e) => e.id == 'EMP-BULK-2-$uniqueSuffix'), isTrue);
    });

    test('3. Verify HTTP Site Repository fetches data from backend', () async {
      final sites = await siteRepo.getAllSites();
      expect(sites, isNotEmpty);
      expect(sites.any((s) => s.name.contains('CTS Chennai')), isTrue);
      expect(sites.any((s) => s.name.contains('WTC Chennai')), isTrue);
    });

    test('4. Verify HTTP Mapping Repository creates and gets active site mappings', () async {
      await mappingRepo.saveEmployeeMappings(
        employeeId: 'EMP-TEST-MAP',
        siteIds: ['SITE-001'],
        fromDate: DateTime(2026, 1, 1),
        actorName: 'Admin',
      );

      final activeSiteIds = await mappingRepo.getActiveSiteIdsForEmployee('EMP-TEST-MAP');
      expect(activeSiteIds, isNotEmpty);
      expect(activeSiteIds.contains('SITE-001'), isTrue);
    });

    test('5. Verify HTTP Attendance Repository records mobile punch', () async {
      final sites = await siteRepo.getAllSites();
      final ctsSite = sites.firstWhere((s) => s.id == 'SITE-001');

      final punch = await attendanceRepo.recordMobilePunch(
        employeeId: 'EMP-TEST-PUNCH',
        type: PunchType.inPunch,
        site: ctsSite,
        latitude: 12.9010,
        longitude: 80.2279,
        accuracy: 5.0,
        distanceMeters: 25.0,
      );

      expect(punch, isNotNull);
      expect(punch.employeeId, equals('EMP-TEST-PUNCH'));
      expect(punch.isVerified, isTrue);
    });

    test('6. Verify HTTP Payroll Repository computes summary', () async {
      final payroll = await payrollRepo.getPayrollSummaryForMonth(8, 2026);
      expect(payroll, isNotNull);
    });

    test('7. Verify HTTP Notification & Audit Repositories query records', () async {
      final notifs = await notifRepo.getNotifications();
      expect(notifs, isNotNull);

      final auditLogs = await auditRepo.getAuditLogs();
      expect(auditLogs, isNotNull);
    });

    test('8. Verify Google Sign-In with Authorized Admin Account', () async {
      final user = await authRepo.signInWithGoogle(
        payload: GoogleAuthPayload(
          email: 'admin@workpulse.com',
          name: 'Alexander Wright',
          idToken: 'TEST_GOOGLE_ID_TOKEN_ADMIN',
          googleSubjectId: 'GGL-SUB-001',
        ),
      );

      expect(user, isNotNull);
      expect(user.role, equals(UserRole.admin));
      expect(user.email, equals('admin@workpulse.com'));
      expect(user.token, isNotEmpty);
    });

    test('9. Verify Google Sign-In with Authorized HR Account', () async {
      final user = await authRepo.signInWithGoogle(
        payload: GoogleAuthPayload(
          email: 'hr@workpulse.com',
          name: 'Sarah Jenkins',
          idToken: 'TEST_GOOGLE_ID_TOKEN_HR',
          googleSubjectId: 'GGL-SUB-002',
        ),
      );

      expect(user, isNotNull);
      expect(user.role, equals(UserRole.hr));
      expect(user.email, equals('hr@workpulse.com'));
    });

    test('10. Verify Google Sign-In Rejects Unauthorized Account', () async {
      expect(
        () async => await authRepo.signInWithGoogle(
          payload: GoogleAuthPayload(
            email: 'unregistered.hacker@gmail.com',
            name: 'Stranger',
            idToken: 'TEST_GOOGLE_ID_TOKEN_UNAUTHORIZED',
          ),
        ),
        throwsA(predicate((e) => e.toString().toLowerCase().contains('not authorized'))),
      );
    });
  });
}
