import '../models/destination.dart';
import '../models/parking_space.dart';
import 'distance_service.dart';

/// Controls how [ParkingService.filterParkingSpaces] orders its results.
enum ParkingSortOrder {
  /// Sort by walking distance, nearest first.
  distance,

  /// Sort by price per hour, cheapest first.
  price,

  /// Sort by safety score, safest (highest score) first.
  safetyScore,
}

/// Pairs a [ParkingSpace] with its calculated walking distance from the
/// searched destination.
///
/// Created by [ParkingService.filterParkingSpaces] and consumed by the UI
/// to display distance labels and drive map marker visibility.
class ParkingResult {
  /// Creates a [ParkingResult] associating a space with its walking distance.
  const ParkingResult({
    required this.space,
    required this.walkingDistanceKm,
  });

  /// The parking space this result describes.
  final ParkingSpace space;

  /// Straight-line walking distance in kilometres from the destination to
  /// this space, rounded to 2 decimal places.
  final double walkingDistanceKm;
}

/// Business-logic layer for generating, filtering, sorting, and refreshing
/// parking space data.
///
/// Pure Dart — no Flutter dependency — so all methods are fully unit-testable.
/// A [DistanceService] is injected to allow haversine calculations to be
/// replaced in tests.
class ParkingService {
  /// Creates a [ParkingService] with an optional custom [distanceService].
  const ParkingService({
    this.distanceService = const DistanceService(),
  });

  /// Service used to calculate the walking distance between the destination
  /// and each parking space.
  final DistanceService distanceService;

  /// Generates six parking spaces positioned around [destination] at
  /// graduated distances (~0.25 km to ~3.0 km).
  ///
  /// Each space is based on a fixed template (type, price, capacity, etc.)
  /// with its [ParkingSpace.name] prefixed by the first segment of the
  /// destination name and its coordinates offset from the destination centre.
  /// This ensures that adjusting the distance filter progressively reveals
  /// additional results during a demo.
  List<ParkingSpace> generateParkingSpaces(Destination destination) {
    final baseTemplates = <ParkingSpace>[
      const ParkingSpace(
        id: 'p1',
        name: 'Central Car Park',
        latitude: 0,
        longitude: 0,
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
      ),
      const ParkingSpace(
        id: 'p2',
        name: 'Station Parking',
        latitude: 0,
        longitude: 0,
        pricePerHour: 1.60,
        availableSpaces: 12,
        previousAvailableSpaces: 15,
        totalSpaces: 60,
        type: 'standard',
        hasLighting: true,
        safetyScore: 5,
        openingHours: '07:00-22:00',
        restrictions: 'Permit recommended during peak times',
        bayWidth: 'standard',
        notes: 'Good value option near public transport and offices.',
      ),
      const ParkingSpace(
        id: 'p3',
        name: 'Accessible Civic Parking',
        latitude: 0,
        longitude: 0,
        pricePerHour: 2.10,
        availableSpaces: 7,
        previousAvailableSpaces: 4,
        totalSpaces: 35,
        type: 'disabled',
        hasLighting: true,
        safetyScore: 4,
        openingHours: '08:00-20:00',
        restrictions: 'Disabled badge required for accessible bays',
        bayWidth: 'wide',
        notes: 'Includes accessible bays near public buildings.',
      ),
      const ParkingSpace(
        id: 'p4',
        name: 'Outer Zone Wide Bays',
        latitude: 0,
        longitude: 0,
        pricePerHour: 1.20,
        availableSpaces: 0,
        previousAvailableSpaces: 0,
        totalSpaces: 80,
        type: 'wide',
        hasLighting: false,
        safetyScore: 3,
        openingHours: '24 hours',
        restrictions: 'Busy during weekends',
        bayWidth: 'wide',
        notes: 'Cheaper but further from the main destination.',
      ),
      const ParkingSpace(
        id: 'p5',
        name: 'Commercial Road Parking',
        latitude: 0,
        longitude: 0,
        pricePerHour: 2.90,
        availableSpaces: 18,
        previousAvailableSpaces: 20,
        totalSpaces: 50,
        type: 'standard',
        hasLighting: true,
        safetyScore: 4,
        openingHours: '06:00-23:00',
        restrictions: 'No overnight parking',
        bayWidth: 'standard',
        notes: 'Further from centre, close to shops and public transport.',
      ),
      const ParkingSpace(
        id: 'p6',
        name: 'Secure Wide Bay Parking',
        latitude: 0,
        longitude: 0,
        pricePerHour: 2.40,
        availableSpaces: 6,
        previousAvailableSpaces: 2,
        totalSpaces: 28,
        type: 'wide',
        hasLighting: true,
        safetyScore: 5,
        openingHours: '08:00-21:00',
        restrictions: 'Wide bays only, no overnight parking',
        bayWidth: 'wide',
        notes: 'Suitable for drivers who prefer wider spaces.',
      ),
    ];

    // Offsets are graduated so each space sits at a meaningfully different
    // walking distance (~0.25, 0.65, 1.1, 1.7, 2.2, 3.0 km). This ensures
    // that raising the distance filter progressively reveals more results.
    final offsets = <({double lat, double lng})>[
      (lat: 0.0018, lng: -0.0021), // ~0.25 km
      (lat: 0.0040, lng: 0.0070),  // ~0.65 km
      (lat: 0.0080, lng: -0.0100), // ~1.1 km
      (lat: -0.0120, lng: 0.0150), // ~1.7 km
      (lat: 0.0160, lng: 0.0180),  // ~2.2 km
      (lat: -0.0220, lng: 0.0250), // ~3.0 km
    ];

    return baseTemplates.asMap().entries.map((entry) {
      final index = entry.key;
      final base = entry.value;
      final offset = offsets[index];

      return base.copyWith(
        name: '${_shortDestinationName(destination.name)} ${base.name}',
        latitude: destination.latitude + offset.lat,
        longitude: destination.longitude + offset.lng,
      );
    }).toList();
  }

  /// Filters and sorts [spaces] relative to [destination] according to the
  /// supplied criteria, returning only matching [ParkingResult]s.
  ///
  /// A space is excluded when any of the following are true:
  /// - [ParkingSpace.availableSpaces] is zero (full car park).
  /// - [ParkingSpace.pricePerHour] exceeds [maxPrice].
  /// - Walking distance exceeds [maxDistanceKm].
  /// - [type] is not `"any"` and [ParkingSpace.type] does not match [type].
  /// - [requiresLighting] is true and [ParkingSpace.hasLighting] is false.
  ///
  /// The remaining results are sorted according to [sortOrder].
  List<ParkingResult> filterParkingSpaces({
    required Destination destination,
    required List<ParkingSpace> spaces,
    required double maxPrice,
    required double maxDistanceKm,
    required String type,
    required bool requiresLighting,
    ParkingSortOrder sortOrder = ParkingSortOrder.distance,
  }) {
    final results = spaces.map((space) {
      final distance = distanceService.calculateDistanceKm(
        startLatitude: destination.latitude,
        startLongitude: destination.longitude,
        endLatitude: space.latitude,
        endLongitude: space.longitude,
      );

      return ParkingResult(
        space: space,
        walkingDistanceKm: double.parse(distance.toStringAsFixed(2)),
      );
    }).where((result) {
      final space = result.space;

      if (space.availableSpaces <= 0) {
        return false;
      }

      if (space.pricePerHour > maxPrice) {
        return false;
      }

      if (result.walkingDistanceKm > maxDistanceKm) {
        return false;
      }

      if (type != 'any' && space.type != type) {
        return false;
      }

      if (requiresLighting && !space.hasLighting) {
        return false;
      }

      return true;
    }).toList();

    results.sort((a, b) => switch (sortOrder) {
      ParkingSortOrder.distance =>
          a.walkingDistanceKm.compareTo(b.walkingDistanceKm),
      ParkingSortOrder.price =>
          a.space.pricePerHour.compareTo(b.space.pricePerHour),
      ParkingSortOrder.safetyScore =>
          b.space.safetyScore.compareTo(a.space.safetyScore),
    });
    return results;
  }

  /// Simulates a live availability update by incrementing or decrementing
  /// each space's [ParkingSpace.availableSpaces] by one.
  ///
  /// The direction of change alternates based on whether occupancy was
  /// previously increasing or decreasing, producing a smooth oscillation
  /// between full and empty rather than random noise. Full spaces (0 available)
  /// remain unchanged.
  List<ParkingSpace> refreshAvailability(List<ParkingSpace> spaces) {
    return spaces.asMap().entries.map((entry) {
      final space = entry.value;

      if (space.availableSpaces <= 0) {
        return space.copyWith(
          previousAvailableSpaces: space.availableSpaces,
          availableSpaces: 0,
        );
      }

      final wasIncreasing = space.availableSpaces > space.previousAvailableSpaces;
      final change = wasIncreasing ? -1 : 1;
      final nextAvailableSpaces =
          (space.availableSpaces + change).clamp(0, space.totalSpaces);

      return space.copyWith(
        previousAvailableSpaces: space.availableSpaces,
        availableSpaces: nextAvailableSpaces,
      );
    }).toList();
  }

  /// Returns the subset of [spaces] whose [ParkingSpace.availableSpaces] has
  /// increased since the last refresh (i.e. spaces that were recently freed up).
  ///
  /// Used by [ParkingHomeScreen] to trigger a snackbar notification when
  /// previously-full spaces become available.
  List<ParkingSpace> spacesWithNewAvailability(List<ParkingSpace> spaces) {
    return spaces
        .where(
          (space) => space.availableSpaces > space.previousAvailableSpaces,
        )
        .toList();
  }

  /// Extracts the first comma-separated segment of a destination name.
  ///
  /// For example, `"Portsmouth Guildhall, Guildhall Square, Portsmouth"` →
  /// `"Portsmouth Guildhall"`. Used to prefix generated parking space names.
  String _shortDestinationName(String name) {
    final firstPart = name.split(',').first.trim();
    return firstPart.isEmpty ? 'Local' : firstPart;
  }
}
