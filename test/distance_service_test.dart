import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/services/distance_service.dart';

void main() {
  group('DistanceService', () {
    const service = DistanceService();

    test('returns zero for same coordinates', () {
      final distance = service.calculateDistanceKm(
        startLatitude: 51.3890,
        startLongitude: 0.5486,
        endLatitude: 51.3890,
        endLongitude: 0.5486,
      );

      expect(distance, closeTo(0, 0.001));
    });

    test('returns positive distance for different coordinates', () {
      final distance = service.calculateDistanceKm(
        startLatitude: 51.3890,
        startLongitude: 0.5486,
        endLatitude: 51.3900,
        endLongitude: 0.5500,
      );

      expect(distance, greaterThan(0));
    });
  });
}
