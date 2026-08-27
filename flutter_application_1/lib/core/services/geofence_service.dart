import '../../shared/models/employee_site_mapping.dart';
import '../../shared/models/site.dart';
import '../utils/haversine_calculator.dart';

/// Calculation output for a specific site geofence evaluation.
class GeofenceResult {
  final double distanceFromSite;
  final bool isInsideGeofence;
  final double currentLatitude;
  final double currentLongitude;
  final double siteLatitude;
  final double siteLongitude;
  final double allowedRadius;
  final double gpsAccuracy;

  const GeofenceResult({
    required this.distanceFromSite,
    required this.isInsideGeofence,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.siteLatitude,
    required this.siteLongitude,
    required this.allowedRadius,
    required this.gpsAccuracy,
  });

  Map<String, dynamic> toJson() => {
        'distanceFromSite': distanceFromSite,
        'isInsideGeofence': isInsideGeofence,
        'currentLatitude': currentLatitude,
        'currentLongitude': currentLongitude,
        'siteLatitude': siteLatitude,
        'siteLongitude': siteLongitude,
        'allowedRadius': allowedRadius,
        'gpsAccuracy': gpsAccuracy,
      };
}

/// A matched site along with its computed distance and geofence status.
class NearbySiteMatch {
  final Site site;
  final GeofenceResult result;

  const NearbySiteMatch({
    required this.site,
    required this.result,
  });

  double get distanceMeters => result.distanceFromSite;
  bool get isInsideGeofence => result.isInsideGeofence;
}

/// Comprehensive evaluation states according to Field Attendance business rules.
enum GeofenceEvaluationState {
  idle,
  detectingGps,
  checkingMappings,
  evaluatingGeofence,
  verified,
  multipleSitesFound,
  outsideGeofence,
  unmappedLocation,
  noMappedSites,
  poorAccuracy,
  permissionDenied,
  gpsDisabled,
  error,
}

/// Result returned after evaluating employee location against active mapped sites.
class GeofenceEvaluationResult {
  final GeofenceEvaluationState state;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final Site? matchedSite;
  final List<NearbySiteMatch> nearbyMatches;
  final String message;
  final bool isPunchAllowed;

  const GeofenceEvaluationResult({
    required this.state,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.matchedSite,
    this.nearbyMatches = const [],
    required this.message,
    this.isPunchAllowed = false,
  });
}

/// Independent payload for backend verification of mobile GPS attendance punches (Requirement 14).
class AttendanceVerificationPayload {
  final String employeeId;
  final String siteId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double distanceMeters;
  final double allowedRadius;
  final DateTime timestamp;

  const AttendanceVerificationPayload({
    required this.employeeId,
    required this.siteId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distanceMeters,
    required this.allowedRadius,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'siteId': siteId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'distanceMeters': distanceMeters,
        'allowedRadius': allowedRadius,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Service for calculating geofence proximity and enforcing business rules for Field Staff attendance.
class GeofenceService {
  /// Evaluates distance and geofence inclusion for a single site.
  GeofenceResult evaluateSingleSite({
    required double currentLat,
    required double currentLon,
    required double accuracy,
    required Site site,
  }) {
    final double distance = HaversineCalculator.calculateDistanceMeters(
      lat1: currentLat,
      lon1: currentLon,
      lat2: site.latitude,
      lon2: site.longitude,
    );

    // Business rule: distance must be within configured geofence radius
    final bool isInside = distance <= site.geofenceRadius;

    return GeofenceResult(
      distanceFromSite: distance,
      isInsideGeofence: isInside,
      currentLatitude: currentLat,
      currentLongitude: currentLon,
      siteLatitude: site.latitude,
      siteLongitude: site.longitude,
      allowedRadius: site.geofenceRadius,
      gpsAccuracy: accuracy,
    );
  }

  /// Evaluates current GPS location against all active mapped sites for the employee.
  GeofenceEvaluationResult evaluateEmployeeLocation({
    required double currentLat,
    required double currentLon,
    required double accuracy,
    required List<Site> activeMappedSites,
    double maxAccuracyThreshold = 50.0,
  }) {
    // 1. Validate GPS Accuracy
    if (accuracy > maxAccuracyThreshold) {
      return GeofenceEvaluationResult(
        state: GeofenceEvaluationState.poorAccuracy,
        latitude: currentLat,
        longitude: currentLon,
        accuracy: accuracy,
        message: 'GPS accuracy is too low (±${accuracy.toStringAsFixed(1)}m). Please move to an open area and try again.',
        isPunchAllowed: false,
      );
    }

    // 2. Validate Active Mapped Sites Presence
    final activeSites = activeMappedSites.where((s) => s.status == SiteStatus.active).toList();
    if (activeSites.isEmpty) {
      return GeofenceEvaluationResult(
        state: GeofenceEvaluationState.noMappedSites,
        latitude: currentLat,
        longitude: currentLon,
        accuracy: accuracy,
        message: 'No approved site is mapped to your profile. Please contact HR.',
        isPunchAllowed: false,
      );
    }

    // 3. Compute distance to every active mapped site
    final List<NearbySiteMatch> allMatches = [];
    for (final site in activeSites) {
      final res = evaluateSingleSite(
        currentLat: currentLat,
        currentLon: currentLon,
        accuracy: accuracy,
        site: site,
      );
      allMatches.add(NearbySiteMatch(site: site, result: res));
    }

    // Sort by nearest distance first
    allMatches.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    // 4. Identify sites where employee is inside geofence
    final insideMatches = allMatches.where((m) => m.isInsideGeofence).toList();

    if (insideMatches.isEmpty) {
      // Outside geofence of all mapped sites
      final nearest = allMatches.first;
      return GeofenceEvaluationResult(
        state: GeofenceEvaluationState.outsideGeofence,
        latitude: currentLat,
        longitude: currentLon,
        accuracy: accuracy,
        matchedSite: nearest.site,
        nearbyMatches: allMatches,
        message: 'Location not within the approved attendance area. (${nearest.site.name} is ${nearest.distanceMeters.toInt()}m away, allowed radius: ${nearest.site.geofenceRadius.toInt()}m).',
        isPunchAllowed: false,
      );
    } else if (insideMatches.length == 1) {
      // Exactly 1 approved site in geofence
      final match = insideMatches.first;
      return GeofenceEvaluationResult(
        state: GeofenceEvaluationState.verified,
        latitude: currentLat,
        longitude: currentLon,
        accuracy: accuracy,
        matchedSite: match.site,
        nearbyMatches: insideMatches,
        message: 'Approved Site Found: ${match.site.name}',
        isPunchAllowed: true,
      );
    } else {
      // Multiple approved sites within geofence (e.g. adjacent campuses)
      return GeofenceEvaluationResult(
        state: GeofenceEvaluationState.multipleSitesFound,
        latitude: currentLat,
        longitude: currentLon,
        accuracy: accuracy,
        nearbyMatches: insideMatches,
        message: 'Multiple approved sites detected. Select your site.',
        isPunchAllowed: true,
      );
    }
  }

  /// Backend validator simulation (Requirement 14).
  /// Verifies attendance payload independently on server/backend before database write.
  bool validateBackendPayload({
    required AttendanceVerificationPayload payload,
    required Site site,
    required List<EmployeeSiteMapping> activeMappings,
    double maxAccuracyThreshold = 50.0,
  }) {
    // 1. Site status check
    if (site.status != SiteStatus.active) return false;

    // 2. Active mapping check
    final isMapped = activeMappings.any((m) =>
        m.employeeId == payload.employeeId &&
        m.siteId == payload.siteId &&
        m.isCurrentlyValid(payload.timestamp));
    if (!isMapped) return false;

    // 3. Accuracy check
    if (payload.accuracy > maxAccuracyThreshold) return false;

    // 4. Geodesic distance calculation
    final distance = HaversineCalculator.calculateDistanceMeters(
      lat1: payload.latitude,
      lon1: payload.longitude,
      lat2: site.latitude,
      lon2: site.longitude,
    );

    return distance <= site.geofenceRadius;
  }
}
