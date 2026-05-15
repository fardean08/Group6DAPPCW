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

