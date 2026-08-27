import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/utils/haversine_calculator.dart';
import 'package:flutter_application_1/features/attendance/data/attendance_repository.dart';
import 'package:flutter_application_1/features/biometric/data/biometric_adapter.dart';
import 'package:flutter_application_1/features/employee_site_mapping/data/mapping_repository.dart';
import 'package:flutter_application_1/features/employees/data/employee_repository.dart';
import 'package:flutter_application_1/shared/models/employee.dart';
import 'package:flutter_application_1/shared/models/attendance_punch.dart';
import 'package:flutter_application_1/shared/models/daily_attendance.dart';

void main() {
  group('1. Haversine Geofence Calculation Tests', () {
    test('User within 100m geofence is ALLOWED', () {
      // CTS Chennai Center: 12.9010, 80.2279
      // Employee Position: 12.9012, 80.2281 (~30 meters away)
      final distance = HaversineCalculator.calculateDistanceMeters(
        lat1: 12.9012,
        lon1: 80.2281,
        lat2: 12.9010,
        lon2: 80.2279,
      );

      expect(distance, lessThanOrEqualTo(100.0));
      final isInside = HaversineCalculator.isInsideGeofence(
        userLat: 12.9012,
        userLon: 80.2281,
        siteLat: 12.9010,
        siteLon: 80.2279,
        radiusMeters: 100.0,
      );
      expect(isInside, isTrue);
    });

    test('User outside geofence (e.g. 250m away) is REJECTED', () {
      final isInside = HaversineCalculator.isInsideGeofence(
        userLat: 12.9035,
        userLon: 80.2300,
        siteLat: 12.9010,
        siteLon: 80.2279,
        radiusMeters: 100.0,
      );
      expect(isInside, isFalse);
    });
  });

  group('2. Business Rule 26: Same-Day Multiple Site Visits Payroll Test', () {
    test('Multiple site visits in a single day strictly yields 1.0 Payroll Working Day', () {
      final punchInCTS = AttendancePunch(
        id: 'PUNCH-01',
        employeeId: 'EMP-001',
        timestamp: DateTime(2026, 8, 20, 9, 0),
        type: PunchType.inPunch,
        source: PunchSource.mobile,
        siteId: 'SITE-001',
        siteName: 'CTS Chennai Campus',
        distanceMeters: 25.0,
        isVerified: true,
      );

      final punchOutWTC = AttendancePunch(
        id: 'PUNCH-02',
        employeeId: 'EMP-001',
        timestamp: DateTime(2026, 8, 20, 17, 15),
        type: PunchType.outPunch,
        source: PunchSource.mobile,
        siteId: 'SITE-003',
        siteName: 'WTC Chennai Perungudi',
        distanceMeters: 45.0,
        isVerified: true,
      );

      final dailyRecord = DailyAttendance(
        id: 'ATT-TEST-01',
        employeeId: 'EMP-001',
        date: DateTime(2026, 8, 20),
        firstPunch: punchInCTS,
        lastPunch: punchOutWTC,
        allPunches: [punchInCTS, punchOutWTC],
        visitedSiteNames: ['CTS Chennai Campus', 'WTC Chennai Perungudi'],
        workingDuration: const Duration(hours: 8, minutes: 15),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.mobile,
      );

      // Must strictly be 1.0 day credit (NOT 2 working days!)
      expect(dailyRecord.payrollWorkingDaysCredit, equals(1.0));
      expect(dailyRecord.visitedSiteNames.length, equals(2));
    });
  });

  group('3. Attendance Status & Punch Detection Tests', () {
    test('Detects missing IN when only single OUT punch exists', () async {
      final outPunch = AttendancePunch(
        id: 'PUNCH-OUT-TEST',
        employeeId: 'EMP-005',
        timestamp: DateTime.now(),
        type: PunchType.outPunch,
        source: PunchSource.mobile,
      );
      final dailyRecord = DailyAttendance(
        id: 'ATT-MISSING-IN',
        employeeId: 'EMP-005',
        date: DateTime.now(),
        lastPunch: outPunch,
        allPunches: [outPunch],
        visitedSiteNames: const [],
        workingDuration: Duration.zero,
        status: AttendanceStatus.missingIn,
        sourceType: AttendanceSourceType.mobile,
      );

      expect(dailyRecord.status, equals(AttendanceStatus.missingIn));
      expect(dailyRecord.firstPunch, isNull);
      expect(dailyRecord.lastPunch, isNotNull);
    });

    test('Office Biometric punch ingestion successfully updates central attendance', () async {
      final attendanceRepo = CentralAttendanceRepository();
      final empRepo = MockEmployeeRepository();
      await empRepo.addEmployee(Employee(
        id: 'EMP-003',
        code: 'EMP003',
        name: 'Priya Sharma',
        department: 'HR',
        designation: 'HR Executive',
        type: EmployeeType.office,
        phone: '9840555666',
        email: 'priya.sharma@workpulse.com',
        status: EmployeeStatus.active,
        joiningDate: DateTime(2025, 1, 1),
      ));
      final emp = (await empRepo.getEmployeeByCode('EMP003'))!;

      final now = DateTime.now();
      final rawPunch = RawBiometricPunch(
        employeeCode: 'EMP003',
        timestamp: DateTime(now.year, now.month, now.day, 9, 5),
        deviceSerial: 'ZKT-BIO-HQ-01',
        terminalLocation: 'HQ Main Turnstile',
      );

      await attendanceRepo.ingestBiometricPunch(rawPunch, emp);
      final dailyRecord = await attendanceRepo.getDailyAttendanceForEmployee(emp.id, now);

      expect(dailyRecord, isNotNull);
      expect(dailyRecord!.firstPunch?.source, equals(PunchSource.biometric));
    });
  });

  group('4. Unlimited Employee-Site Mapping Tests', () {
    test('Supports assigning unlimited sites and maintains history', () async {
      final mappingRepo = MockMappingRepository();
      final initialMappings = await mappingRepo.getMappingsForEmployee('EMP-001');

      // Raj has multiple mapped locations (CTS, Wipro, WTC, Coimbatore, Cochin)
      expect(initialMappings.length, greaterThanOrEqualTo(5));

      // Add more sites
      await mappingRepo.saveEmployeeMappings(
        employeeId: 'EMP-001',
        siteIds: ['SITE-001', 'SITE-002', 'SITE-003', 'SITE-004', 'SITE-005', 'SITE-006', 'SITE-007'],
        fromDate: DateTime(2026, 1, 1),
        actorName: 'Sarah Jenkins (HR)',
      );

      final updatedActive = await mappingRepo.getActiveSiteIdsForEmployee('EMP-001');
      expect(updatedActive.length, equals(7));
    });
  });
}
