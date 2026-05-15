import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/parking_space.dart';
import 'package:smart_parking_finder_flutter/repositories/parking_repository.dart';

/// Tests for [FirestoreParkingRepository] using an in-process Firestore fake.
///
/// [FakeFirebaseFirestore] mirrors the Firestore API without network access,
/// so these tests run entirely offline while exercising the real repository
/// code paths (collection references, batch writes, document mapping).
///
/// Test partitions:
///   - Fetch before any write → empty list
///   - Write one space → fetch returns it with all fields intact
///   - Write multiple spaces → all returned
///   - Replace overwrites previous batch entirely
///   - Replace with empty list clears destination
///   - Two destinations stored independently
ParkingSpace _makeSpace({
  required String id,
  String name = 'Test Car Park',
  int availableSpaces = 10,
  double pricePerHour = 2.0,
}) {
  return ParkingSpace(
    id: id,
    name: name,
    latitude: 50.8,
    longitude: -1.09,
    pricePerHour: pricePerHour,
    availableSpaces: availableSpaces,
    previousAvailableSpaces: availableSpaces,
    totalSpaces: 50,
    type: 'standard',
    hasLighting: true,
    safetyScore: 4,
    openingHours: '24 hours',
    restrictions: 'None',
    bayWidth: 'standard',
    notes: '',
  );
}

void main() {
  group('FirestoreParkingRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreParkingRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreParkingRepository(firestore: fakeFirestore);
    });

    // ---------------------------------------------------------------
    // Fetch before write
    // ---------------------------------------------------------------

    test('returns empty list when no spaces have been stored', () async {
      final spaces = await repository.fetchParkingSpaces('portsmouth');
      expect(spaces, isEmpty);
    });

    // ---------------------------------------------------------------
    // Store and retrieve
    // ---------------------------------------------------------------

    test('stores and retrieves a single parking space', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [_makeSpace(id: 'p1', name: 'Central Park')],
      );

      final result = await repository.fetchParkingSpaces('portsmouth');
      expect(result, hasLength(1));
      expect(result.first.id, 'p1');
      expect(result.first.name, 'Central Park');
    });

    test('all ParkingSpace fields survive the Firestore round-trip', () async {
      const space = ParkingSpace(
        id: 'p1',
        name: 'Round-trip Space',
        latitude: 50.7984,
        longitude: -1.0911,
        pricePerHour: 3.50,
        availableSpaces: 8,
        previousAvailableSpaces: 10,
        totalSpaces: 60,
        type: 'wide',
        hasLighting: false,
        safetyScore: 3,
        openingHours: '08:00-20:00',
        restrictions: 'No overnight',
        bayWidth: 'wide',
        notes: 'Near the waterfront',
      );

      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [space],
      );

      final stored = (await repository.fetchParkingSpaces('portsmouth')).first;
      expect(stored.id, 'p1');
      expect(stored.name, 'Round-trip Space');
      expect(stored.latitude, 50.7984);
      expect(stored.longitude, -1.0911);
      expect(stored.pricePerHour, 3.50);
      expect(stored.availableSpaces, 8);
      expect(stored.previousAvailableSpaces, 10);
      expect(stored.totalSpaces, 60);
      expect(stored.type, 'wide');
      expect(stored.hasLighting, false);
      expect(stored.safetyScore, 3);
      expect(stored.openingHours, '08:00-20:00');
      expect(stored.restrictions, 'No overnight');
      expect(stored.bayWidth, 'wide');
      expect(stored.notes, 'Near the waterfront');
    });

    test('stores and retrieves multiple parking spaces', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [
          _makeSpace(id: 'p1', name: 'Space One'),
          _makeSpace(id: 'p2', name: 'Space Two'),
          _makeSpace(id: 'p3', name: 'Space Three'),
        ],
      );

      final result = await repository.fetchParkingSpaces('portsmouth');
      expect(result, hasLength(3));
      expect(result.map((s) => s.id), containsAll(['p1', 'p2', 'p3']));
    });

    // ---------------------------------------------------------------
    // Replace semantics
    // ---------------------------------------------------------------

    test('replace overwrites previous spaces entirely', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [_makeSpace(id: 'p1', name: 'Old Space')],
      );

      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [_makeSpace(id: 'p2', name: 'New Space')],
      );

      final result = await repository.fetchParkingSpaces('portsmouth');
      expect(result, hasLength(1));
      expect(result.first.id, 'p2');
    });

    test('replace with empty list clears all spaces', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [_makeSpace(id: 'p1')],
      );

      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [],
      );

      final result = await repository.fetchParkingSpaces('portsmouth');
      expect(result, isEmpty);
    });

    // ---------------------------------------------------------------
    // Destination isolation
    // ---------------------------------------------------------------

    test('different destination keys are stored independently', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [_makeSpace(id: 'p1', name: 'Portsmouth Space')],
      );

      await repository.replaceParkingSpaces(
        destinationKey: 'southampton',
        spaces: [_makeSpace(id: 's1', name: 'Southampton Space')],
      );

      final portsmouth = await repository.fetchParkingSpaces('portsmouth');
      final southampton = await repository.fetchParkingSpaces('southampton');
      expect(portsmouth.first.id, 'p1');
      expect(southampton.first.id, 's1');
    });

    test('fetching unknown destination key returns empty list', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [_makeSpace(id: 'p1')],
      );

      final result = await repository.fetchParkingSpaces('london');
      expect(result, isEmpty);
    });
  });
}
