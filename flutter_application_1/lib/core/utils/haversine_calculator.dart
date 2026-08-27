import 'dart:math';

class HaversineCalculator {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates the great-circle distance between two geographic coordinates in meters.
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double rLat1 = _degreesToRadians(lat1);
    final double rLat2 = _degreesToRadians(lat2);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(rLat1) * cos(rLat2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Checks if the given position is within the geofence radius (meters).
  static bool isInsideGeofence({
    required double userLat,
    required double userLon,
    required double siteLat,
    required double siteLon,
    required double radiusMeters,
  }) {
    final double distance = calculateDistanceMeters(
      lat1: userLat,
      lon1: userLon,
      lat2: siteLat,
      lon2: siteLon,
    );
    return distance <= radiusMeters;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
}
