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
 