import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/destination.dart';
import 'package:smart_parking_finder_flutter/services/parking_service.dart';

void main() {
  group('ParkingService', () {
    const service = ParkingService();

    const destination = Destination(
      name: 'Gillingham High Street',
      latitude: 51.3890,
      longitude: 0.5486,
    );

    test('generates parking spaces around destination', () {
      final spaces = service.generateParkingSpaces(destination);

      expect(spaces, hasLength(6));
      expect(spaces.first.name, contains('Gillingham High Street'));
    });

    test('filters out full spaces', () {
      final spaces = service.generateParkingSpaces(destination);

      final results = service.filterParkingSpaces(
        destination: destination,
        spaces: spaces,
        maxPrice: 5,
        maxDistanceKm: 5,
        type: 'any',
        requiresLighting: false,
      );

      expect(results.every((result) => result.space.availableSpaces > 0), true);
    });

    test('filters by price', () {
      final spaces = service.generateParkingSpaces(destination);

      final results = service.filterParkingSpaces(
        destination: destination,
        spaces: spaces,
        maxPrice: 2,
        maxDistanceKm: 5,
        type: 'any',
        requiresLighting: false,
      );

      expect(
        results.every((result) => result.space.pricePerHour <= 2),
        true,
      );
    });

    test('filters by type', () {
      final spaces = service.generateParkingSpaces(destination);

      final results = service.filterParkingSpaces(
        destination: destination,
        spaces: spaces,
        maxPrice: 5,
        maxDistanceKm: 5,
        type: 'wide',
        requiresLighting: false,
      );

      expect(results.every((result) => result.space.type == 'wide'), true);
    });

    test('refreshAvailability reverses the previous movement and stores previous value', () {
      final spaces = service.generateParkingSpaces(destination);
      final refreshed = service.refreshAvailability(spaces);

      expect(refreshed.first.previousAvailableSpaces, spaces.first.availableSpaces);
      expect(refreshed.first.availableSpaces, spaces.first.availableSpaces - 1);
    });

    test('refreshAvailability keeps sold-out spaces at zero', () {
      final spaces = service.generateParkingSpaces(destination);
      final soldOut = spaces.first.copyWith(
        availableSpaces: 0,
        previousAvailableSpaces: 0,
      );

      final refreshed = service.refreshAvailability([
        soldOut,
        ...spaces.skip(1),
      ]);

      expect(refreshed.first.availableSpaces, 0);
    });
  });
}
