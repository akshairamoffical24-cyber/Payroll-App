import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_application_1/core/services/analytics_engine.dart';
import 'package:flutter_application_1/core/services/excel_import_service.dart';
import 'package:flutter_application_1/shared/models/daily_attendance.dart';
import 'package:flutter_application_1/shared/models/employee.dart';
import 'package:flutter_application_1/shared/models/import_job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Excel Import Service Tests', () {
    final service = ExcelImportService();

    test('generateEmployeeTemplate creates non-empty valid xlsx bytes with headers', () {
      final bytes = service.generateEmployeeTemplate();
      expect(bytes, isNotEmpty);

      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.keys, contains('Employee_Master_Template'));

      final sheet = excel.tables['Employee_Master_Template']!;
      expect(sheet.maxRows, greaterThanOrEqualTo(1));
      expect(sheet.rows[0][0]?.value.toString(), contains('Employee ID'));
    });

    test('generateErrorReport produces error spreadsheet with row numbers and field names', () {
      final errors = [
        const ImportError(
          rowNumber: 2,
          fieldName: 'Email',
          errorMessage: 'Invalid email address format',
          rawValue: 'invalid_email_string',
          errorType: ImportErrorType.invalidEmail,
        ),
      ];

      final bytes = service.generateErrorReport(errors);
      expect(bytes, isNotEmpty);

      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.keys, contains('Import_Errors'));
      final sheet = excel.tables['Import_Errors']!;
      expect(sheet.maxRows, greaterThanOrEqualTo(2));
    });

    test('parseAndValidateExcel flags validation errors for invalid data without crashing', () async {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([TextCellValue('Random Header'), TextCellValue('Another')]);
      sheet.appendRow([TextCellValue('Val1'), TextCellValue('Val2')]);
      final bytes = excel.encode()!;

      final result = await service.parseAndValidateExcel(
        fileBytes: Uint8List.fromList(bytes),
        fileName: 'test.xlsx',
        existingEmployees: [],
        mode: ImportMode.addNew,
      );

      expect(result.validEmployees, isEmpty);
    });
  });

  group('Analytics Engine Tests', () {
    test('computeSummary handles zero employees cleanly without fake data', () {
      final summary = AnalyticsEngine.computeSummary(
        employees: [],
        sites: [],
        mappings: [],
        attendanceRecords: [],
        rawPunches: [],
      );

      expect(summary.totalEmployees, 0);
      expect(summary.activeEmployees, 0);
      expect(summary.overallAttendanceRate, 0.0);
      expect(summary.hasData, isFalse);
      expect(summary.dataDrivenInsights.first, contains('Not enough data'));
    });

    test('computeSummary correctly computes active metrics and rates for real datasets', () {
      final emp1 = Employee(
        id: 'EMP-001',
        code: 'E001',
        name: 'Alex Morgan',
        department: 'Projects',
        designation: 'Site Engineer',
        type: EmployeeType.field,
        phone: '9876543210',
        email: 'alex@workpulse.io',
        status: EmployeeStatus.active,
        joiningDate: DateTime(2025, 1, 1),
      );

      final emp2 = Employee(
        id: 'EMP-002',
        code: 'E002',
        name: 'Elena Rostova',
        department: 'Human Resources',
        designation: 'HR Lead',
        type: EmployeeType.office,
        phone: '9876543211',
        email: 'elena@workpulse.io',
        status: EmployeeStatus.active,
        joiningDate: DateTime(2025, 1, 1),
      );

      final today = DateTime(2026, 8, 25);
      final att1 = DailyAttendance(
        id: 'ATT-1',
        employeeId: 'EMP-001',
        date: today,
        workingDuration: const Duration(hours: 8),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.mobile,
        allPunches: const [],
        visitedSiteNames: const ['CTS Chennai Campus'],
      );

      final summary = AnalyticsEngine.computeSummary(
        employees: [emp1, emp2],
        sites: [],
        mappings: [],
        attendanceRecords: [att1],
        rawPunches: [],
      );

      expect(summary.totalEmployees, 2);
      expect(summary.activeEmployees, 2);
      expect(summary.presentToday, 1);
      expect(summary.absentToday, 1); // 1 present, 1 unrecorded
      expect(summary.overallAttendanceRate, 50.0);
      expect(summary.departmentMetrics.length, 2);
      expect(summary.dataDrivenInsights, isNotEmpty);
    });
  });
}
