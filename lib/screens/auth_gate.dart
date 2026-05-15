import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../repositories/parking_repository.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'parking_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.parkingRepository,
    required this.firebaseReady,
  });

  final AuthService authService;
  final ParkingRepository parkingRepository;
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
