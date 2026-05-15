import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/services/auth_service.dart';

/// Tests for [FirebaseAuthService] using an in-process Firebase Auth mock.
///
/// [MockFirebaseAuth] mirrors the FirebaseAuth API without a live project,
/// so these tests run entirely offline while exercising the real service
/// code paths (sign-up, sign-in, sign-out, authStateChanges mapping).
///
/// Test partitions:
///   - Sign-up returns AppUser with correct fields
///   - Sign-up emits user on authStateChanges
///   - Sign-in with correct credentials returns AppUser
///   - Sign-in emits user on authStateChanges
///   - Sign-out emits null on authStateChanges
///   - authStateChanges maps null Firebase user to null AppUser
void main() {
  group('FirebaseAuthService', () {
    // ---------------------------------------------------------------
    // Sign-up
    // ---------------------------------------------------------------

    group('signUp', () {
      test('returns AppUser with correct email and name', () async {
        final auth = FirebaseAuthService(
          firebaseAuth: MockFirebaseAuth(),
        );

        final user = await auth.signUp(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass123',
        );

        expect(user.email, 'alice@example.com');
        expect(user.name, 'Alice');
        expect(user.uid, isNotEmpty);
      });

      test('normalises email to lower case on sign-up', () async {
        final auth = FirebaseAuthService(
          firebaseAuth: MockFirebaseAuth(),
        );

        final user = await auth.signUp(
          name: 'Alice',
          email: 'ALICE@EXAMPLE.COM',
          password: 'pass123',
        );

        expect(user.email, 'alice@example.com');
      });

      test('authStateChanges emits signed-in user after sign-up', () async {
        final mockAuth = MockFirebaseAuth();
        final service = FirebaseAuthService(firebaseAuth: mockAuth);

        final future = service.authStateChanges.first;

        await service.signUp(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass123',
        );

        final emitted = await future;
        expect(emitted, isNotNull);
        expect(emitted!.email, 'alice@example.com');
      });
    });

    // ---------------------------------------------------------------
    // Sign-in
    // ---------------------------------------------------------------

    group('signIn', () {
      test('returns AppUser with correct fields on valid credentials',
          () async {
        final mockAuth = MockFirebaseAuth(
          mockUser: MockUser(
            uid: 'u1',
            email: 'bob@example.com',
            displayName: 'Bob',
          ),
          signedIn: false,
        );
        final service = FirebaseAuthService(firebaseAuth: mockAuth);

        final user = await service.signIn(
          email: 'bob@example.com',
          password: 'secret',
        );

        expect(user.email, 'bob@example.com');
        expect(user.name, 'Bob');
        expect(user.uid, 'u1');
      });

      test('authStateChanges emits signed-in user after sign-in', () async {
        final mockAuth = MockFirebaseAuth(
          mockUser: MockUser(
            uid: 'u1',
            email: 'bob@example.com',
            displayName: 'Bob',
          ),
          signedIn: false,
        );
        final service = FirebaseAuthService(firebaseAuth: mockAuth);

        final future = service.authStateChanges.first;

        await service.signIn(
          email: 'bob@example.com',
          password: 'secret',
        );

        final emitted = await future;
        expect(emitted, isNotNull);
        expect(emitted!.email, 'bob@example.com');
      });
    });

    // ---------------------------------------------------------------
    // Sign-out
    // ---------------------------------------------------------------

    group('signOut', () {
      test('authStateChanges emits null after sign-out', () async {
        final mockAuth = MockFirebaseAuth(
          mockUser: MockUser(
            uid: 'u1',
            email: 'carol@example.com',
            displayName: 'Carol',
          ),
          signedIn: true,
        );
        final service = FirebaseAuthService(firebaseAuth: mockAuth);

        final future = service.authStateChanges.first;
        await service.signOut();

        final emitted = await future;
        expect(emitted, isNull);
      });
    });

    // ---------------------------------------------------------------
    // authStateChanges mapping
    // ---------------------------------------------------------------

    group('authStateChanges', () {
      test('emits null when no user is signed in', () async {
        final service = FirebaseAuthService(
          firebaseAuth: MockFirebaseAuth(signedIn: false),
        );

        final user = await service.authStateChanges.first;
        expect(user, isNull);
      });

      test('emits AppUser when a user is already signed in', () async {
        final service = FirebaseAuthService(
          firebaseAuth: MockFirebaseAuth(
            mockUser: MockUser(
              uid: 'u2',
              email: 'dave@example.com',
              displayName: 'Dave',
            ),
            signedIn: true,
          ),
        );

        final user = await service.authStateChanges.first;
        expect(user, isNotNull);
        expect(user!.uid, 'u2');
        expect(user.email, 'dave@example.com');
        expect(user.name, 'Dave');
      });

      test('falls back to "User" display name when displayName is null',
          () async {
        final service = FirebaseAuthService(
          firebaseAuth: MockFirebaseAuth(
            mockUser: MockUser(
              uid: 'u3',
              email: 'anon@example.com',
            ),
            signedIn: true,
          ),
        );

        final user = await service.authStateChanges.first;
        expect(user!.name, 'User');
      });
    });
  });
}
