import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'repositories/parking_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';

/// Application entry point.
///
/// Attempts to initialise Firebase using [DefaultFirebaseOptions]; if that
/// fails (e.g. placeholder `firebase_options.dart` in development) the app
/// falls back to local-only auth and in-memory storage. [SmartParkingApp] is
/// then run with [firebaseReady] indicating which path is active.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(SmartParkingApp(firebaseReady: firebaseReady));
}

/// Root [MaterialApp] for Smart Parking Finder.
///
/// Selects the correct [AuthService] and [ParkingRepository] implementations
/// based on [firebaseReady], then mounts [AuthGate] as the home widget so the
/// user is routed to [AuthScreen] or [ParkingHomeScreen] depending on their
/// current authentication state.
class SmartParkingApp extends StatelessWidget {
  /// Creates a [SmartParkingApp].
  ///
  /// Set [firebaseReady] to `true` when Firebase has been successfully
  /// initialised so that Firebase-backed services are used; `false` activates
  /// the local fallback mode.
  const SmartParkingApp({
    super.key,
    required this.firebaseReady,
  });

  /// Whether Firebase was successfully initialised at startup.
  ///
  /// Controls which [AuthService] and [ParkingRepository] implementations are
  /// injected into the widget tree: Firebase-backed when `true`, local
  /// in-memory / [SharedPreferences] fallback when `false`.
  final bool firebaseReady;

  /// Builds the [MaterialApp] with theme, [AuthService], and [ParkingRepository]
  /// wired to [AuthGate].
  @override
  Widget build(BuildContext context) {
    final AuthService authService =
        firebaseReady ? FirebaseAuthService() : PersistentLocalAuthService();

    final ParkingRepository parkingRepository = firebaseReady
        ? FirestoreParkingRepository()
        : MemoryParkingRepository();

    return MaterialApp(
      title: 'Smart Parking Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B7280),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9FAFB),
          foregroundColor: Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6B7280), width: 1.4),
          ),
        ),
        useMaterial3: true,
      ),
      home: AuthGate(
        authService: authService,
        parkingRepository: parkingRepository,
        firebaseReady: firebaseReady,
      ),
    );
  }
}
