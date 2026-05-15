import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/services/auth_service.dart';

/// Tests for [LocalAuthService].
///
/// Firebase Authentication cannot be unit-tested without a live Firebase
/// project, so these tests cover the [LocalAuthService] implementation
/// which uses the same interface and mirrors the same business rules.
///
/// Test partitions (equivalence classes):
///   - Valid credentials (happy path)
///   - Duplicate email (sign-up boundary)
///   - Wrong password (sign-in boundary)
///   - Unregistered email (sign-in boundary)
///   - Sign-out state reset
void main() {
  group('LocalAuthService', () {
    late LocalAuthService service;

    setUp(() {
      service = LocalAuthService();
    });

    // ---------------------------------------------------------------
    // Sign-up
    // ---------------------------------------------------------------

    group('signUp', () {
      test('returns AppUser with correct fields on valid sign-up', () async {
        final user = await service.signUp(
          name: 'Jane Smith',
          email: 'jane@example.com',
          password: 'securepass',
        );

        expect(user.name, 'Jane Smith');
        expect(user.email, 'jane@example.com');
        expect(user.uid, isNotEmpty);
      });

      test('emits the new user on authStateChanges after sign-up', () async {
        await service.signUp(
          name: 'Jane Smith',
          email: 'jane@example.com',
          password: 'securepass',
        );

        final user = await service.authStateChanges.first;
        expect(user, isNotNull);
        expect(user!.email, 'jane@example.com');
      });

      test('throws when email is already registered', () async {
        await service.signUp(
          name: 'Jane Smith',
          email: 'jane@example.com',
          password: 'securepass',
        );

        expect(
          () => service.signUp(
            name: 'Jane Again',
            email: 'jane@example.com',
            password: 'otherpass',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('email comparison is case-insensitive', () async {
        await service.signUp(
          name: 'Jane Smith',
          email: 'Jane@Example.com',
          password: 'securepass',
        );

        expect(
          () => service.signUp(
            name: 'Jane Smith',
            email: 'jane@example.com',
            password: 'securepass',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('multiple different users can sign up independently', () async {
        final user1 = await service.signUp(
          name: 'Alice',
          email: 'alice@example.com',
          password: 'pass1',
        );

        final user2 = await service.signUp(
          name: 'Bob',
          email: 'bob@example.com',
          password: 'pass2',
        );

        expect(user1.email, isNot(equals(user2.email)));
      });
    });

 // ---------------------------------------------------------------
    // Sign-in
    // ---------------------------------------------------------------
 
    group('signIn', () {
      setUp(() async {
        await service.signUp(
          name: 'Jane Smith',
          email: 'jane@example.com',
          password: 'securepass',
        );
        await service.signOut();
      });
 
      test('returns AppUser with correct fields on valid credentials', () async {
        final user = await service.signIn(
          email: 'jane@example.com',
          password: 'securepass',
        );
 
        expect(user.name, 'Jane Smith');
        expect(user.email, 'jane@example.com');
      });
 
      test('emits user on authStateChanges after sign-in', () async {
        await service.signIn(
          email: 'jane@example.com',
          password: 'securepass',
        );
 
        final user = await service.authStateChanges.first;
        expect(user, isNotNull);
      });
 
      test('throws on unregistered email', () async {
        expect(
          () => service.signIn(
            email: 'nobody@example.com',
            password: 'securepass',
          ),
          throwsA(isA<Exception>()),
        );
      });
 
      test('throws on wrong password', () async {
        expect(
          () => service.signIn(
            email: 'jane@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<Exception>()),
        );
      });
 
      test('sign-in is case-insensitive for email', () async {
        final user = await service.signIn(
          email: 'JANE@EXAMPLE.COM',
          password: 'securepass',
        );
 
        expect(user.email, 'jane@example.com');
      });
    });
 
    // ---------------------------------------------------------------
    // Sign-out
    // ---------------------------------------------------------------
 
    group('signOut', () {
      test('emits null on authStateChanges after sign-out', () async {
        await service.signUp(
          name: 'Jane Smith',
          email: 'jane@example.com',
          password: 'securepass',
        );
 
        await service.signOut();
 
        final user = await service.authStateChanges.first;
        expect(user, isNull);
      });
 
      test('user can sign in again after sign-out', () async {
        await service.signUp(
          name: 'Jane Smith',
          email: 'jane@example.com',
          password: 'securepass',
        );
 
        await service.signOut();
 
        final user = await service.signIn(
          email: 'jane@example.com',
          password: 'securepass',
        );
 
        expect(user.name, 'Jane Smith');
      });
    });
  });
}
 