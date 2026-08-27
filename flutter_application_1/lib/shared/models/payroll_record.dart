enum PayrollStatus {
  draft,
  processed,
  approved,
  locked;

  String get displayName {
    switch (this) {
      case PayrollStatus.draft:
        return 'Draft';
      case PayrollStatus.processed:
        return 'Processed';
      case PayrollStatus.approved:
        return 'Approved';
      case PayrollStatus.locked:
        return 'Locked';
    }
  }
}

class PayrollRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final int month;
  final int year;
  final int totalCalendarDays;
  final double payableWorkingDays; // e.g. 26.0 (Multiple site punches per day count as 1.0 day!)
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final int halfDays;
  final int leaveDays;
  final int holidays;
  final int weeklyOffs;
  final int missingPunchCount;
  final double totalOvertimeHours;
  final PayrollStatus status;

  const PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.month,
    required this.year,
    required this.totalCalendarDays,
    required this.payableWorkingDays,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.halfDays,
    required this.leaveDays,
    required this.holidays,
    required this.weeklyOffs,
    required this.missingPunchCount,
    required this.totalOvertimeHours,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'department': department,
      'month': month,
      'year': year,
      'totalCalendarDays': totalCalendarDays,
      'payableWorkingDays': payableWorkingDays,
      'presentDays': presentDays,
      'lateDays': lateDays,
      'absentDays': absentDays,
      'halfDays': halfDays,
      'leaveDays': leaveDays,
      'holidays': holidays,
      'weeklyOffs': weeklyOffs,
      'missingPunchCount': missingPunchCount,
      'totalOvertimeHours': totalOvertimeHours,
      'status': status.name,
    };
  }

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    int parsedMonth = 8;
    int parsedYear = 2026;
    if (json['month'] is int) {
      parsedMonth = json['month'] as int;
    } else if (json['month'] is String) {
      try {
        final parsed = DateTime.parse(json['month'] as String);
        parsedMonth = parsed.month;
        parsedYear = parsed.year;
      } catch (_) {}
    }
    if (json['year'] is int) {
      parsedYear = json['year'] as int;
    }

    return PayrollRecord(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String? ?? 'Employee ${json['employeeId']}',
      employeeCode: json['employeeCode'] as String? ?? json['employeeId'] as String? ?? 'EMP',
      department: json['department'] as String? ?? 'Field Operations',
      month: parsedMonth,
      year: parsedYear,
      totalCalendarDays: (json['totalCalendarDays'] as num?)?.toInt() ?? (json['totalDaysInMonth'] as num?)?.toInt() ?? 30,
      payableWorkingDays: (json['payableWorkingDays'] as num?)?.toDouble() ?? (json['payableDays'] as num?)?.toDouble() ?? 30.0,
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 26,
      lateDays: (json['lateDays'] as num?)?.toInt() ?? 0,
      absentDays: (json['absentDays'] as num?)?.toInt() ?? 0,
      halfDays: (json['halfDays'] as num?)?.toInt() ?? 0,
      leaveDays: (json['leaveDays'] as num?)?.toInt() ?? (json['paidLeaves'] as num?)?.toInt() ?? 0,
      holidays: (json['holidays'] as num?)?.toInt() ?? (json['holidays'] as num?)?.toInt() ?? 0,
      weeklyOffs: (json['weeklyOffs'] as num?)?.toInt() ?? (json['weeklyOffs'] as num?)?.toInt() ?? 4,
      missingPunchCount: (json['missingPunchCount'] as num?)?.toInt() ?? 0,
      totalOvertimeHours: (json['totalOvertimeHours'] as num?)?.toDouble() ?? 0.0,
      status: PayrollStatus.values.firstWhere(
        (s) => s.name == json['status'] || (s == PayrollStatus.draft && json['status'] == 'calculated'),
        orElse: () => PayrollStatus.draft,
      ),
    );
  }
}
