/// A location the user searched for, used as the centre point for nearby parking.
class Destination {
  const Destination({
    required this.name,
    required this.longitude,
    required this.latitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  /// URL-safe slug used as the Firestore document key.
  ///
  /// Falls back to a lat-lng string if the name has no alphanumeric chars.
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
