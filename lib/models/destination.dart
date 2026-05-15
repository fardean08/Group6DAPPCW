class Destination {
  const Destination({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

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
