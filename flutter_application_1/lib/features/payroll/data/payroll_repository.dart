import 'dart:async';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/payroll_record.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../employees/data/employee_repository.dart';

abstract class PayrollRepository {
  Future<List<PayrollRecord>> getPayrollSummaryForMonth(int month, int year);
  Future<void> updatePayrollStatus(String recordId, PayrollStatus status);
}

class CentralPayrollRepository implements PayrollRepository {
  final AttendanceRepository _attendanceRepo;
  final EmployeeRepository _employeeRepo;
  final List<PayrollRecord> _cache = [];

  CentralPayrollRepository(this._attendanceRepo, this._employeeRepo);

  @override
  Future<List<PayrollRecord>> getPayrollSummaryForMonth(int month, int year) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final employees = await _employeeRepo.getAllEmployees();
    final allDaily = await _attendanceRepo.getDailyAttendanceList();

    final List<PayrollRecord> summaryList = [];
    final int daysInMonth = DateTime(year, month + 1, 0).day;

    for (final emp in employees) {
      final empDaily = allDaily.where((d) =>
          d.employeeId == emp.id &&
          d.date.month == month &&
          d.date.year == year).toList();

      int presentCount = 0;
      int lateCount = 0;
      int absentCount = 0;
      int halfDayCount = 0;
      int leaveCount = 0;
      int missingPunchCount = 0;
      double totalPayableDays = 0.0;

      for (final d in empDaily) {
        totalPayableDays += d.payrollWorkingDaysCredit;
        switch (d.status) {
          case AttendanceStatus.present:
            presentCount++;
            break;
          case AttendanceStatus.late:
            lateCount++;
            presentCount++;
            break;
          case AttendanceStatus.absent:
            absentCount++;
            break;
          case AttendanceStatus.halfDay:
            halfDayCount++;
            break;
          case AttendanceStatus.leave:
            leaveCount++;
            break;
          case AttendanceStatus.missingIn:
          case AttendanceStatus.missingOut:
            missingPunchCount++;
            break;
          default:
            break;
        }
      }

      // Default calculation for sample monthly projection if month is in progress
      if (totalPayableDays == 0 && emp.status == EmployeeStatus.active) {
        totalPayableDays = 22.0;
        presentCount = 20;
        lateCount = 2;
        absentCount = 0;
      }

      summaryList.add(
        PayrollRecord(
          id: 'PAY-$year-$month-${emp.id}',
          employeeId: emp.id,
          employeeName: emp.name,
          employeeCode: emp.code,
          department: emp.department,
          month: month,
          year: year,
          totalCalendarDays: daysInMonth,
          payableWorkingDays: totalPayableDays,
          presentDays: presentCount,
          lateDays: lateCount,
          absentDays: absentCount,
          halfDays: halfDayCount,
          leaveDays: leaveCount,
          holidays: 2,
          weeklyOffs: 4,
          missingPunchCount: missingPunchCount,
          totalOvertimeHours: emp.type == EmployeeType.field ? 4.5 : 0.0,
          status: PayrollStatus.processed,
        ),
      );
    }

    return summaryList;
  }

  @override
  Future<void> updatePayrollStatus(String recordId, PayrollStatus status) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _cache.indexWhere((p) => p.id == recordId);
    if (index != -1) {
      // update cache
    }
  }
}
