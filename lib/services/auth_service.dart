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

class PersistentLocalAuthService implements AuthService {
  static const _usersKey = 'local_users';
  static const _sessionKey = 'local_session';

  final _controller = StreamController<AppUser?>.broadcast();
  final Map<String, ({String name, String password})> _users = {};
  AppUser? _currentUser;

  PersistentLocalAuthService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in map.entries) {
        final v = e.value as Map<String, dynamic>;
        _users[e.key] = (name: v['name'] as String, password: v['password'] as String);
      }
    }
    final email = prefs.getString(_sessionKey);
    if (email != null && _users.containsKey(email)) {
      _currentUser = AppUser(uid: email, email: email, name: _users[email]!.name);
    }
    _controller.add(_currentUser);
  }

  Future<void> _save({required String? session}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode({
      for (final e in _users.entries)
        e.key: {'name': e.value.name, 'password': e.value.password},
    }));
    if (session == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, session);
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser> signUp({required String name, required String email, required String password}) async {
    final key = email.toLowerCase();
    if (_users.containsKey(key)) {
      throw Exception('An account with this email already exists.');
    }
    _users[key] = (name: name, password: password);
    _currentUser = AppUser(uid: key, email: key, name: name);
    await _save(session: key);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final key = email.toLowerCase();
    final user = _users[key];
    if (user == null) throw Exception('No account exists for this email. Please sign up first.');
    if (user.password != password) throw Exception('Incorrect email or password.');
    _currentUser = AppUser(uid: key, email: key, name: user.name);
    await _save(session: key);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _save(session: null);
    _controller.add(null);
  }
}
