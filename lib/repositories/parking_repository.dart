import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/parking_space.dart';

/// Interface for loading and saving parking spaces per destination.
abstract class ParkingRepository {
  Future<List<ParkingSpace>> fetchParkingSpaces(String destinationKey);

  /// Replaces all stored spaces for [destinationKey] atomically.
  Future<void> replaceParkingSpaces({
    required String destinationKey,
    required List<ParkingSpace> spaces,
  });
}

/// Firestore-backed repository. Spaces are stored under
/// `parkingDestinations/{destinationKey}/parkingSpaces/{spaceId}`.
class FirestoreParkingRepository implements ParkingRepository {
  FirestoreParkingRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns a reference to the `parkingSpaces` sub-collection for
  /// [destinationKey].
  CollectionReference<Map<String, dynamic>> _parkingCollection(
    String destinationKey,
  ) {
    return _firestore
        .collection('parkingDestinations')
        .doc(destinationKey)
        .collection('parkingSpaces');
  }

  @override
  Future<List<ParkingSpace>> fetchParkingSpaces(String destinationKey) async {
    final snapshot = await _parkingCollection(destinationKey).get();

    return snapshot.docs
        .map((doc) => ParkingSpace.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> replaceParkingSpaces({
    required String destinationKey,
    required List<ParkingSpace> spaces,
  }) async {
    final collection = _parkingCollection(destinationKey);
    final existing = await collection.get();
    final batch = _firestore.batch();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final space in spaces) {
      batch.set(collection.doc(space.id), space.toMap());
    }

    await batch.commit();
  }
}

/// In-memory repository used in tests and when Firebase is unavailable.
class MemoryParkingRepository implements ParkingRepository {
  final Map<String, List<ParkingSpace>> _storage = {};

  @override
  Future<List<ParkingSpace>> fetchParkingSpaces(String destinationKey) async {
    return List<ParkingSpace>.from(_storage[destinationKey] ?? []);
  }

  @override
  Future<void> replaceParkingSpaces({
    required String destinationKey,
    required List<ParkingSpace> spaces,
  }) async {
    _storage[destinationKey] = List<ParkingSpace>.from(spaces);
  }
}
