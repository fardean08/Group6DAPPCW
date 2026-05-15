import 'dart:math';

/// Calculates straight-line distances between geographic coordinates.
///
/// Uses the Haversine formula, which accounts for Earth's curvature and
/// gives accurate results for the short distances (< 5 km) typical in
/// urban parking searches.
class DistanceService {
  /// Creates a const [DistanceService].
  ///
  /// Declared const so it can be used as a default parameter value in
  /// [ParkingService].
  const DistanceService();

  /// Returns the great-circle distance in kilometres between two WGS-84
  /// coordinate pairs.
  ///
  /// Uses the Haversine formula:
  /// ```
  /// a = sin²(Δlat/2) + cos(lat1)·cos(lat2)·sin²(Δlng/2)
  /// d = 2·R·atan2(√a, √(1−a))
  /// ```
  /// where R = 6371 km (mean Earth radius).
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
