import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      await credentials.user?.updateDisplayName(name);

      return AppUser(
        uid: credentials.user!.uid,
        email: credentials.user!.email ?? normalizedEmail,
        name: name,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists. Log in instead.');
      }

      rethrow;
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final credentials = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credentials.user!;

      return AppUser(
        uid: user.uid,
        email: user.email ?? normalizedEmail,
        name: user.displayName ?? 'User',
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        throw Exception('No account exists for this email. Please sign up first.');
      }

      if (error.code == 'wrong-password' || error.code == 'invalid-credential') {
        throw Exception('Incorrect email or password.');
      }

      rethrow;
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  AppUser? _mapUser(firebase_auth.User? user) {
    if (user == null) {
      return null;
    }

    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? 'User',
    );
  }
}

class LocalAuthService implements AuthService {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  final Map<String, ({String name, String password})> _users = {};

  AppUser? _currentUser;

  LocalAuthService() {
    Future<void>.microtask(() => _controller.add(_currentUser));
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final lowerEmail = email.toLowerCase();

    if (_users.containsKey(lowerEmail)) {
      throw Exception('An account with this email already exists.');
    }

    _users[lowerEmail] = (name: name, password: password);

    _currentUser = AppUser(
      uid: lowerEmail,
      email: lowerEmail,
      name: name,
    );

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final lowerEmail = email.toLowerCase();
    final user = _users[lowerEmail];

    if (user == null) {
      throw Exception('No account exists for this email. Please sign up first.');
    }

    if (user.password != password) {
      throw Exception('Incorrect email or password.');
    }

    _currentUser = AppUser(
      uid: lowerEmail,
      email: lowerEmail,
      name: user.name,
    );

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
