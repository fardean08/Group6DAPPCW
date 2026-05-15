import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/destination.dart';

/// Resolves a free-text place query to geographic coordinates using the
/// OpenStreetMap Nominatim geocoding API.
///
/// Results are restricted to Great Britain (`countrycodes=gb`) and limited
/// to the single best match. An [http.Client] can be injected for testing
/// without making real network calls.
class GeocodingService {
  /// Creates a [GeocodingService].
  ///
  /// Pass a custom [client] to intercept HTTP requests in tests. When [client]
  /// is omitted the top-level `http.get` function is used directly.
  const GeocodingService({http.Client? client}) : _client = client;

  final http.Client? _client;

  /// Searches for [query] and returns the best-matching [Destination].
  ///
  /// Calls the Nominatim `/search` endpoint with `format=json&limit=1&countrycodes=gb`.
  /// Throws an [Exception] if:
  /// - the HTTP response status is not 200, or
  /// - the result set is empty (no match found for [query]).
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

    final response = await (_client?.get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'SmartParkingFinderCourseworkPrototype/1.0',
          },
        ) ??
        http.get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'SmartParkingFinderCourseworkPrototype/1.0',
          },
        ));

    if (response.statusCode != 200) {
      throw Exception('Could not search for destination.');
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
