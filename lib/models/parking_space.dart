/// Snapshot of a single parking space.
///
/// [previousAvailableSpaces] tracks the last known count so the refresh
/// logic can simulate realistic occupancy changes rather than random noise.
class ParkingSpace {
  const ParkingSpace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.availableSpaces,
    required this.previousAvailableSpaces,
    required this.totalSpaces,
    required this.type,
    required this.hasLighting,
    required this.safetyScore,
    required this.openingHours,
    required this.restrictions,
    required this.bayWidth,
    required this.notes,
  });

  /// Firestore document ID.
  final String id;

  /// Human-readable name of the car park.
  final String name;

  /// Latitude in decimal degrees (WGS-84).
  final double latitude;

  /// Longitude in decimal degrees (WGS-84).
  final double longitude;

  /// Cost per hour in GBP.
  final double pricePerHour;

  /// Number of bays currently free.
  final int availableSpaces;

  /// Availability count from the previous refresh cycle — used to determine
  /// whether occupancy is trending up or down.
  final int previousAvailableSpaces;

  /// Total number of bays in the car park.
  final int totalSpaces;

  /// Bay type: `"standard"`, `"wide"`, or `"disabled"`.
  final String type;

  /// Whether the car park has lighting.
  final bool hasLighting;

  /// Safety rating from 1 (lowest) to 5 (highest).
  final int safetyScore;

  /// Opening hours string, e.g. `"24/7"` or `"Mon–Sat 08:00–20:00"`.
  final String openingHours;

  /// Any access restrictions, e.g. `"Permit holders only after 18:00"`.
  final String restrictions;

  /// Bay width category, e.g. `"standard"` or `"wide"`.
  final String bayWidth;

  /// Free-text notes about the car park.
  final String notes;

  /// Creates a [ParkingSpace] from a Firestore document. Missing fields use sensible defaults.
  factory ParkingSpace.fromMap(String id, Map<String, dynamic> data) {
    return ParkingSpace(
      id: id,
      name: data['name'] as String? ?? 'Unknown parking',
      latitude: (data['latitude'] as num? ?? 0).toDouble(),
      longitude: (data['longitude'] as num? ?? 0).toDouble(),
      pricePerHour: (data['pricePerHour'] as num? ?? 0).toDouble(),
      availableSpaces: (data['availableSpaces'] as num? ?? 0).toInt(),
      previousAvailableSpaces:
          (data['previousAvailableSpaces'] as num? ?? 0).toInt(),
      totalSpaces: (data['totalSpaces'] as num? ?? 0).toInt(),
      type: data['type'] as String? ?? 'standard',
      hasLighting: data['hasLighting'] as bool? ?? false,
      safetyScore: (data['safetyScore'] as num? ?? 0).toInt(),
      openingHours: data['openingHours'] as String? ?? 'Unknown',
      restrictions: data['restrictions'] as String? ?? 'None',
      bayWidth: data['bayWidth'] as String? ?? 'standard',
      notes: data['notes'] as String? ?? '',
    );
  }

  /// Converts to a map for Firestore. The [id] is excluded as Firestore stores it as the doc key.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerHour': pricePerHour,
      'availableSpaces': availableSpaces,
      'previousAvailableSpaces': previousAvailableSpaces,
      'totalSpaces': totalSpaces,
      'type': type,
      'hasLighting': hasLighting,
      'safetyScore': safetyScore,
      'openingHours': openingHours,
      'restrictions': restrictions,
      'bayWidth': bayWidth,
      'notes': notes,
    };
  }

  /// Returns a copy with the given fields replaced.
  ParkingSpace copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? pricePerHour,
    int? availableSpaces,
    int? previousAvailableSpaces,
    int? totalSpaces,
    String? type,
    bool? hasLighting,
    int? safetyScore,
    String? openingHours,
    String? restrictions,
    String? bayWidth,
    String? notes,
  }) {
    return ParkingSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      availableSpaces: availableSpaces ?? this.availableSpaces,
      previousAvailableSpaces:
          previousAvailableSpaces ?? this.previousAvailableSpaces,
      totalSpaces: totalSpaces ?? this.totalSpaces,
      type: type ?? this.type,
      hasLighting: hasLighting ?? this.hasLighting,
      safetyScore: safetyScore ?? this.safetyScore,
      openingHours: openingHours ?? this.openingHours,
      restrictions: restrictions ?? this.restrictions,
      bayWidth: bayWidth ?? this.bayWidth,
      notes: notes ?? this.notes,
    );
  }
}
