import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/parking_space.dart';
import 'package:smart_parking_finder_flutter/repositories/parking_repository.dart';
 
/// Tests for [MemoryParkingRepository].
///
/// [FirestoreParkingRepository] requires a live Firestore instance and is
/// tested manually during the demo. [MemoryParkingRepository] implements
/// the same [ParkingRepository] interface and verifies all contract
/// behaviours that Firestore must also satisfy.
///
/// Test partitions:
///   - Empty store (boundary: fetch before any write)
///   - Single destination with one space
///   - Single destination with multiple spaces
///   - Multiple destinations are stored independently
///   - Replace completely overwrites previous data (not appends)
///   - Fetch returns a copy, not a reference (isolation)
void main() {
  group('MemoryParkingRepository', () {
    late MemoryParkingRepository repository;
 
    /// Minimal valid [ParkingSpace] factory used across tests.
    ParkingSpace makeSpace({
      required String id,
      String name = 'Test Car Park',
      int availableSpaces = 10,
      double pricePerHour = 2.0,
      String type = 'standard',
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
        type: type,
        hasLighting: true,
        safetyScore: 4,
        openingHours: '24 hours',
        restrictions: 'None',
        bayWidth: 'standard',
        notes: '',
      );
    }
 
    setUp(() {
      repository = MemoryParkingRepository();
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
      final space = makeSpace(id: 'p1', name: 'Central Park');
 
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [space],
      );
 
      final result = await repository.fetchParkingSpaces('portsmouth');
      expect(result, hasLength(1));
      expect(result.first.id, 'p1');
      expect(result.first.name, 'Central Park');
    });
 
    test('stores and retrieves multiple parking spaces', () async {
      final spaces = [
        makeSpace(id: 'p1', name: 'Space One'),
        makeSpace(id: 'p2', name: 'Space Two'),
        makeSpace(id: 'p3', name: 'Space Three'),
      ];
 
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: spaces,
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
        spaces: [makeSpace(id: 'p1', name: 'Old Space')],
      );
 
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [makeSpace(id: 'p2', name: 'New Space')],
      );
 
      final result = await repository.fetchParkingSpaces('portsmouth');
      expect(result, hasLength(1));
      expect(result.first.id, 'p2');
    });
 
    test('replace with empty list clears all spaces', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [makeSpace(id: 'p1')],
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
        spaces: [makeSpace(id: 'p1', name: 'Portsmouth Space')],
      );
 
      await repository.replaceParkingSpaces(
        destinationKey: 'southampton',
        spaces: [makeSpace(id: 's1', name: 'Southampton Space')],
      );
 
      final portsmouth = await repository.fetchParkingSpaces('portsmouth');
      final southampton = await repository.fetchParkingSpaces('southampton');
 
      expect(portsmouth.first.id, 'p1');
      expect(southampton.first.id, 's1');
    });
 
    test('fetching unknown destination key returns empty list', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [makeSpace(id: 'p1')],
      );
 
      final result = await repository.fetchParkingSpaces('london');
      expect(result, isEmpty);
    });
 
    // ---------------------------------------------------------------
    // Return value isolation
    // ---------------------------------------------------------------
 
    test('returned list is a copy and does not affect stored data', () async {
      await repository.replaceParkingSpaces(
        destinationKey: 'portsmouth',
        spaces: [makeSpace(id: 'p1')],
      );
 
      final result1 = await repository.fetchParkingSpaces('portsmouth');
      result1.clear();
 
      final result2 = await repository.fetchParkingSpaces('portsmouth');
      expect(result2, hasLength(1));
    });
 
    // ---------------------------------------------------------------
    // ParkingSpace field preservation
    // ---------------------------------------------------------------
 
    test('all ParkingSpace fields are preserved through store and retrieve',
        () async {
      final space = ParkingSpace(
        id: 'p1',
        name: 'Test Space',
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
 
      final result = await repository.fetchParkingSpaces('portsmouth');
      final stored = result.first;
 
      expect(stored.id, 'p1');
      expect(stored.name, 'Test Space');
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
  });
}
 