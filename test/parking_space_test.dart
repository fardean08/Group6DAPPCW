import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/parking_space.dart';
 
/// Tests for [ParkingSpace] model.
///
/// Test partitions:
///
/// fromMap:
///   - All fields present and correct types  -> parsed correctly
///   - Missing optional fields               -> falls back to defaults
///   - Numeric fields as int vs double       -> both handled (num cast)
///   - Boolean field true and false          -> both parsed correctly
///
/// toMap:
///   - All fields serialised correctly
///   - Round-trip: fromMap(toMap()) produces identical object
///
/// copyWith:
///   - No arguments                          -> identical copy
///   - Single field changed                  -> only that field differs
///   - All fields changed                    -> all fields updated
///   - Original object unchanged after copy
void main() {
  /// A fully populated reference [ParkingSpace] used across tests.
  const reference = ParkingSpace(
    id: 'p1',
    name: 'Central Car Park',
    latitude: 50.7984,
    longitude: -1.0911,
    pricePerHour: 2.80,
    availableSpaces: 34,
    previousAvailableSpaces: 30,
    totalSpaces: 120,
    type: 'standard',
    hasLighting: true,
    safetyScore: 4,
    openingHours: '24 hours',
    restrictions: 'Maximum stay 6 hours',
    bayWidth: 'standard',
    notes: 'Close to the main destination area.',
  );
 
  /// A fully populated map matching [reference] for fromMap/toMap tests.
  final referenceMap = <String, dynamic>{
    'name': 'Central Car Park',
    'latitude': 50.7984,
    'longitude': -1.0911,
    'pricePerHour': 2.80,
    'availableSpaces': 34,
    'previousAvailableSpaces': 30,
    'totalSpaces': 120,
    'type': 'standard',
    'hasLighting': true,
    'safetyScore': 4,
    'openingHours': '24 hours',
    'restrictions': 'Maximum stay 6 hours',
    'bayWidth': 'standard',
    'notes': 'Close to the main destination area.',
  };
 
  // ---------------------------------------------------------------
  // fromMap
  // ---------------------------------------------------------------
 
  group('ParkingSpace.fromMap', () {
    test('parses all fields correctly from a complete map', () {
      final space = ParkingSpace.fromMap('p1', referenceMap);
 
      expect(space.id, 'p1');
      expect(space.name, 'Central Car Park');
      expect(space.latitude, 50.7984);
      expect(space.longitude, -1.0911);
      expect(space.pricePerHour, 2.80);
      expect(space.availableSpaces, 34);
      expect(space.previousAvailableSpaces, 30);
      expect(space.totalSpaces, 120);
      expect(space.type, 'standard');
      expect(space.hasLighting, true);
      expect(space.safetyScore, 4);
      expect(space.openingHours, '24 hours');
      expect(space.restrictions, 'Maximum stay 6 hours');
      expect(space.bayWidth, 'standard');
      expect(space.notes, 'Close to the main destination area.');
    });
 
    test('uses default values when fields are missing from map', () {
      final space = ParkingSpace.fromMap('p1', {});
 
      expect(space.name, 'Unknown parking');
      expect(space.latitude, 0.0);
      expect(space.longitude, 0.0);
      expect(space.pricePerHour, 0.0);
      expect(space.availableSpaces, 0);
      expect(space.previousAvailableSpaces, 0);
      expect(space.totalSpaces, 0);
      expect(space.type, 'standard');
      expect(space.hasLighting, false);
      expect(space.safetyScore, 0);
      expect(space.openingHours, 'Unknown');
      expect(space.restrictions, 'None');
      expect(space.bayWidth, 'standard');
      expect(space.notes, '');
    });
    test('handles integer latitude/longitude values (num cast)', () {
      final space = ParkingSpace.fromMap('p1', {
        ...referenceMap,
        'latitude': 51,
        'longitude': -1,
      });
 
      expect(space.latitude, 51.0);
      expect(space.longitude, -1.0);
      expect(space.latitude, isA<double>());
    });
 
    test('handles integer pricePerHour (num cast)', () {
      final space = ParkingSpace.fromMap('p1', {
        ...referenceMap,
        'pricePerHour': 3,
      });
 
      expect(space.pricePerHour, 3.0);
      expect(space.pricePerHour, isA<double>());
    });
 
    test('parses hasLighting as false correctly', () {
      final space = ParkingSpace.fromMap('p1', {
        ...referenceMap,
        'hasLighting': false,
      });
 
      expect(space.hasLighting, false);
    });
 
    test('parses hasLighting as true correctly', () {
      final space = ParkingSpace.fromMap('p1', {
        ...referenceMap,
        'hasLighting': true,
      });
 
      expect(space.hasLighting, true);
    });
 
    test('uses the provided id, not any id field inside the map', () {
      final space = ParkingSpace.fromMap('custom-id', referenceMap);
      expect(space.id, 'custom-id');
    });
  });
 
  // ---------------------------------------------------------------
  // toMap
  // ---------------------------------------------------------------
 
  group('ParkingSpace.toMap', () {
    test('serialises all fields to map correctly', () {
      final map = reference.toMap();
 
      expect(map['name'], 'Central Car Park');
      expect(map['latitude'], 50.7984);
      expect(map['longitude'], -1.0911);
      expect(map['pricePerHour'], 2.80);
      expect(map['availableSpaces'], 34);
      expect(map['previousAvailableSpaces'], 30);
      expect(map['totalSpaces'], 120);
      expect(map['type'], 'standard');
      expect(map['hasLighting'], true);
      expect(map['safetyScore'], 4);
      expect(map['openingHours'], '24 hours');
      expect(map['restrictions'], 'Maximum stay 6 hours');
      expect(map['bayWidth'], 'standard');
      expect(map['notes'], 'Close to the main destination area.');
    });
 
    test('does not include id in the map (id is the Firestore document key)', () {
      final map = reference.toMap();
      expect(map.containsKey('id'), false);
    });
 
    test('round-trip: fromMap(toMap()) produces equivalent object', () {
      final map = reference.toMap();
      final restored = ParkingSpace.fromMap('p1', map);
 
      expect(restored.id, reference.id);
      expect(restored.name, reference.name);
      expect(restored.latitude, reference.latitude);
      expect(restored.longitude, reference.longitude);
      expect(restored.pricePerHour, reference.pricePerHour);
      expect(restored.availableSpaces, reference.availableSpaces);
      expect(restored.previousAvailableSpaces, reference.previousAvailableSpaces);
      expect(restored.totalSpaces, reference.totalSpaces);
      expect(restored.type, reference.type);
      expect(restored.hasLighting, reference.hasLighting);
      expect(restored.safetyScore, reference.safetyScore);
      expect(restored.openingHours, reference.openingHours);
      expect(restored.restrictions, reference.restrictions);
      expect(restored.bayWidth, reference.bayWidth);
      expect(restored.notes, reference.notes);
    });
  });
 // ---------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------
 
  group('ParkingSpace.copyWith', () {
    test('returns an identical copy when no arguments are provided', () {
      final copy = reference.copyWith();
 
      expect(copy.id, reference.id);
      expect(copy.name, reference.name);
      expect(copy.latitude, reference.latitude);
      expect(copy.longitude, reference.longitude);
      expect(copy.pricePerHour, reference.pricePerHour);
      expect(copy.availableSpaces, reference.availableSpaces);
      expect(copy.type, reference.type);
      expect(copy.hasLighting, reference.hasLighting);
    });
 
    test('updates only availableSpaces when specified', () {
      final copy = reference.copyWith(availableSpaces: 99);
 
      expect(copy.availableSpaces, 99);
      expect(copy.name, reference.name);
      expect(copy.pricePerHour, reference.pricePerHour);
    });
 
    test('updates only name when specified', () {
      final copy = reference.copyWith(name: 'New Name');
 
      expect(copy.name, 'New Name');
      expect(copy.availableSpaces, reference.availableSpaces);
      expect(copy.latitude, reference.latitude);
    });
 
    test('updates only hasLighting when specified', () {
      final copy = reference.copyWith(hasLighting: false);
 
      expect(copy.hasLighting, false);
      expect(copy.name, reference.name);
    });
 
    test('updates multiple fields simultaneously', () {
      final copy = reference.copyWith(
        availableSpaces: 0,
        pricePerHour: 5.00,
        type: 'wide',
        hasLighting: false,
      );
 
      expect(copy.availableSpaces, 0);
      expect(copy.pricePerHour, 5.00);
      expect(copy.type, 'wide');
      expect(copy.hasLighting, false);
      // Unchanged fields stay the same
      expect(copy.name, reference.name);
      expect(copy.id, reference.id);
    });
 
    test('original object is unchanged after copyWith', () {
      reference.copyWith(
        availableSpaces: 0,
        name: 'Changed',
        pricePerHour: 99.99,
      );
 
      expect(reference.availableSpaces, 34);
      expect(reference.name, 'Central Car Park');
      expect(reference.pricePerHour, 2.80);
    });
 
    test('copyWith can update coordinates', () {
      final copy = reference.copyWith(
        latitude: 51.5074,
        longitude: -0.1278,
      );
 
      expect(copy.latitude, 51.5074);
      expect(copy.longitude, -0.1278);
      expect(copy.name, reference.name);
    });
 
    test('copyWith previousAvailableSpaces updates independently of availableSpaces', () {
      final copy = reference.copyWith(
        previousAvailableSpaces: 50,
      );
 
      expect(copy.previousAvailableSpaces, 50);
      expect(copy.availableSpaces, reference.availableSpaces);
    });
  });
}
