/// Represents a signed-in user.
class AppUser {
  /// Creates an [AppUser].
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
  });

  /// Firebase UID, or lower-cased email for local fallback accounts.
  final String uid;

  /// The user's email address, normalised to lower case.
  final String email;

  /// Display name set during sign-up.
  final String name;
}
