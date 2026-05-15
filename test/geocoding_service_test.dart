import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_parking_finder_flutter/services/geocoding_service.dart';

/// A fake [http.Client] that returns a pre-configured response.
/// This avoids any real network calls and requires no extra packages.
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.body, required this.statusCode});

  final String body;
  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

String _nominatimResponse({
  String displayName = 'Portsmouth Guildhall, Portsmouth, England',
  String lat = '50.7984',
  String lon = '-1.0911',
}) {
  return jsonEncode([
    {'display_name': displayName, 'lat': lat, 'lon': lon}
  ]);
}

/// Tests for [GeocodingService].
///
/// Uses a fake HTTP client so tests run offline with no extra dependencies.
///
/// Test partitions:
///   - Valid single result    -> returns correct Destination
///   - Valid multiple results -> returns first result only
///   - Empty results array   -> throws Exception
///   - HTTP 404              -> throws Exception
///   - HTTP 500              -> throws Exception
///   - Coordinate parsing    -> lat/lon parsed as doubles correctly
///   - Negative coordinates  -> southern/western hemisphere handled
void main() {
  group('GeocodingService', () {
    test('returns Destination with correct fields for a valid response',
        () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _nominatimResponse(
          displayName: 'Portsmouth Guildhall, Portsmouth, England',
          lat: '50.7984',
          lon: '-1.0911',
        ),
      );
      final service = GeocodingService(client: client);
      final destination =
          await service.searchDestination('Portsmouth Guildhall');

      expect(destination.name, 'Portsmouth Guildhall, Portsmouth, England');
      expect(destination.latitude, closeTo(50.7984, 0.0001));
      expect(destination.longitude, closeTo(-1.0911, 0.0001));
    });

    test('returns only the first result when multiple results are returned',
        () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode([
          {'display_name': 'First Result', 'lat': '50.7984', 'lon': '-1.0911'},
          {'display_name': 'Second Result', 'lat': '51.5074', 'lon': '-0.1278'},
        ]),
      );
      final service = GeocodingService(client: client);
      final destination = await service.searchDestination('Portsmouth');

      expect(destination.name, 'First Result');
    });

    test('correctly parses latitude and longitude as doubles', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _nominatimResponse(lat: '51.5074160', lon: '-0.1277583'),
      );
      final service = GeocodingService(client: client);
      final destination = await service.searchDestination('London');

      expect(destination.latitude, isA<double>());
      expect(destination.longitude, isA<double>());
      expect(destination.latitude, closeTo(51.5074, 0.001));
      expect(destination.longitude, closeTo(-0.1278, 0.001));
    });

    test('throws Exception when the result array is empty', () async {
      final client =
          _FakeHttpClient(statusCode: 200, body: jsonEncode([]));
      final service = GeocodingService(client: client);

      expect(
        () => service.searchDestination('XYZ123NonExistentPlace'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception on HTTP 404', () async {
      final client =
          _FakeHttpClient(statusCode: 404, body: 'Not Found');
      final service = GeocodingService(client: client);

      expect(
        () => service.searchDestination('Portsmouth Guildhall'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception on HTTP 500', () async {
      final client =
          _FakeHttpClient(statusCode: 500, body: 'Internal Server Error');
      final service = GeocodingService(client: client);

      expect(
        () => service.searchDestination('Portsmouth Guildhall'),
        throwsA(isA<Exception>()),
      );
    });

    test('handles negative latitude and longitude (southern/western hemisphere)',
        () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _nominatimResponse(lat: '-33.8688', lon: '151.2093'),
      );
      final service = GeocodingService(client: client);
      final destination = await service.searchDestination('Sydney');

      expect(destination.latitude, isNegative);
      expect(destination.longitude, isPositive);
    });

    test('ignores extra fields in the response and returns correct Destination',
        () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode([
          {
            'display_name': 'Portsmouth Guildhall, Portsmouth, England',
            'lat': '50.7984',
            'lon': '-1.0911',
            'place_id': 12345,
            'osm_type': 'way',
            'importance': 0.65,
          }
        ]),
      );
      final service = GeocodingService(client: client);
      final destination =
          await service.searchDestination('Portsmouth Guildhall');

      expect(destination.name, 'Portsmouth Guildhall, Portsmouth, England');
      expect(destination.latitude, closeTo(50.7984, 0.0001));
      expect(destination.longitude, closeTo(-1.0911, 0.0001));
    });
  });
}