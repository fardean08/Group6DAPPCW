import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/destination.dart';

/// Converts a destination name string into geographic coordinates
/// using the Nominatim OpenStreetMap geocoding API.
///
/// Accepts an optional [client] so that tests can inject a [MockClient]
/// without making real network calls.
class GeocodingService {
  const GeocodingService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get _effectiveClient => _client ?? http.Client();

  Future<Destination> searchDestination(String query) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'format': 'json',
        'q': query,
        'limit': '1',
        'countrycodes': 'gb',
      },
    );

    final response = await _effectiveClient.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'SmartParkingFinderCourseworkPrototype/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Could not search destination.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;

    if (decoded.isEmpty) {
      throw Exception('Destination not found.');
    }

    final first = decoded.first as Map<String, dynamic>;

    return Destination(
      name: first['display_name'] as String,
      latitude: double.parse(first['lat'] as String),
      longitude: double.parse(first['lon'] as String),
    );
  }
}