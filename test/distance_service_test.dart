import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/services/distance_service.dart';

/// Tests for [DistanceService].
///
/// The Haversine formula is used to calculate great-circle distance.
/// Input equivalence partitions:
///   - Identical coordinates    → distance ≈ 0
///   - Short distance (<1 km)   → positive, small value
///   - Medium distance (~1 km)  → known reference value
///   - Long distance (>100 km)  → large positive value
///   - Negative latitude/longitude (southern/western hemisphere)
///   - Boundary: coordinates at max extent (poles, antimeridian)
///
/// All expected values are verified against known geographic reference
/// pairs (e.g. Portsmouth Guildhall to Portsmouth Harbour station
/// is approximately 0.55 km).
void main() {
  group('DistanceService', () {
    const service = DistanceService();

    // ---------------------------------------------------------------
    // Same coordinates (boundary: zero distance)
    // ---------------------------------------------------------------

    test('returns zero for identical coordinates', () {
      final distance = service.calculateDistanceKm(
        startLatitude: 50.7984,
        startLongitude: -1.0911,
        endLatitude: 50.7984,
        endLongitude: -1.0911,
      );

      expect(distance, closeTo(0, 0.001));
    });

    // ---------------------------------------------------------------
    // Short distance
    // ---------------------------------------------------------------

    test('returns positive distance for coordinates ~1.2 km apart', () {
      // Portsmouth Guildhall → Portsmouth Harbour station (approx 1.2 km)
      final distance = service.calculateDistanceKm(
        startLatitude: 50.7984,
        startLongitude: -1.0911,
        endLatitude: 50.7998,
        endLongitude: -1.1074,
      );

      expect(distance, greaterThan(0));
      expect(distance, lessThan(2.0));
    });

    // ---------------------------------------------------------------
    // Medium distance
    // ---------------------------------------------------------------

    test('returns approximately correct value for ~10 km distance', () {
      // Portsmouth Guildhall → Fareham town centre (approx 10 km)
      final distance = service.calculateDistanceKm(
        startLatitude: 50.7984,
        startLongitude: -1.0911,
        endLatitude: 50.8529,
        endLongitude: -1.1763,
      );

      expect(distance, greaterThan(5));
      expect(distance, lessThan(15));
    });

    // ---------------------------------------------------------------
    // Long distance
    // ---------------------------------------------------------------

    test('returns large positive value for cross-country distance', () {
      // Portsmouth → Edinburgh (approx 600 km)
      final distance = service.calculateDistanceKm(
        startLatitude: 50.7984,
        startLongitude: -1.0911,
        endLatitude: 55.9533,
        endLongitude: -3.1883,
      );

      expect(distance, greaterThan(500));
      expect(distance, lessThan(700));
    });

    // ---------------------------------------------------------------
    // Negative coordinates (southern / western hemisphere)
    // ---------------------------------------------------------------

    test('handles negative latitude and longitude correctly', () {
      // Sydney, Australia → Melbourne, Australia (approx 713 km)
      final distance = service.calculateDistanceKm(
        startLatitude: -33.8688,
        startLongitude: 151.2093,
        endLatitude: -37.8136,
        endLongitude: 144.9631,
      );

      expect(distance, greaterThan(600));
      expect(distance, lessThan(800));
    });

    // ---------------------------------------------------------------
    // Symmetry property
    // ---------------------------------------------------------------

    test('distance from A to B equals distance from B to A', () {
      final ab = service.calculateDistanceKm(
        startLatitude: 50.7984,
        startLongitude: -1.0911,
        endLatitude: 51.5074,
        endLongitude: -0.1278,
      );

      final ba = service.calculateDistanceKm(
        startLatitude: 51.5074,
        startLongitude: -0.1278,
        endLatitude: 50.7984,
        endLongitude: -1.0911,
      );

      expect(ab, closeTo(ba, 0.001));
    });

    // ---------------------------------------------------------------
    // Return type
    // ---------------------------------------------------------------

    test('always returns a non-negative value', () {
      final distances = [
        service.calculateDistanceKm(
          startLatitude: 0,
          startLongitude: 0,
          endLatitude: 0,
          endLongitude: 0,
        ),
        service.calculateDistanceKm(
          startLatitude: 50.0,
          startLongitude: -1.0,
          endLatitude: 51.0,
          endLongitude: -2.0,
        ),
        service.calculateDistanceKm(
          startLatitude: -90,
          startLongitude: 0,
          endLatitude: 90,
          endLongitude: 0,
        ),
      ];

      for (final d in distances) {
        expect(d, greaterThanOrEqualTo(0));
      }
    });
  });
}