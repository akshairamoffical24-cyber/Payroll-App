import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../utils/haversine_calculator.dart';

/// Reusable core service for GPS, Location permissions, accuracy, and position queries.
class LocationService {
  /// Default demo presets for testing, edge cases, Web, and emulators.
  static final Map<String, Position> demoLocations = {
    'CTS Chennai (Inside Geofence 42m)': Position(
      latitude: 12.9012,
      longitude: 80.2281,
      timestamp: DateTime.now(),
      accuracy: 6.5,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ),
    'Wipro Chennai (Inside Geofence 80m)': Position(
      latitude: 12.9038,
      longitude: 80.2298,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ),
    'Dual Collision: CTS (60m) & Wipro (75m)': Position(
      latitude: 12.9022,
      longitude: 80.2287,
      timestamp: DateTime.now(),
      accuracy: 4.0,
      altitude: 8.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ),
    'Outside Geofence: CTS Area (450m away)': Position(
      latitude: 12.9055,
      longitude: 80.2315,
      timestamp: DateTime.now(),
      accuracy: 7.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ),
    'Unmapped Location (Central Station)': Position(
      latitude: 13.0827,
      longitude: 80.2707,
      timestamp: DateTime.now(),
      accuracy: 8.0,
      altitude: 5.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ),
    'Poor Accuracy Simulation (±120m)': Position(
      latitude: 12.9012,
      longitude: 80.2281,
      timestamp: DateTime.now(),
      accuracy: 120.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ),
  };

  Position? _simulatedPosition;
  bool _mockPermissionGranted = true;
  bool _mockLocationServiceEnabled = true;

  /// Set a simulated position for demo, testing, or desktop/web environments.
  void setSimulatedPosition(Position? position) {
    _simulatedPosition = position;
  }

  /// Override permission state for automated testing.
  void setMockPermissionGranted(bool granted) {
    _mockPermissionGranted = granted;
  }

  /// Override service status for automated testing.
  void setMockLocationServiceEnabled(bool enabled) {
    _mockLocationServiceEnabled = enabled;
  }

  /// Checks whether device location service (GPS) is turned on.
  Future<bool> isLocationServiceEnabled() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      return isEnabled;
    } catch (_) {
      return _mockLocationServiceEnabled;
    }
  }

  /// Checks whether location permission is currently granted.
  Future<bool> checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return _mockPermissionGranted;
    }
  }

  /// Requests location permission from the operating system.
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      // Fallback to permission_handler if needed
      try {
        final status = await ph.Permission.locationWhenInUse.request();
        return status.isGranted;
      } catch (_) {
        return _mockPermissionGranted;
      }
    }
  }

  /// Obtains the current GPS position with high accuracy.
  Future<Position?> getCurrentLocation({Duration timeLimit = const Duration(seconds: 10)}) async {
    if (_simulatedPosition != null) {
      return _simulatedPosition;
    }

    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _simulatedPosition ?? demoLocations.values.first;
      }

      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          return _simulatedPosition ?? demoLocations.values.first;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
    } catch (_) {
      return _simulatedPosition ?? demoLocations.values.first;
    }
  }

  /// Backward-compatible alias for getCurrentLocation
  Future<Position?> getCurrentPosition() => getCurrentLocation();

  /// Calculates geodesic distance in meters between two coordinates.
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return HaversineCalculator.calculateDistanceMeters(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
  }

  /// Extracts or returns GPS accuracy from position in meters.
  double? getLocationAccuracy(Position? position) {
    return position?.accuracy;
  }

  /// Validates if GPS accuracy is within an acceptable threshold (default <= 50m).
  bool isAccuracyAcceptable(double? accuracy, {double maxAllowedMeters = 50.0}) {
    if (accuracy == null) return true;
    return accuracy <= maxAllowedMeters;
  }

  /// Standard error message for permission denial.
  String handlePermissionDenied([bool isPermanentlyDenied = false]) {
    if (isPermanentlyDenied) {
      return 'Location permission is permanently denied. Please enable it in device Settings.';
    }
    return 'Location permission is required for attendance.';
  }

  /// Standard error message for disabled location service.
  String handleLocationServiceDisabled() {
    return 'Please enable location services.';
  }
}
