import 'dart:math';

/// Haversine-based distance calculations between two GPS coordinates.
class DistanceService {
  const DistanceService();

  /// Returns the straight-line distance in kilometres between two coordinate pairs.
  double calculateDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(endLatitude - startLatitude);
    final dLng = _toRadians(endLongitude - startLongitude);

    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(startLatitude)) *
            cos(_toRadians(endLatitude)) *
            pow(sin(dLng / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Converts [degrees] to radians.
  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
