import '../../shared/models/attendance_punch.dart';
import '../../shared/models/daily_attendance.dart';
import '../../shared/models/employee.dart';
import '../../shared/models/employee_site_mapping.dart';
import '../../shared/models/site.dart';

class DepartmentAttendanceMetric {
  final String department;
  final int total;
  final int present;
  final int absent;
  final int late;
  final double attendancePercentage;

  const DepartmentAttendanceMetric({
    required this.department,
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendancePercentage,
  });
}

class SiteAttendanceMetric {
  final Site site;
  final int mappedEmployees;
  final int present;
  final int absent;
  final int late;
  final int missingPunches;
  final double attendancePercentage;

  const SiteAttendanceMetric({
    required this.site,
    required this.mappedEmployees,
    required this.present,
    required this.absent,
    required this.late,
    required this.missingPunches,
    required this.attendancePercentage,
  });
}

class OfficeVsFieldMetric {
  final int officeTotal;
  final int officePresent;
  final int officeLate;
  final double officeRate;

  final int fieldTotal;
  final int fieldPresent;
  final int fieldLate;
  final double fieldRate;

  const OfficeVsFieldMetric({
    required this.officeTotal,
    required this.officePresent,
    required this.officeLate,
    required this.officeRate,
    required this.fieldTotal,
    required this.fieldPresent,
    required this.fieldLate,
    required this.fieldRate,
  });
}

class AnalyticsSummary {
  final int totalEmployees;
  final int activeEmployees;
  final int totalSites;
  final int activeSites;
  final int totalMappings;
  final int activeMappings;

  final int presentToday;
  final int absentToday;
  final int lateToday;
  final int leaveToday;
  final int missingInToday;
  final int missingOutToday;
  final int exceptionsTotal;
  final double overallAttendanceRate;

  final List<DepartmentAttendanceMetric> departmentMetrics;
  final List<SiteAttendanceMetric> siteMetrics;
  final OfficeVsFieldMetric officeVsField;
  final List<String> dataDrivenInsights;

  const AnalyticsSummary({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.totalSites,
    required this.activeSites,
    required this.totalMappings,
    required this.activeMappings,
    required this.presentToday,
    required this.absentToday,
    required this.lateToday,
    required this.leaveToday,
    required this.missingInToday,
    required this.missingOutToday,
    required this.exceptionsTotal,
    required this.overallAttendanceRate,
    required this.departmentMetrics,
    required this.siteMetrics,
    required this.officeVsField,
    required this.dataDrivenInsights,
  });

  bool get hasData => totalEmployees > 0;
}

class AnalyticsEngine {
  /// Computes real analytics from active datasets without any hardcoded mock numbers
  static AnalyticsSummary computeSummary({
    required List<Employee> employees,
    required List<Site> sites,
    required List<EmployeeSiteMapping> mappings,
    required List<DailyAttendance> attendanceRecords,
    required List<AttendancePunch> rawPunches,
  }) {
    if (employees.isEmpty) {
      return AnalyticsSummary(
        totalEmployees: 0,
        activeEmployees: 0,
        totalSites: sites.length,
        activeSites: sites.where((s) => s.status.isActive).length,
        totalMappings: mappings.length,
        activeMappings: mappings.where((m) => m.status.isActive).length,
        presentToday: 0,
        absentToday: 0,
        lateToday: 0,
        leaveToday: 0,
        missingInToday: 0,
        missingOutToday: 0,
        exceptionsTotal: 0,
        overallAttendanceRate: 0.0,
        departmentMetrics: [],
        siteMetrics: [],
        officeVsField: const OfficeVsFieldMetric(
          officeTotal: 0,
          officePresent: 0,
          officeLate: 0,
          officeRate: 0,
          fieldTotal: 0,
          fieldPresent: 0,
          fieldLate: 0,
          fieldRate: 0,
        ),
        dataDrivenInsights: ['Not enough data to generate an insight.'],
      );
    }

    final activeEmployeesList = employees.where((e) => e.status.isActive).toList();
    final activeEmployees = activeEmployeesList.length;
    final activeSites = sites.where((s) => s.status.isActive).length;
    final activeMappings = mappings.where((m) => m.status.isActive).length;

    // Filter attendance for the current working set
    int present = 0;
    int absent = 0;
    int late = 0;
    int leave = 0;
    int missingIn = 0;
    int missingOut = 0;

    for (final att in attendanceRecords) {
      switch (att.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.late:
          late++;
          present++; // late is attended
          break;
        case AttendanceStatus.halfDay:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.leave:
        case AttendanceStatus.permission:
          leave++;
          break;
        case AttendanceStatus.onDuty:
          present++;
          break;
        case AttendanceStatus.missingIn:
          missingIn++;
          present++;
          break;
        case AttendanceStatus.missingOut:
          missingOut++;
          present++;
          break;
        case AttendanceStatus.holiday:
        case AttendanceStatus.weeklyOff:
          break;
      }
    }

    // If attendanceRecords is empty, calculate remaining as unrecorded/absent
    if (attendanceRecords.isEmpty) {
      absent = activeEmployees;
    } else {
      final recordedEmpIds = attendanceRecords.map((a) => a.employeeId).toSet();
      final unrecorded = activeEmployeesList.where((e) => !recordedEmpIds.contains(e.id)).length;
      absent += unrecorded;
    }

    final totalAttended = present;
    final overallRate = activeEmployees > 0 ? (totalAttended / activeEmployees) * 100 : 0.0;
    final exceptionsTotal = missingIn + missingOut + late;

    // 1. Department breakdown
    final deptGroups = <String, List<Employee>>{};
    for (final emp in employees) {
      deptGroups.putIfAbsent(emp.department.isNotEmpty ? emp.department : 'General', () => []).add(emp);
    }

    final deptMetrics = <DepartmentAttendanceMetric>[];
    for (final entry in deptGroups.entries) {
      final deptEmps = entry.value;
      final deptEmpIds = deptEmps.map((e) => e.id).toSet();
      final deptAtt = attendanceRecords.where((a) => deptEmpIds.contains(a.employeeId)).toList();

      final dPresent = deptAtt.where((a) => a.status.isPresent || a.status.isLate).length;
      final dLate = deptAtt.where((a) => a.status.isLate).length;
      final dAbsent = deptEmps.length - dPresent;
      final dRate = deptEmps.isNotEmpty ? (dPresent / deptEmps.length) * 100 : 0.0;

      deptMetrics.add(DepartmentAttendanceMetric(
        department: entry.key,
        total: deptEmps.length,
        present: dPresent,
        absent: dAbsent > 0 ? dAbsent : 0,
        late: dLate,
        attendancePercentage: double.parse(dRate.toStringAsFixed(1)),
      ));
    }

    // 2. Site breakdown
    final siteMetrics = <SiteAttendanceMetric>[];
    for (final s in sites) {
      final mappedEmpIds = mappings
          .where((m) => m.siteId == s.id && m.status.isActive)
          .map((m) => m.employeeId)
          .toSet();

      final siteAtt = attendanceRecords.where((a) => mappedEmpIds.contains(a.employeeId)).toList();
      final sPresent = siteAtt.where((a) => a.status.isPresent || a.status.isLate).length;
      final sLate = siteAtt.where((a) => a.status.isLate).length;
      final sMissing = siteAtt.where((a) => a.status == AttendanceStatus.missingIn || a.status == AttendanceStatus.missingOut).length;
      final sAbsent = mappedEmpIds.length > sPresent ? mappedEmpIds.length - sPresent : 0;
      final sRate = mappedEmpIds.isNotEmpty ? (sPresent / mappedEmpIds.length) * 100 : 0.0;

      siteMetrics.add(SiteAttendanceMetric(
        site: s,
        mappedEmployees: mappedEmpIds.length,
        present: sPresent,
        absent: sAbsent,
        late: sLate,
        missingPunches: sMissing,
        attendancePercentage: double.parse(sRate.toStringAsFixed(1)),
      ));
    }

    // 3. Office vs Field
    final officeEmps = employees.where((e) => e.type.isOffice).toList();
    final fieldEmps = employees.where((e) => e.type.isField).toList();

    final officeIds = officeEmps.map((e) => e.id).toSet();
    final fieldIds = fieldEmps.map((e) => e.id).toSet();

    final officeAtt = attendanceRecords.where((a) => officeIds.contains(a.employeeId)).toList();
    final fieldAtt = attendanceRecords.where((a) => fieldIds.contains(a.employeeId)).toList();

    final officePres = officeAtt.where((a) => a.status.isPresent || a.status.isLate).length;
    final officeLate = officeAtt.where((a) => a.status.isLate).length;
    final officeRate = officeEmps.isNotEmpty ? (officePres / officeEmps.length) * 100 : 0.0;

    final fieldPres = fieldAtt.where((a) => a.status.isPresent || a.status.isLate).length;
    final fieldLate = fieldAtt.where((a) => a.status.isLate).length;
    final fieldRate = fieldEmps.isNotEmpty ? (fieldPres / fieldEmps.length) * 100 : 0.0;

    final officeVsField = OfficeVsFieldMetric(
      officeTotal: officeEmps.length,
      officePresent: officePres,
      officeLate: officeLate,
      officeRate: double.parse(officeRate.toStringAsFixed(1)),
      fieldTotal: fieldEmps.length,
      fieldPresent: fieldPres,
      fieldLate: fieldLate,
      fieldRate: double.parse(fieldRate.toStringAsFixed(1)),
    );

    // 4. Generate real data-driven insights
    final insights = <String>[];

    if (overallRate >= 90) {
      insights.add('Workforce attendance is high today at ${overallRate.toStringAsFixed(1)}%.');
    } else if (overallRate > 0) {
      insights.add('Current attendance rate is ${overallRate.toStringAsFixed(1)}% across ${employees.length} employees.');
    }

    if (missingIn + missingOut > 0) {
      insights.add('${missingIn + missingOut} employee(s) have missing punch records requiring regularization.');
    }

    if (late > 0) {
      insights.add('$late employee(s) clocked in past grace period today.');
    }

    // Find highest late site
    final highestLateSite = siteMetrics.where((s) => s.late > 0).toList()
      ..sort((a, b) => b.late.compareTo(a.late));
    if (highestLateSite.isNotEmpty && highestLateSite.first.late > 0) {
      insights.add('Site ${highestLateSite.first.site.name} recorded the most delayed arrivals (${highestLateSite.first.late}).');
    }

    // Field staff compliance
    if (fieldEmps.isNotEmpty && fieldRate > 0) {
      insights.add('Field staff GPS attendance compliance stands at ${fieldRate.toStringAsFixed(1)}%.');
    }

    if (insights.isEmpty) {
      insights.add('All attendance parameters are operating normally with zero recorded exceptions.');
    }

    return AnalyticsSummary(
      totalEmployees: employees.length,
      activeEmployees: activeEmployees,
      totalSites: sites.length,
      activeSites: activeSites,
      totalMappings: mappings.length,
      activeMappings: activeMappings,
      presentToday: present,
      absentToday: absent,
      lateToday: late,
      leaveToday: leave,
      missingInToday: missingIn,
      missingOutToday: missingOut,
      exceptionsTotal: exceptionsTotal,
      overallAttendanceRate: double.parse(overallRate.toStringAsFixed(1)),
      departmentMetrics: deptMetrics,
      siteMetrics: siteMetrics,
      officeVsField: officeVsField,
      dataDrivenInsights: insights,
    );
  }
}
