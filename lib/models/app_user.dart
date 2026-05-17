/// Represents a signed-in user.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
  });

  // Firebase UID, or lower-cased email for local fallback accounts
  final String uid;
  final String email;
  final String name;
}
