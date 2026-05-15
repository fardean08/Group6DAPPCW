import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/app_user.dart';
import 'package:smart_parking_finder_flutter/screens/auth_screen.dart';
import 'package:smart_parking_finder_flutter/services/auth_service.dart';

/// Configurable stub [AuthService].
///
/// Set [signInError] / [signUpError] to a non-null string to make the
/// corresponding method throw; leave null to have it return a dummy user.
class _StubAuth implements AuthService {
  String? signInError;
  String? signUpError;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signIn(
      {required String email, required String password}) async {
    if (signInError != null) throw Exception(signInError);
    return const AppUser(uid: 'u1', email: 'jane@test.com', name: 'Jane');
  }

  @override
  Future<AppUser> signUp(
      {required String name,
      required String email,
      required String password}) async {
    if (signUpError != null) throw Exception(signUpError);
    return const AppUser(uid: 'u1', email: 'jane@test.com', name: 'Jane');
  }

  @override
  Future<void> signOut() async {}
}

/// Wraps [AuthScreen] in a [MaterialApp] with a stub auth service.
Widget buildScreen({String? signInError, String? signUpError}) {
  final auth = _StubAuth()
    ..signInError = signInError
    ..signUpError = signUpError;
  return MaterialApp(
    home: AuthScreen(authService: auth, firebaseReady: false),
  );
}

/// Scrolls the [FilledButton] into view and taps it.
Future<void> tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(FilledButton));
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.pump();
}

/// Enters valid login credentials into the visible form fields.
Future<void> enterLoginCredentials(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@test.com');
  await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secret123');
}

void main() {
  // ---------------------------------------------------------------
  // Structure
  // ---------------------------------------------------------------

  testWidgets('shows Smart Parking Finder title', (tester) async {
    await tester.pumpWidget(buildScreen());
    expect(find.text('Smart Parking Finder'), findsOneWidget);
  });

  testWidgets('shows Log in heading by default', (tester) async {
    await tester.pumpWidget(buildScreen());
    expect(find.text('Log in'), findsWidgets);
  });

  testWidgets('shows local fallback subtitle when Firebase not ready',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    expect(find.textContaining('local fallback mode'), findsOneWidget);
  });

  // ---------------------------------------------------------------
  // Mode switching
  // ---------------------------------------------------------------

  testWidgets('switching to sign-up mode shows Full name field', (tester) async {
    await tester.pumpWidget(buildScreen());
    expect(find.widgetWithText(TextFormField, 'Full name'), findsNothing);

    await tester.tap(find.text('Sign up'));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Full name'), findsOneWidget);
  });

  testWidgets('switching to sign-up shows Confirm password field',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    expect(find.widgetWithText(TextFormField, 'Confirm password'), findsOneWidget);
  });

  testWidgets('switching back to log-in hides Full name field', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.widgetWithText(TextFormField, 'Full name'), findsNothing);
  });

  // ---------------------------------------------------------------
  // Email validation
  // ---------------------------------------------------------------

  testWidgets('shows error when email is empty on submit', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
  });

  testWidgets('shows error when email format is invalid', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  // ---------------------------------------------------------------
  // Password validation
  // ---------------------------------------------------------------

  testWidgets('shows error when password is too short', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'jane@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
  });

  // ---------------------------------------------------------------
  // Sign-up validation
  // ---------------------------------------------------------------

  testWidgets('shows error when name is empty in sign-up mode', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'jane@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'), 'secret123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Enter your name.'), findsOneWidget);
  });

  testWidgets('shows error when passwords do not match in sign-up',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'), 'Jane');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'jane@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'), 'different');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  // ---------------------------------------------------------------
  // Auth service errors
  // ---------------------------------------------------------------

  testWidgets('shows error message when sign-in fails', (tester) async {
    await tester.pumpWidget(buildScreen(signInError: 'Wrong password'));
    await enterLoginCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Wrong password'), findsOneWidget);
  });

  testWidgets('shows error message when sign-up fails', (tester) async {
    await tester.pumpWidget(buildScreen(signUpError: 'Email already in use'));
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'), 'Jane');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'jane@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'), 'secret123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Email already in use'), findsOneWidget);
  });

  testWidgets('switching mode clears the error message', (tester) async {
    await tester.pumpWidget(buildScreen(signInError: 'Wrong password'));
    await enterLoginCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Wrong password'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pump();
    expect(find.text('Wrong password'), findsNothing);
  });

  // ---------------------------------------------------------------
  // Sign-up shortcut
  // ---------------------------------------------------------------

  testWidgets('shows sign-up shortcut when error says please sign up first',
      (tester) async {
    await tester.pumpWidget(
        buildScreen(signInError: 'No account found. Please sign up first.'));
    await enterLoginCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await tester.pump();
    expect(find.text('No account? Sign up'), findsOneWidget);
  });

  testWidgets('sign-up shortcut switches to sign-up mode when tapped',
      (tester) async {
    await tester.pumpWidget(
        buildScreen(signInError: 'No account found. Please sign up first.'));
    await enterLoginCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.text('No account? Sign up'));
    await tester.tap(find.text('No account? Sign up'));
    await tester.pump();
    expect(find.widgetWithText(TextFormField, 'Full name'), findsOneWidget);
  });
}
