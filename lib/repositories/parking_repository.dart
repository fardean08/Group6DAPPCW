import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/parking_space.dart';

/// Data-access contract for persisting and retrieving [ParkingSpace] lists.
///
/// Two implementations are provided:
/// - [FirestoreParkingRepository] — reads and writes to Cloud Firestore.
/// - [MemoryParkingRepository] — stores data in a plain Dart map; used as
///   a fallback when Firebase is unavailable and in all unit tests.
abstract class ParkingRepository {
  /// Returns the list of [ParkingSpace]s stored under [destinationKey].
  ///
  /// Returns an empty list if no spaces have been saved for this key.
  Future<List<ParkingSpace>> fetchParkingSpaces(String destinationKey);

  /// Atomically replaces all [ParkingSpace]s stored under [destinationKey]
  /// with [spaces].
  ///
  /// Any previously stored spaces for the same key are deleted before the
  /// new ones are written, so the stored set always exactly matches [spaces].
  Future<void> replaceParkingSpaces({
    required String destinationKey,
    required List<ParkingSpace> spaces,
  });
}

/// [ParkingRepository] backed by Cloud Firestore.
///
/// Spaces are stored in the path:
/// ```
/// parkingDestinations/{destinationKey}/parkingSpaces/{spaceId}
/// ```
/// [replaceParkingSpaces] uses a single Firestore batch to delete old
/// documents and write new ones atomically, minimising partial-update risk.
class FirestoreParkingRepository implements ParkingRepository {
  /// Creates a [FirestoreParkingRepository], optionally injecting a
  /// [firestore] instance for testing.
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

  /// Deletes all existing spaces and writes [spaces] in a single Firestore
  /// batch commit.
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

/// In-memory [ParkingRepository] used when Firebase is unavailable.
///
/// All data is stored in a plain [Map] keyed by destination. Data is lost
/// when the app is closed. This implementation is also used in all unit
/// tests because it avoids any network or SDK dependency.
class MemoryParkingRepository implements ParkingRepository {
  /// Internal store mapping destination keys to their space lists.
  final Map<String, List<ParkingSpace>> _storage = {};

  /// Returns a defensive copy of the stored spaces for [destinationKey].
  ///
  /// Modifications to the returned list do not affect the stored data.
  @override
  Future<List<ParkingSpace>> fetchParkingSpaces(String destinationKey) async {
    return List<ParkingSpace>.from(_storage[destinationKey] ?? []);
  }

  /// Replaces the stored spaces for [destinationKey] with a defensive copy
  /// of [spaces].
  @override
  Future<void> replaceParkingSpaces({
    required String destinationKey,
    required List<ParkingSpace> spaces,
  }) async {
    _storage[destinationKey] = List<ParkingSpace>.from(spaces);
  }
}
