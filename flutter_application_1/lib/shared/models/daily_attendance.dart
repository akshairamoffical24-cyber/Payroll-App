import 'attendance_punch.dart';

enum AttendanceStatus {
  present,
  late,
  absent,
  halfDay,
  leave,
  holiday,
  weeklyOff,
  permission,
  onDuty,
  missingIn,
  missingOut;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.holiday:
        return 'Holiday';
      case AttendanceStatus.weeklyOff:
        return 'Weekly Off';
      case AttendanceStatus.permission:
        return 'Permission';
      case AttendanceStatus.onDuty:
        return 'On Duty';
      case AttendanceStatus.missingIn:
        return 'Missing IN';
      case AttendanceStatus.missingOut:
        return 'Missing OUT';
    }
  }

  bool get isPresent => this == AttendanceStatus.present;
  bool get isLate => this == AttendanceStatus.late;
  bool get isPresentOrLate => this == AttendanceStatus.present || this == AttendanceStatus.late;
}

enum AttendanceSourceType {
  mobile,
  biometric,
  hybrid;

  String get displayName {
    switch (this) {
      case AttendanceSourceType.mobile:
        return 'Mobile GPS';
      case AttendanceSourceType.biometric:
        return 'Biometric';
      case AttendanceSourceType.hybrid:
        return 'Hybrid (Multi-Source)';
    }
  }

  bool get isBiometric => this == AttendanceSourceType.biometric;
  bool get isMobile => this == AttendanceSourceType.mobile;
  bool get isHybrid => this == AttendanceSourceType.hybrid;
}

class DailyAttendance {
  final String id;
  final String employeeId;
  final DateTime date;
  final AttendancePunch? firstPunch; // First punch = IN
  final AttendancePunch? lastPunch; // Last punch = OUT
  final List<AttendancePunch> allPunches;
  final List<String> visitedSiteNames;
  final Duration workingDuration;
  final AttendanceStatus status;
  final AttendanceSourceType sourceType;
  final String? remarks;

  const DailyAttendance({
    required this.id,
    required this.employeeId,
    required this.date,
    this.firstPunch,
    this.lastPunch,
    required this.allPunches,
    required this.visitedSiteNames,
    required this.workingDuration,
    required this.status,
    required this.sourceType,
    this.remarks,
  });

  /// Payroll working day credit: multiple site visits on the same date strictly yield 1.0 (or 0.5 for half day).
  double get payrollWorkingDaysCredit {
    switch (status) {
      case AttendanceStatus.present:
      case AttendanceStatus.late:
      case AttendanceStatus.onDuty:
      case AttendanceStatus.permission:
        return 1.0;
      case AttendanceStatus.halfDay:
        return 0.5;
      case AttendanceStatus.holiday:
      case AttendanceStatus.weeklyOff:
        return 1.0; // Paid off
      case AttendanceStatus.leave:
      case AttendanceStatus.absent:
      case AttendanceStatus.missingIn:
      case AttendanceStatus.missingOut:
        return 0.0;
    }
  }

  DailyAttendance copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    AttendancePunch? firstPunch,
    AttendancePunch? lastPunch,
    List<AttendancePunch>? allPunches,
    List<String>? visitedSiteNames,
    Duration? workingDuration,
    AttendanceStatus? status,
    AttendanceSourceType? sourceType,
    String? remarks,
  }) {
    return DailyAttendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      firstPunch: firstPunch ?? this.firstPunch,
      lastPunch: lastPunch ?? this.lastPunch,
      allPunches: allPunches ?? this.allPunches,
      visitedSiteNames: visitedSiteNames ?? this.visitedSiteNames,
      workingDuration: workingDuration ?? this.workingDuration,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'firstPunch': firstPunch?.toJson(),
      'lastPunch': lastPunch?.toJson(),
      'allPunches': allPunches.map((p) => p.toJson()).toList(),
      'visitedSiteNames': visitedSiteNames,
      'workingDurationMinutes': workingDuration.inMinutes,
      'status': status.name,
      'sourceType': sourceType.name,
      'remarks': remarks,
    };
  }

  factory DailyAttendance.fromJson(Map<String, dynamic> json) {
    AttendancePunch? parseFirstPunch() {
      if (json['firstPunch'] != null && json['firstPunch'] is Map<String, dynamic>) {
        return AttendancePunch.fromJson(json['firstPunch'] as Map<String, dynamic>);
      }
      if (json['firstPunchTime'] != null) {
        return AttendancePunch(
          id: json['firstPunchId'] as String? ?? 'PUNCH-IN',
          employeeId: json['employeeId'] as String? ?? '',
          timestamp: DateTime.parse(json['firstPunchTime'] as String),
          type: json['firstPunchType'] == 'outPunch' ? PunchType.outPunch : PunchType.inPunch,
          source: json['firstPunchSource'] == 'biometric' ? PunchSource.biometric : PunchSource.mobile,
          siteName: json['firstPunchSiteName'] as String?,
          isVerified: true,
        );
      }
      return null;
    }

    AttendancePunch? parseLastPunch() {
      if (json['lastPunch'] != null && json['lastPunch'] is Map<String, dynamic>) {
        return AttendancePunch.fromJson(json['lastPunch'] as Map<String, dynamic>);
      }
      if (json['lastPunchTime'] != null) {
        return AttendancePunch(
          id: json['lastPunchId'] as String? ?? 'PUNCH-OUT',
          employeeId: json['employeeId'] as String? ?? '',
          timestamp: DateTime.parse(json['lastPunchTime'] as String),
          type: json['lastPunchType'] == 'inPunch' ? PunchType.inPunch : PunchType.outPunch,
          source: json['lastPunchSource'] == 'biometric' ? PunchSource.biometric : PunchSource.mobile,
          siteName: json['lastPunchSiteName'] as String?,
          isVerified: true,
        );
      }
      return null;
    }

    final first = parseFirstPunch();
    final last = parseLastPunch();

    List<String> parseSites() {
      if (json['visitedSiteNames'] is List) {
        return (json['visitedSiteNames'] as List).map((e) => e.toString()).toList();
      }
      if (json['visitedSiteNamesJson'] != null && json['visitedSiteNamesJson'].toString().isNotEmpty) {
        return json['visitedSiteNamesJson'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      final sites = <String>[];
      final fSite = first?.siteName;
      if (fSite != null) sites.add(fSite);
      final lSite = last?.siteName;
      if (lSite != null && !sites.contains(lSite)) sites.add(lSite);
      return sites;
    }

    final durationMinutes = (json['workingDurationMinutes'] as int?) ??
        (json['workingMinutes'] as int?) ??
        (first != null && last != null ? last.timestamp.difference(first.timestamp).inMinutes.clamp(0, 1440) : 0);

    return DailyAttendance(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      date: DateTime.parse(json['date'] as String),
      firstPunch: first,
      lastPunch: last,
      allPunches: (json['allPunches'] as List<dynamic>? ?? [])
          .map((p) => AttendancePunch.fromJson(p as Map<String, dynamic>))
          .toList(),
      visitedSiteNames: parseSites(),
      workingDuration: Duration(minutes: durationMinutes),
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      sourceType: AttendanceSourceType.values.firstWhere(
        (s) => s.name == json['sourceType'],
        orElse: () => AttendanceSourceType.mobile,
      ),
      remarks: json['remarks'] as String?,
    );
  }
}
