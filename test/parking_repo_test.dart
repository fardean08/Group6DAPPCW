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