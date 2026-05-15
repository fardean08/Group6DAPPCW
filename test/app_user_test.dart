import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/app_user.dart';

/// Tests for [AppUser] model.
///
/// Test partitions:
///   - Field storage          -> each field holds the value it was given
///   - Const construction     -> can be used as a compile-time constant
///   - Instance independence  -> two instances do not share state
///   - Boundary: empty strings -> accepted without error
///   - Boundary: long strings  -> accepted without truncation
void main() {
  group('AppUser', () {
    const user = AppUser(
      uid: 'abc-123',
      email: 'alice@example.com',
      name: 'Alice Smith',
    );

    test('stores uid correctly', () {
      expect(user.uid, 'abc-123');
    });

    test('stores email correctly', () {
      expect(user.email, 'alice@example.com');
    });

    test('stores name correctly', () {
      expect(user.name, 'Alice Smith');
    });

    test('can be constructed as a compile-time constant', () {
      const other = AppUser(uid: 'xyz', email: 'bob@example.com', name: 'Bob');
      expect(other.uid, 'xyz');
      expect(other.email, 'bob@example.com');
      expect(other.name, 'Bob');
    });

    test('two instances with different values are independent', () {
      const user1 = AppUser(uid: 'u1', email: 'a@a.com', name: 'A');
      const user2 = AppUser(uid: 'u2', email: 'b@b.com', name: 'B');

      expect(user1.uid, isNot(equals(user2.uid)));
      expect(user1.email, isNot(equals(user2.email)));
      expect(user1.name, isNot(equals(user2.name)));
    });

    test('accepts empty strings for all fields', () {
      const empty = AppUser(uid: '', email: '', name: '');

      expect(empty.uid, isEmpty);
      expect(empty.email, isEmpty);
      expect(empty.name, isEmpty);
    });

    test('preserves long string values without truncation', () {
      final longUid = 'u' * 128;
      final longEmail = '${'a' * 60}@example.com';
      final longName = 'Name ' * 20;

      final u = AppUser(uid: longUid, email: longEmail, name: longName);

      expect(u.uid, longUid);
      expect(u.email, longEmail);
      expect(u.name, longName);
    });
  });
}
