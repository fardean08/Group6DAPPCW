import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking_finder_flutter/models/app_user.dart';
import 'package:smart_parking_finder_flutter/repositories/parking_repository.dart';
import 'package:smart_parking_finder_flutter/screens/auth_gate.dart';
import 'package:smart_parking_finder_flutter/screens/auth_screen.dart';
import 'package:smart_parking_finder_flutter/screens/parking_home_screen.dart';
import 'package:smart_parking_finder_flutter/services/auth_service.dart';

/// [AuthService] stub backed by a [StreamController] so tests can push
/// auth-state events on demand.
class _StubAuth implements AuthService {
  final _controller = StreamController<AppUser?>();

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  /// Emits [user] to all listeners of [authStateChanges].
  void emit(AppUser? user) => _controller.add(user);

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signUp(
          {required String name,
          required String email,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  void dispose() => _controller.close();
}

/// Pumps [AuthGate] inside a [MaterialApp] with a phone-sized viewport.
///
/// Overflow and tile errors are suppressed to keep tests clean when
/// [ParkingHomeScreen] is shown.
Future<_StubAuth> _pumpGate(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final originalOnError = FlutterError.onError!;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('overflowed') || msg.contains('ClientException')) return;
    originalOnError(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  final auth = _StubAuth();
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: AuthGate(
        authService: auth,
        parkingRepository: MemoryParkingRepository(),
        firebaseReady: false,
      ),
    ),
  );
  return auth;
}

void main() {
  // ---------------------------------------------------------------
  // Unauthenticated
  // ---------------------------------------------------------------

  testWidgets('shows AuthScreen while auth state is pending', (tester) async {
    await _pumpGate(tester);
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(ParkingHomeScreen), findsNothing);
  });

  testWidgets('shows AuthScreen when auth stream emits null', (tester) async {
    final auth = await _pumpGate(tester);
    auth.emit(null);
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  // ---------------------------------------------------------------
  // Authenticated
  // ---------------------------------------------------------------

  testWidgets('shows ParkingHomeScreen when auth stream emits a user',
      (tester) async {
    final auth = await _pumpGate(tester);
    auth.emit(
        const AppUser(uid: 'u1', email: 'jane@test.com', name: 'Jane'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ParkingHomeScreen), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('transitions back to AuthScreen when user signs out',
      (tester) async {
    final auth = await _pumpGate(tester);
    auth.emit(
        const AppUser(uid: 'u1', email: 'jane@test.com', name: 'Jane'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ParkingHomeScreen), findsOneWidget);

    auth.emit(null);
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
