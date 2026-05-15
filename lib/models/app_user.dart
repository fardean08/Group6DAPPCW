/// Represents an authenticated user of the Smart Parking Finder application.
///
/// Created by [AuthService] after a successful sign-up or sign-in, and passed
/// through the widget tree via [AuthGate] and [ParkingHomeScreen].
class AppUser {
  /// Creates an [AppUser] with the given identity fields.
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
  });

  /// Unique identifier for this user.
  ///
  /// For Firebase-backed accounts this is the Firebase UID. For local fallback
  /// accounts it is the lower-cased email address.
  final String uid;

  /// The user's email address, normalised to lower case.
  final String email;

  /// The user's display name as entered at sign-up.
  final String name;
}
