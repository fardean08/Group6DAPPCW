import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../repositories/parking_repository.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'parking_home_screen.dart';

/// Root widget that listens to [AuthService.authStateChanges] and routes the
/// user to either [AuthScreen] (unauthenticated) or [ParkingHomeScreen]
/// (authenticated).
///
/// By reacting to the auth stream rather than navigating imperatively, the
/// gate automatically handles sign-in and sign-out without any manual
/// navigation calls.
class AuthGate extends StatelessWidget {
  /// Creates an [AuthGate] wired to the provided [authService] and
  /// [parkingRepository].
  ///
  /// [firebaseReady] is forwarded to child screens so they can display the
  /// appropriate connectivity status to the user.
  const AuthGate({
    super.key,
    required this.authService,
    required this.parkingRepository,
    required this.firebaseReady,
  });

  /// The authentication service used to observe and mutate auth state.
  final AuthService authService;

  /// The repository used to load and persist parking spaces.
  final ParkingRepository parkingRepository;

  /// Whether Firebase was successfully initialised at app startup.
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return AuthScreen(
            authService: authService,
            firebaseReady: firebaseReady,
          );
        }

        return ParkingHomeScreen(
          user: user,
          authService: authService,
          repository: parkingRepository,
          firebaseReady: firebaseReady,
        );
      },
    );
  }
}
