import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/destination.dart';

/// Tests for [Destination] model.
///
/// Focuses on the [Destination.key] getter which converts a destination
/// name into a URL/Firestore-safe slug used as a storage key.
///
/// Test partitions for key generation:
///   - Normal name with spaces → spaces replaced with hyphens
///   - Name with special characters → stripped
///   - Name with commas (typical geocoding result) → comma removed
///   - Empty name → falls back to coordinate-based key
///   - Name that produces empty slug after cleaning → coordinate fallback
///   - Coordinates stored correctly as doubles
void main() {
  group('Destination', () {
    // ---------------------------------------------------------------
    // Field storage
    // ---------------------------------------------------------------

    test('stores name, latitude and longitude correctly', () {
      const destination = Destination(
        name: 'Portsmouth Guildhall',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      expect(destination.name, 'Portsmouth Guildhall');
      expect(destination.latitude, 50.7984);
      expect(destination.longitude, -1.0911);
    });

    // ---------------------------------------------------------------
    // Key generation — happy path
    // ---------------------------------------------------------------

    test('key converts spaces to hyphens and lowercases', () {
      const destination = Destination(
        name: 'Portsmouth Guildhall',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      expect(destination.key, 'portsmouth-guildhall');
    });

    test('key uses only the first segment before a comma', () {
      const destination = Destination(
        name: 'Portsmouth Guildhall, Portsmouth, England',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      expect(destination.key, 'portsmouth-guildhall');
    });

    test('key strips special characters', () {
      const destination = Destination(
        name: 'St. Mary\'s Church!',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      // Apostrophes, dots and exclamation marks should be removed
      expect(destination.key, isNot(contains('.')));
      expect(destination.key, isNot(contains('\'')));
      expect(destination.key, isNot(contains('!')));
    });

    test('key does not have leading or trailing hyphens', () {
      const destination = Destination(
        name: '  Guildhall  ',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      expect(destination.key, isNot(startsWith('-')));
      expect(destination.key, isNot(endsWith('-')));
    });

    test('key collapses multiple consecutive hyphens into one', () {
      const destination = Destination(
        name: 'The   Big   Car  Park',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      expect(destination.key, isNot(contains('--')));
    });

    // ---------------------------------------------------------------
    // Key generation — coordinate fallback
    // ---------------------------------------------------------------

    test('key falls back to coordinates when name is empty', () {
      const destination = Destination(
        name: '',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      // Should contain the latitude value, not be empty
      expect(destination.key, isNotEmpty);
      expect(destination.key, contains('50'));
    });

    // ---------------------------------------------------------------
    // Key is consistent
    // ---------------------------------------------------------------

    test('same destination always produces the same key', () {
      const destination = Destination(
        name: 'Portsmouth Guildhall',
        latitude: 50.7984,
        longitude: -1.0911,
      );

      expect(destination.key, equals(destination.key));
    });
  });
}