/// A geographic destination that the user wants to park near.
///
/// Created by [GeocodingService.searchDestination] from an OpenStreetMap
/// Nominatim response. The destination acts as the centre point for all
/// parking-space distance calculations performed by [ParkingService].
class Destination {
  /// Creates a [Destination] with the given name and coordinates.
  const Destination({
    required this.name,
    required this.longitude,
    required this.latitude,
  });

  /// Full display name returned by the Nominatim geocoding API.
  ///
  /// Typically a comma-separated address string, e.g.
  /// "Portsmouth Guildhall, Guildhall Square, Portsmouth, …".
  final String name;

  /// WGS-84 latitude in decimal degrees.
  final double latitude;

  /// WGS-84 longitude in decimal degrees.
  final double longitude;

  /// A URL-safe, lower-case slug derived from [name].
  ///
  /// Used as the Firestore document key for the parking-space collection
  /// so that the same destination always maps to the same storage path.
  /// Falls back to a `"lat-lng"` string when [name] contains no
  /// alphanumeric characters.
  String get key {
    final cleaned = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return cleaned.isEmpty
        ? '${latitude.toStringAsFixed(4)}-${longitude.toStringAsFixed(4)}'
        : cleaned;
  }
}
