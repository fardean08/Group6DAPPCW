import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'repositories/parking_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';

/// Entry point. Tries Firebase first, falls back to local mode if it fails.
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

/// Root widget. Picks Firebase or local services based on [firebaseReady].
class SmartParkingApp extends StatelessWidget {
  const SmartParkingApp({
    super.key,
    required this.firebaseReady,
  });

  final bool firebaseReady;

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
