import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/destination.dart';

class GeocodingService {
  const GeocodingService();

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

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'SmartParkingFinderCourseworkPrototype/1.0',
      },
    );

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
