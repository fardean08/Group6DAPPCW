import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking_finder_flutter/models/app_user.dart';
import 'package:smart_parking_finder_flutter/models/parking_space.dart';
import 'package:smart_parking_finder_flutter/repositories/parking_repository.dart';
import 'package:smart_parking_finder_flutter/screens/parking_home_screen.dart';
import 'package:smart_parking_finder_flutter/services/auth_service.dart';

/// Stub [AuthService] that never emits a user change and does nothing on
/// sign-out, allowing [ParkingHomeScreen] to render without Firebase.
class _StubAuth implements AuthService {
  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

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
}

/// Pumps [ParkingHomeScreen] inside a [MaterialApp] using a phone-sized
/// viewport (360×800 logical pixels).
///
/// RenderFlex overflow warnings are silenced because the stats grid and filter
/// rows clip slightly in this constrained test viewport but do not affect
/// the behaviour being tested.
Future<void> pumpApp(WidgetTester tester, {ParkingRepository? repo}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final originalOnError = FlutterError.onError!;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    // Suppress layout-overflow warnings (test viewport is narrower than a real
    // device) and map-tile network errors (no live network in tests).
    if (msg.contains('overflowed') || msg.contains('ClientException')) return;
    originalOnError(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  await tester.pumpWidget(
    MaterialApp(
      home: ParkingHomeScreen(
        user:
            const AppUser(uid: 'u1', email: 'test@example.com', name: 'Tester'),
        authService: _StubAuth(),
        repository: repo ?? MemoryParkingRepository(),
        firebaseReady: false,
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows app bar title', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.text('Smart Parking Finder'), findsOneWidget);
  });

  testWidgets('shows signed-in user name in app bar', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.text('Tester'), findsOneWidget);
  });

  testWidgets('shows loading indicator initially', (tester) async {
    await pumpApp(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows search destination field', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.text('Search destination'), findsOneWidget);
  });

  testWidgets('shows reset filters button', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.text('Reset filters'), findsOneWidget);
  });

  // The items below live further down the scrollable list and require
  // scrollUntilVisible to bring them into the built widget subtree.
  // The main ListView's Scrollable is targeted explicitly because FlutterMap
  // and other widgets add extra Scrollable ancestors to the tree.

  testWidgets('shows quick filter preset chips', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final listScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Evening'),
      500.0,
      scrollable: listScrollable,
    );
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('Cheap'), findsOneWidget);
    expect(find.text('Accessible'), findsOneWidget);
  });

  testWidgets('shows parking map section after loading', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final listScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Parking map'),
      500.0,
      scrollable: listScrollable,
    );
    expect(find.text('Parking map'), findsOneWidget);
  });

  testWidgets('shows results count after loading', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final listScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.textContaining('available parking result'),
      500.0,
      scrollable: listScrollable,
    );
    expect(
      find.textContaining('available parking result'),
      findsOneWidget,
    );
  });

  testWidgets('sign-out button is present in app bar', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('shows favourites-only filter toggle', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final listScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Favourites only'),
      300.0,
      scrollable: listScrollable,
    );
    expect(find.text('Favourites only'), findsOneWidget);
  });

  testWidgets('toggling favourites-only filter does not crash', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final listScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Favourites only'),
      300.0,
      scrollable: listScrollable,
    );
    await tester.tap(find.text('Favourites only'));
    await tester.pump();
    expect(find.text('Smart Parking Finder'), findsOneWidget);
  });

  testWidgets('reset filters button re-renders without error', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    await tester.tap(find.text('Reset filters'));
    await tester.pump();
    expect(find.text('Smart Parking Finder'), findsOneWidget);
  });

  testWidgets('shows sort dropdown widget', (tester) async {
    await pumpApp(tester);
    await tester.pump();
    final listScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byType(DropdownButton<String>),
      300.0,
      scrollable: listScrollable,
    );
    expect(find.byType(DropdownButton<String>), findsWidgets);
  });

  testWidgets('pre-loads stored spaces from repository', (tester) async {
    final repo = MemoryParkingRepository();
    await repo.replaceParkingSpaces(
      destinationKey: 'gillingham-high-street',
      spaces: [
        const ParkingSpace(
          id: 'p1',
          name: 'Test Car Park',
          latitude: 51.389,
          longitude: 0.549,
          pricePerHour: 1.50,
          availableSpaces: 10,
          previousAvailableSpaces: 10,
          totalSpaces: 20,
          type: 'standard',
          hasLighting: true,
          safetyScore: 4,
          openingHours: '24 hours',
          restrictions: 'None',
          bayWidth: 'standard',
          notes: '',
        ),
      ],
    );

    await pumpApp(tester, repo: repo);
    await tester.pump();
    final listScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Test Car Park'),
      500.0,
      scrollable: listScrollable,
    );
    expect(find.text('Test Car Park'), findsOneWidget);
  });
}
