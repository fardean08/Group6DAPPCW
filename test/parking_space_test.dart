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