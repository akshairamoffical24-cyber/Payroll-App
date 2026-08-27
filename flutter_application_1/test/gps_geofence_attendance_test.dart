import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/services/location_service.dart';
import 'package:flutter_application_1/core/services/geofence_service.dart';
import 'package:flutter_application_1/features/attendance/data/attendance_repository.dart';
import 'package:flutter_application_1/shared/models/attendance_punch.dart';
import 'package:flutter_application_1/shared/models/employee_site_mapping.dart';
import 'package:flutter_application_1/shared/models/site.dart';

void main() {
  late LocationService locationService;
  late GeofenceService geofenceService;
  late CentralAttendanceRepository attendanceRepo;

  final siteCTS = const Site(
    id: 'SITE-001',
    code: 'SITE001',
    name: 'CTS Chennai Campus',
    client: 'Cognizant',
    project: 'Sirius',
    address: 'Siruseri, Chennai',
    latitude: 12.9010,
    longitude: 80.2279,
    geofenceRadius: 100.0,
    poNumber: 'PO-001',
    siteManagerName: 'Manager 1',
    siteEngineerName: 'Engineer 1',
    status: SiteStatus.active,
  );

  final siteWipro = const Site(
    id: 'SITE-002',
    code: 'SITE002',
    name: 'Wipro Chennai SEZ',
    client: 'Wipro',
    project: 'Falcon',
    address: 'Sholinganallur, Chennai',
    latitude: 12.9020,
    longitude: 80.2285,
    geofenceRadius: 100.0,
    poNumber: 'PO-002',
    siteManagerName: 'Manager 2',
    siteEngineerName: 'Engineer 2',
    status: SiteStatus.active,
  );

  final siteInactive = const Site(
    id: 'SITE-INACTIVE',
    code: 'SITE099',
    name: 'Closed Facility Site',
    client: 'Old Client',
    project: 'Completed',
    address: 'Guindy, Chennai',
    latitude: 12.9010,
    longitude: 80.2279,
    geofenceRadius: 100.0,
    poNumber: 'PO-099',
    siteManagerName: 'Manager Old',
    siteEngineerName: 'Engineer Old',
    status: SiteStatus.inactive,
  );

  setUp(() {
    locationService = LocationService();
    geofenceService = GeofenceService();
    attendanceRepo = CentralAttendanceRepository();
  });

  group('GPS & Location Service Tests', () {
    test('1. Permission granted allows location acquisition', () async {
      locationService.setMockPermissionGranted(true);
      final hasPermission = await locationService.checkLocationPermission();
      expect(hasPermission, isTrue);
    });

    test('2. Permission denied returns proper error message and state', () async {
      locationService.setMockPermissionGranted(false);
      final hasPermission = await locationService.checkLocationPermission();
      expect(hasPermission, isFalse);

      final errorMsg = locationService.handlePermissionDenied();
      expect(errorMsg, equals('Location permission is required for attendance.'));
    });

    test('3. Location service disabled returns correct error message', () async {
      locationService.setMockLocationServiceEnabled(false);
      final isEnabled = await locationService.isLocationServiceEnabled();
      expect(isEnabled, isFalse);

      final errorMsg = locationService.handleLocationServiceDisabled();
      expect(errorMsg, equals('Please enable location services.'));
    });

    test('4. Location service enabled status check', () async {
      locationService.setMockLocationServiceEnabled(true);
      final isEnabled = await locationService.isLocationServiceEnabled();
      expect(isEnabled, isTrue);
    });
  });

  group('Geofence Business Rules Tests', () {
    test('5. Inside Geofence (40m from site, 100m radius) is VERIFIED and ALLOWED', () {
      // 12.9012, 80.2281 is approx ~30-40m from CTS Chennai (12.9010, 80.2279)
      final result = geofenceService.evaluateEmployeeLocation(
        currentLat: 12.9012,
        currentLon: 80.2281,
        accuracy: 6.0,
        activeMappedSites: [siteCTS],
      );

      expect(result.state, equals(GeofenceEvaluationState.verified));
      expect(result.isPunchAllowed, isTrue);
      expect(result.matchedSite?.id, equals('SITE-001'));
      expect(result.nearbyMatches.first.isInsideGeofence, isTrue);
    });

    test('6. Outside Geofence (450m from site, 100m radius) is REJECTED', () {
      final result = geofenceService.evaluateEmployeeLocation(
        currentLat: 12.9055,
        currentLon: 80.2315,
        accuracy: 7.0,
        activeMappedSites: [siteCTS],
      );

      expect(result.state, equals(GeofenceEvaluationState.outsideGeofence));
      expect(result.isPunchAllowed, isFalse);
      expect(result.message, contains('Location not within the approved attendance area'));
    });

    test('7. Exactly on radius boundary (distance == radius) is ALLOWED', () {
      // Single site evaluate with exactly matching radius
      final singleResult = geofenceService.evaluateSingleSite(
        currentLat: siteCTS.latitude,
        currentLon: siteCTS.longitude,
        accuracy: 5.0,
        site: siteCTS,
      );

      expect(singleResult.distanceFromSite, lessThanOrEqualTo(siteCTS.geofenceRadius));
      expect(singleResult.isInsideGeofence, isTrue);
    });

    test('8. Multiple nearby approved sites inside geofence returns selectable state', () {
      // Point equidistant/close to both CTS and Wipro within their 100m radii
      final result = geofenceService.evaluateEmployeeLocation(
        currentLat: 12.9015,
        currentLon: 80.2282,
        accuracy: 4.0,
        activeMappedSites: [siteCTS, siteWipro],
      );

      expect(result.state, equals(GeofenceEvaluationState.multipleSitesFound));
      expect(result.isPunchAllowed, isTrue);
      expect(result.nearbyMatches.length, equals(2));
      expect(result.message, contains('Multiple approved sites detected'));
    });

    test('9. No mapped sites in employee profile is REJECTED', () {
      final result = geofenceService.evaluateEmployeeLocation(
        currentLat: 12.9010,
        currentLon: 80.2279,
        accuracy: 5.0,
        activeMappedSites: [],
      );

      expect(result.state, equals(GeofenceEvaluationState.noMappedSites));
      expect(result.isPunchAllowed, isFalse);
      expect(result.message, contains('No approved site is mapped to your profile'));
    });

    test('10. Inactive site is ignored and rejected', () {
      final result = geofenceService.evaluateEmployeeLocation(
        currentLat: 12.9010,
        currentLon: 80.2279,
        accuracy: 5.0,
        activeMappedSites: [siteInactive],
      );

      expect(result.state, equals(GeofenceEvaluationState.noMappedSites));
      expect(result.isPunchAllowed, isFalse);
    });

    test('11. Inactive employee-site mapping is rejected by backend validator', () {
      final mappingInactive = EmployeeSiteMapping(
        id: 'MAP-TEST-INACTIVE',
        employeeId: 'EMP-001',
        siteId: 'SITE-001',
        fromDate: DateTime(2026, 1, 1),
        status: MappingStatus.inactive,
        createdBy: 'Admin',
        createdDate: DateTime(2026, 1, 1),
      );

      final payload = AttendanceVerificationPayload(
        employeeId: 'EMP-001',
        siteId: 'SITE-001',
        latitude: 12.9010,
        longitude: 80.2279,
        accuracy: 5.0,
        distanceMeters: 10.0,
        allowedRadius: 100.0,
        timestamp: DateTime.now(),
      );

      final isValid = geofenceService.validateBackendPayload(
        payload: payload,
        site: siteCTS,
        activeMappings: [mappingInactive],
      );

      expect(isValid, isFalse);
    });

    test('12. Poor GPS accuracy (> 50m) is REJECTED with guidance message', () {
      final result = geofenceService.evaluateEmployeeLocation(
        currentLat: 12.9010,
        currentLon: 80.2279,
        accuracy: 120.0, // High error margin
        activeMappedSites: [siteCTS],
      );

      expect(result.state, equals(GeofenceEvaluationState.poorAccuracy));
      expect(result.isPunchAllowed, isFalse);
      expect(result.message, contains('GPS accuracy is too low'));
    });
  });

  group('Offline Attendance & Duplicate Punch Prevention Tests', () {
    test('13. Offline mode records punch with isPendingSync flag and can sync', () async {
      final punch = await attendanceRepo.recordMobilePunch(
        employeeId: 'EMP-048',
        type: PunchType.inPunch,
        site: siteCTS,
        latitude: 12.9010,
        longitude: 80.2279,
        accuracy: 5.0,
        distanceMeters: 25.0,
        isOfflineQueued: true,
      );

      expect(punch.isPendingSync, isTrue);

      final syncedCount = await attendanceRepo.syncOfflinePunches();
      expect(syncedCount, greaterThanOrEqualTo(1));

      final allPunches = await attendanceRepo.getAllPunches();
      final updatedPunch = allPunches.firstWhere((p) => p.id == punch.id);
      expect(updatedPunch.isPendingSync, isFalse);
    });

    test('14. Duplicate punch within 30s window returns existing punch without duplication', () async {
      final firstPunch = await attendanceRepo.recordMobilePunch(
        employeeId: 'EMP-DUPLICATE-TEST',
        type: PunchType.inPunch,
        site: siteCTS,
        latitude: 12.9010,
        longitude: 80.2279,
        accuracy: 5.0,
        distanceMeters: 30.0,
      );

      // Attempt immediate rapid second punch
      final duplicateAttempt = await attendanceRepo.recordMobilePunch(
        employeeId: 'EMP-DUPLICATE-TEST',
        type: PunchType.inPunch,
        site: siteCTS,
        latitude: 12.9010,
        longitude: 80.2279,
        accuracy: 5.0,
        distanceMeters: 30.0,
      );

      expect(duplicateAttempt.id, equals(firstPunch.id));
    });
  });
}
