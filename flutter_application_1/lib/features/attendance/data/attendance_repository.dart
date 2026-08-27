import 'dart:async';
import '../../../shared/models/attendance_punch.dart';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/site.dart';
import '../../biometric/data/biometric_adapter.dart';

abstract class AttendanceRepository {
  Future<List<AttendancePunch>> getAllPunches();
  Future<List<DailyAttendance>> getDailyAttendanceList({
    DateTime? date,
    String? employeeId,
    String? department,
    AttendanceStatus? status,
    AttendanceSourceType? sourceType,
  });
  Future<DailyAttendance?> getDailyAttendanceForEmployee(String employeeId, DateTime date);
  Future<AttendancePunch> recordMobilePunch({
    required String employeeId,
    required PunchType type,
    required Site site,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double distanceMeters,
    bool isOfflineQueued = false,
  });
  Future<void> ingestBiometricPunch(RawBiometricPunch rawPunch, Employee employee);
  Future<int> syncOfflinePunches();
  Future<DailyAttendance> correctAttendanceRecord({
    required String dailyAttendanceId,
    required String employeeId,
    required DateTime date,
    DateTime? correctedInTime,
    DateTime? correctedOutTime,
    AttendanceStatus? correctedStatus,
    required String reason,
    required String reviewerName,
    required String reviewerRole,
  });
}

class CentralAttendanceRepository implements AttendanceRepository {
  final List<AttendancePunch> _rawPunches = [];
  final List<DailyAttendance> _dailyRecords = [];

  CentralAttendanceRepository() {
    _seedInitialAttendance();
  }

  void _seedInitialAttendance() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Seed Yesterday: Raj (EMP-001) Multi-Site Visit:
    // 09:15 AM IN at CTS Chennai, 05:30 PM OUT at WTC Chennai
    final punchRajIn = AttendancePunch(
      id: 'PUNCH-YEST-001',
      employeeId: 'EMP-001',
      timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 15),
      type: PunchType.inPunch,
      source: PunchSource.mobile,
      siteId: 'SITE-001',
      siteName: 'CTS Chennai Campus',
      latitude: 12.9010,
      longitude: 80.2279,
      accuracy: 6.2,
      distanceMeters: 38.0,
      isVerified: true,
    );

    final punchRajOut = AttendancePunch(
      id: 'PUNCH-YEST-002',
      employeeId: 'EMP-001',
      timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 30),
      type: PunchType.outPunch,
      source: PunchSource.mobile,
      siteId: 'SITE-003',
      siteName: 'WTC Chennai Perungudi',
      latitude: 12.9698,
      longitude: 80.2442,
      accuracy: 7.5,
      distanceMeters: 52.0,
      isVerified: true,
    );

    _rawPunches.addAll([punchRajIn, punchRajOut]);

    _dailyRecords.add(
      DailyAttendance(
        id: 'ATT-YEST-EMP001',
        employeeId: 'EMP-001',
        date: yesterday,
        firstPunch: punchRajIn,
        lastPunch: punchRajOut,
        allPunches: [punchRajIn, punchRajOut],
        visitedSiteNames: ['CTS Chennai Campus', 'WTC Chennai Perungudi'],
        workingDuration: const Duration(hours: 8, minutes: 15),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.mobile,
        remarks: 'Multi-site visit (CTS & WTC). 1 Payroll Working Day credited.',
      ),
    );

    // Seed Yesterday: Suresh (EMP-002) at Wipro Chennai
    final punchSureshIn = AttendancePunch(
      id: 'PUNCH-YEST-003',
      employeeId: 'EMP-002',
      timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 20),
      type: PunchType.inPunch,
      source: PunchSource.mobile,
      siteId: 'SITE-002',
      siteName: 'Wipro Chennai SEZ',
      latitude: 12.9035,
      longitude: 80.2295,
      accuracy: 5.0,
      distanceMeters: 45.0,
      isVerified: true,
    );

    final punchSureshOut = AttendancePunch(
      id: 'PUNCH-YEST-004',
      employeeId: 'EMP-002',
      timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 18, 00),
      type: PunchType.outPunch,
      source: PunchSource.mobile,
      siteId: 'SITE-002',
      siteName: 'Wipro Chennai SEZ',
      latitude: 12.9035,
      longitude: 80.2295,
      accuracy: 5.0,
      distanceMeters: 40.0,
      isVerified: true,
    );

    _rawPunches.addAll([punchSureshIn, punchSureshOut]);
    _dailyRecords.add(
      DailyAttendance(
        id: 'ATT-YEST-EMP002',
        employeeId: 'EMP-002',
        date: yesterday,
        firstPunch: punchSureshIn,
        lastPunch: punchSureshOut,
        allPunches: [punchSureshIn, punchSureshOut],
        visitedSiteNames: ['Wipro Chennai SEZ'],
        workingDuration: const Duration(hours: 8, minutes: 40),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.mobile,
      ),
    );

    // Seed Yesterday Office Biometric Staff (Priya & Anita)
    final punchPriyaIn = AttendancePunch(
      id: 'PUNCH-YEST-005',
      employeeId: 'EMP-003',
      timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 05),
      type: PunchType.inPunch,
      source: PunchSource.biometric,
      siteName: 'HQ Office Biometric Terminal',
      isVerified: true,
    );
    final punchPriyaOut = AttendancePunch(
      id: 'PUNCH-YEST-006',
      employeeId: 'EMP-003',
      timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 45),
      type: PunchType.outPunch,
      source: PunchSource.biometric,
      siteName: 'HQ Office Biometric Terminal',
      isVerified: true,
    );
    _rawPunches.addAll([punchPriyaIn, punchPriyaOut]);
    _dailyRecords.add(
      DailyAttendance(
        id: 'ATT-YEST-EMP003',
        employeeId: 'EMP-003',
        date: yesterday,
        firstPunch: punchPriyaIn,
        lastPunch: punchPriyaOut,
        allPunches: [punchPriyaIn, punchPriyaOut],
        visitedSiteNames: ['HQ Office'],
        workingDuration: const Duration(hours: 8, minutes: 40),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.biometric,
      ),
    );

    // Seed Today's In-Progress Punches
    final punchTodayRaj = AttendancePunch(
      id: 'PUNCH-TODAY-001',
      employeeId: 'EMP-001',
      timestamp: DateTime(today.year, today.month, today.day, 8, 52),
      type: PunchType.inPunch,
      source: PunchSource.mobile,
      siteId: 'SITE-001',
      siteName: 'CTS Chennai Campus',
      latitude: 12.9010,
      longitude: 80.2279,
      accuracy: 8.0,
      distanceMeters: 42.0,
      isVerified: true,
    );
    _rawPunches.add(punchTodayRaj);

    _dailyRecords.add(
      DailyAttendance(
        id: 'ATT-TODAY-EMP001',
        employeeId: 'EMP-001',
        date: today,
        firstPunch: punchTodayRaj,
        lastPunch: null, // Punch OUT pending
        allPunches: [punchTodayRaj],
        visitedSiteNames: ['CTS Chennai Campus'],
        workingDuration: Duration(
          minutes: DateTime.now().difference(punchTodayRaj.timestamp).inMinutes.clamp(0, 720),
        ),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.mobile,
        remarks: 'Punched IN. Ready for Punch OUT.',
      ),
    );

    // Seed Today Office Biometric Punches
    final punchTodayPriya = AttendancePunch(
      id: 'PUNCH-TODAY-002',
      employeeId: 'EMP-003',
      timestamp: DateTime(today.year, today.month, today.day, 9, 2),
      type: PunchType.inPunch,
      source: PunchSource.biometric,
      siteName: 'HQ Office Biometric Terminal',
      isVerified: true,
    );
    final punchTodayAnita = AttendancePunch(
      id: 'PUNCH-TODAY-003',
      employeeId: 'EMP-004',
      timestamp: DateTime(today.year, today.month, today.day, 9, 14),
      type: PunchType.inPunch,
      source: PunchSource.biometric,
      siteName: 'HQ Office Biometric Terminal',
      isVerified: true,
    );
    final punchTodayKarthikLate = AttendancePunch(
      id: 'PUNCH-TODAY-004',
      employeeId: 'EMP-006',
      timestamp: DateTime(today.year, today.month, today.day, 9, 48), // Late (>9:30 AM)
      type: PunchType.inPunch,
      source: PunchSource.biometric,
      siteName: 'HQ Office Biometric Terminal',
      isVerified: true,
    );

    _rawPunches.addAll([punchTodayPriya, punchTodayAnita, punchTodayKarthikLate]);

    _dailyRecords.addAll([
      DailyAttendance(
        id: 'ATT-TODAY-EMP003',
        employeeId: 'EMP-003',
        date: today,
        firstPunch: punchTodayPriya,
        allPunches: [punchTodayPriya],
        visitedSiteNames: ['HQ Office'],
        workingDuration: Duration(minutes: DateTime.now().difference(punchTodayPriya.timestamp).inMinutes),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.biometric,
      ),
      DailyAttendance(
        id: 'ATT-TODAY-EMP004',
        employeeId: 'EMP-004',
        date: today,
        firstPunch: punchTodayAnita,
        allPunches: [punchTodayAnita],
        visitedSiteNames: ['HQ Office'],
        workingDuration: Duration(minutes: DateTime.now().difference(punchTodayAnita.timestamp).inMinutes),
        status: AttendanceStatus.present,
        sourceType: AttendanceSourceType.biometric,
      ),
      DailyAttendance(
        id: 'ATT-TODAY-EMP006',
        employeeId: 'EMP-006',
        date: today,
        firstPunch: punchTodayKarthikLate,
        allPunches: [punchTodayKarthikLate],
        visitedSiteNames: ['HQ Office'],
        workingDuration: Duration(minutes: DateTime.now().difference(punchTodayKarthikLate.timestamp).inMinutes),
        status: AttendanceStatus.late,
        sourceType: AttendanceSourceType.biometric,
        remarks: 'Arrived after grace cutoff (9:30 AM)',
      ),
    ]);

    // Missing IN sample (Vikram EMP-005 yesterday forgot IN punch)
    final punchVikramOutOnly = AttendancePunch(
      id: 'PUNCH-YEST-007',
      employeeId: 'EMP-005',
      timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 30),
      type: PunchType.outPunch,
      source: PunchSource.mobile,
      siteId: 'SITE-005',
      siteName: 'Client ABC Infra Site',
      latitude: 12.9716,
      longitude: 77.5946,
      accuracy: 6.0,
      distanceMeters: 40.0,
      isVerified: true,
    );
    _rawPunches.add(punchVikramOutOnly);
    _dailyRecords.add(
      DailyAttendance(
        id: 'ATT-YEST-EMP005',
        employeeId: 'EMP-005',
        date: yesterday,
        firstPunch: null, // Missing IN!
        lastPunch: punchVikramOutOnly,
        allPunches: [punchVikramOutOnly],
        visitedSiteNames: ['Client ABC Infra Site'],
        workingDuration: Duration.zero,
        status: AttendanceStatus.missingIn,
        sourceType: AttendanceSourceType.mobile,
        remarks: 'Missing IN punch detected. Single OUT recorded.',
      ),
    );
  }

  @override
  Future<List<AttendancePunch>> getAllPunches() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_rawPunches);
  }

  @override
  Future<List<DailyAttendance>> getDailyAttendanceList({
    DateTime? date,
    String? employeeId,
    String? department,
    AttendanceStatus? status,
    AttendanceSourceType? sourceType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var list = List<DailyAttendance>.from(_dailyRecords);

    if (date != null) {
      list = list.where((d) =>
          d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day).toList();
    }
    if (employeeId != null) {
      list = list.where((d) => d.employeeId == employeeId).toList();
    }
    if (status != null) {
      list = list.where((d) => d.status == status).toList();
    }
    if (sourceType != null) {
      list = list.where((d) => d.sourceType == sourceType).toList();
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<DailyAttendance?> getDailyAttendanceForEmployee(String employeeId, DateTime date) async {
    try {
      return _dailyRecords.firstWhere((d) =>
          d.employeeId == employeeId &&
          d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AttendancePunch> recordMobilePunch({
    required String employeeId,
    required PunchType type,
    required Site site,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double distanceMeters,
    bool isOfflineQueued = false,
  }) async {
    final now = DateTime.now();

    // Duplicate punch prevention: Check if identical punch was registered within last 30 seconds
    final isDuplicate = _rawPunches.any((p) =>
        p.employeeId == employeeId &&
        p.type == type &&
        p.siteId == site.id &&
        now.difference(p.timestamp).inSeconds.abs() < 30);

    if (isDuplicate) {
      // Return existing latest punch rather than creating a duplicate
      return _rawPunches.lastWhere((p) => p.employeeId == employeeId && p.type == type);
    }

    final punch = AttendancePunch(
      id: 'PUNCH-${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      timestamp: now,
      type: type,
      source: PunchSource.mobile,
      siteId: site.id,
      siteName: site.name,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distanceMeters: distanceMeters,
      isVerified: true,
      isPendingSync: isOfflineQueued,
    );

    _rawPunches.add(punch);
    _recalculateDailyAttendance(employeeId, now);

    return punch;
  }

  @override
  Future<void> ingestBiometricPunch(RawBiometricPunch rawPunch, Employee employee) async {
    final punchType = rawPunch.timestamp.hour < 13 ? PunchType.inPunch : PunchType.outPunch;
    final punch = AttendancePunch(
      id: 'PUNCH-BIO-${rawPunch.timestamp.millisecondsSinceEpoch}',
      employeeId: employee.id,
      timestamp: rawPunch.timestamp,
      type: punchType,
      source: PunchSource.biometric,
      siteName: rawPunch.terminalLocation,
      isVerified: true,
    );

    _rawPunches.add(punch);
    _recalculateDailyAttendance(employee.id, rawPunch.timestamp);
  }

  void _recalculateDailyAttendance(String employeeId, DateTime timestamp) {
    final targetDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    // Get all punches for this employee on this date, ordered chronologically
    final punchesForDay = _rawPunches.where((p) {
      return p.employeeId == employeeId &&
          p.timestamp.year == targetDate.year &&
          p.timestamp.month == targetDate.month &&
          p.timestamp.day == targetDate.day;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (punchesForDay.isEmpty) return;

    final firstPunch = punchesForDay.first;
    final lastPunch = punchesForDay.length > 1 ? punchesForDay.last : null;

    // Collect all visited site names
    final visitedSites = punchesForDay
        .map((p) => p.siteName ?? 'Assigned Location')
        .toSet()
        .toList();

    // Determine working duration
    Duration duration = Duration.zero;
    if (lastPunch != null) {
      duration = lastPunch.timestamp.difference(firstPunch.timestamp);
    }

    // Determine status according to business rules
    AttendanceStatus status = AttendanceStatus.present;
    final inTimeHour = firstPunch.timestamp.hour;
    final inTimeMinute = firstPunch.timestamp.minute;

    // Late arrival cutoff: 09:30 AM
    if (inTimeHour > 9 || (inTimeHour == 9 && inTimeMinute > 30)) {
      status = AttendanceStatus.late;
    }

    // If only one punch recorded and it's OUT punch
    if (punchesForDay.length == 1 && firstPunch.type == PunchType.outPunch) {
      status = AttendanceStatus.missingIn;
    }

    // If day is past and only 1 IN punch without OUT
    final now = DateTime.now();
    final isPastDay = now.day > targetDate.day || now.month > targetDate.month;
    if (isPastDay && lastPunch == null && firstPunch.type == PunchType.inPunch) {
      status = AttendanceStatus.missingOut;
    }

    // Determine source type (Mobile, Biometric, or Hybrid)
    final hasMobile = punchesForDay.any((p) => p.source == PunchSource.mobile);
    final hasBiometric = punchesForDay.any((p) => p.source == PunchSource.biometric);
    final AttendanceSourceType sourceType = (hasMobile && hasBiometric)
        ? AttendanceSourceType.hybrid
        : (hasBiometric ? AttendanceSourceType.biometric : AttendanceSourceType.mobile);

    final record = DailyAttendance(
      id: 'ATT-${targetDate.millisecondsSinceEpoch}-$employeeId',
      employeeId: employeeId,
      date: targetDate,
      firstPunch: firstPunch,
      lastPunch: lastPunch,
      allPunches: punchesForDay,
      visitedSiteNames: visitedSites,
      workingDuration: duration,
      status: status,
      sourceType: sourceType,
      remarks: visitedSites.length > 1
          ? 'Visited ${visitedSites.length} mapped sites. 1 Working Day credited.'
          : null,
    );

    final existingIndex = _dailyRecords.indexWhere((d) =>
        d.employeeId == employeeId &&
        d.date.year == targetDate.year &&
        d.date.month == targetDate.month &&
        d.date.day == targetDate.day);

    if (existingIndex != -1) {
      _dailyRecords[existingIndex] = record;
    } else {
      _dailyRecords.add(record);
    }
  }

  @override
  Future<int> syncOfflinePunches() async {
    await Future.delayed(const Duration(milliseconds: 500));
    int syncedCount = 0;
    for (int i = 0; i < _rawPunches.length; i++) {
      if (_rawPunches[i].isPendingSync) {
        _rawPunches[i] = _rawPunches[i].copyWith(isPendingSync: false);
        syncedCount++;
      }
    }
    return syncedCount;
  }

  @override
  Future<DailyAttendance> correctAttendanceRecord({
    required String dailyAttendanceId,
    required String employeeId,
    required DateTime date,
    DateTime? correctedInTime,
    DateTime? correctedOutTime,
    AttendanceStatus? correctedStatus,
    required String reason,
    required String reviewerName,
    required String reviewerRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final index = _dailyRecords.indexWhere((d) =>
        d.id == dailyAttendanceId ||
        (d.employeeId == employeeId &&
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day));

    AttendancePunch? firstPunch;
    AttendancePunch? lastPunch;

    if (correctedInTime != null) {
      firstPunch = AttendancePunch(
        id: 'PUNCH-CORR-IN-${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employeeId,
        timestamp: correctedInTime,
        type: PunchType.inPunch,
        source: PunchSource.biometric,
        siteName: 'Manual Correction ($reviewerName)',
        isVerified: true,
      );
      _rawPunches.add(firstPunch);
    }

    if (correctedOutTime != null) {
      lastPunch = AttendancePunch(
        id: 'PUNCH-CORR-OUT-${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employeeId,
        timestamp: correctedOutTime,
        type: PunchType.outPunch,
        source: PunchSource.biometric,
        siteName: 'Manual Correction ($reviewerName)',
        isVerified: true,
      );
      _rawPunches.add(lastPunch);
    }

    final Duration duration = (firstPunch != null && lastPunch != null)
        ? lastPunch.timestamp.difference(firstPunch.timestamp)
        : (index != -1 ? _dailyRecords[index].workingDuration : const Duration(hours: 8));

    final updatedRecord = DailyAttendance(
      id: dailyAttendanceId.isNotEmpty ? dailyAttendanceId : 'ATT-CORR-$employeeId-${date.millisecondsSinceEpoch}',
      employeeId: employeeId,
      date: date,
      firstPunch: firstPunch ?? (index != -1 ? _dailyRecords[index].firstPunch : null),
      lastPunch: lastPunch ?? (index != -1 ? _dailyRecords[index].lastPunch : null),
      allPunches: index != -1 ? _dailyRecords[index].allPunches : [?firstPunch, ?lastPunch],
      visitedSiteNames: index != -1 ? _dailyRecords[index].visitedSiteNames : ['Assigned Location'],
      workingDuration: duration,
      status: correctedStatus ?? AttendanceStatus.present,
      sourceType: index != -1 ? _dailyRecords[index].sourceType : AttendanceSourceType.biometric,
      remarks: 'Manually corrected by $reviewerRole ($reviewerName). Reason: $reason',
    );

    if (index != -1) {
      _dailyRecords[index] = updatedRecord;
    } else {
      _dailyRecords.add(updatedRecord);
    }

    return updatedRecord;
  }
}
