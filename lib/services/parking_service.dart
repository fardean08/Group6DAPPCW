import '../models/destination.dart';
import '../models/parking_space.dart';
import 'distance_service.dart';

enum ParkingSortOrder { distance, price, safetyScore }

class ParkingResult {
  const ParkingResult({
    required this.space,
    required this.walkingDistanceKm,
  });

  final ParkingSpace space;
  final double walkingDistanceKm;
}

class ParkingService {
  const ParkingService({
    this.distanceService = const DistanceService(),
  });

  final DistanceService distanceService;

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

  List<ParkingSpace> spacesWithNewAvailability(List<ParkingSpace> spaces) {
    return spaces
        .where(
          (space) => space.availableSpaces > space.previousAvailableSpaces,
        )
        .toList();
  }

  String _shortDestinationName(String name) {
    final firstPart = name.split(',').first.trim();
    return firstPart.isEmpty ? 'Local' : firstPart;
  }
}
