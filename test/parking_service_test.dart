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

    test('refreshAvailability increments a space that was previously decreasing', () {
      final spaces = service.generateParkingSpaces(destination);
      // availableSpaces < previousAvailableSpaces → was decreasing → should tick up
      final decreasing = spaces.first.copyWith(
        availableSpaces: 10,
        previousAvailableSpaces: 15,
      );

      final refreshed = service.refreshAvailability([decreasing]);

      expect(refreshed.first.previousAvailableSpaces, 10);
      expect(refreshed.first.availableSpaces, 11);
    });

    test('filters out spaces beyond maxDistanceKm', () {
      final spaces = service.generateParkingSpaces(destination);

      // All generated spaces are within ~0.5 km of the destination.
      // Setting maxDistanceKm to 0 should exclude every space.
      final results = service.filterParkingSpaces(
        destination: destination,
        spaces: spaces,
        maxPrice: 10,
        maxDistanceKm: 0,
        type: 'any',
        requiresLighting: false,
      );

      expect(results, isEmpty);
    });

    test('filters out spaces without lighting when requiresLighting is true', () {
      final spaces = service.generateParkingSpaces(destination);

      final results = service.filterParkingSpaces(
        destination: destination,
        spaces: spaces,
        maxPrice: 10,
        maxDistanceKm: 5,
        type: 'any',
        requiresLighting: true,
      );

      expect(results.every((r) => r.space.hasLighting), true);
    });

    test('spacesWithNewAvailability returns only spaces that gained spaces', () {
      final gained = service.generateParkingSpaces(destination).first.copyWith(
        availableSpaces: 20,
        previousAvailableSpaces: 10,
      );
      final lost = service.generateParkingSpaces(destination).last.copyWith(
        availableSpaces: 5,
        previousAvailableSpaces: 10,
      );

      final result = service.spacesWithNewAvailability([gained, lost]);

      expect(result, hasLength(1));
      expect(result.first.availableSpaces, 20);
    });

    test('spacesWithNewAvailability returns empty when no spaces improved', () {
      final spaces = service.generateParkingSpaces(destination).map((s) =>
        s.copyWith(availableSpaces: 5, previousAvailableSpaces: 10),
      ).toList();

      final result = service.spacesWithNewAvailability(spaces);

      expect(result, isEmpty);
    });

    test('spacesWithNewAvailability returns empty for equal availability', () {
      final spaces = service.generateParkingSpaces(destination).map((s) =>
        s.copyWith(availableSpaces: 10, previousAvailableSpaces: 10),
      ).toList();

      final result = service.spacesWithNewAvailability(spaces);

      expect(result, isEmpty);
    });

    test('filterParkingSpaces returns results sorted nearest first', () {
      final spaces = service.generateParkingSpaces(destination);

      final results = service.filterParkingSpaces(
        destination: destination,
        spaces: spaces,
        maxPrice: 10,
        maxDistanceKm: 5,
        type: 'any',
        requiresLighting: false,
      );

      for (var i = 0; i < results.length - 1; i++) {
        expect(
          results[i].walkingDistanceKm,
          lessThanOrEqualTo(results[i + 1].walkingDistanceKm),
        );
      }
    });

    test('filterParkingSpaces applies all active filters simultaneously', () {
      final spaces = service.generateParkingSpaces(destination);

      final results = service.filterParkingSpaces(
        destination: destination,
        spaces: spaces,
        maxPrice: 2.0,
        maxDistanceKm: 5,
        type: 'standard',
        requiresLighting: true,
      );

      for (final r in results) {
        expect(r.space.pricePerHour, lessThanOrEqualTo(2.0));
        expect(r.space.type, 'standard');
        expect(r.space.hasLighting, true);
        expect(r.space.availableSpaces, greaterThan(0));
      }
    });
  });
}
