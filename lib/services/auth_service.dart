import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Interface for sign-in, sign-up, and sign-out.
///
/// Two implementations: [FirebaseAuthService] for production and
/// [PersistentLocalAuthService] as a fallback when Firebase isn't configured.
abstract class AuthService {
  /// Stream of the current user. Emits null when signed out.
  Stream<AppUser?> get authStateChanges;

  /// Creates a new account. Throws if the email is already registered.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Signs in an existing user. Throws if credentials are wrong.
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

/// [AuthService] backed by Firebase Authentication.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  /// Creates a Firebase account and sets the display name. Email is lowercased first.
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

  /// Signs in and returns the user. Translates Firebase error codes into readable messages.
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

  // Maps a Firebase user to AppUser, or null if signed out
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

/// In-memory auth service used in tests. State is lost when the object is disposed.
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

  /// Registers a new in-memory account.
  ///
  /// Email is normalised to lower case. Throws if the email is already taken.
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

  /// Signs in to an existing in-memory account.
  ///
  /// Throws if the email is not registered or the password does not match.
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

/// Persists accounts and session in SharedPreferences so sign-in survives restarts.
/// Used automatically when Firebase isn't available.
class PersistentLocalAuthService implements AuthService {
  static const _usersKey = 'local_users';
  static const _sessionKey = 'local_session';

  final _controller = StreamController<AppUser?>.broadcast();
  final Map<String, ({String name, String password})> _users = {};
  AppUser? _currentUser;

  /// Creates a [PersistentLocalAuthService] and immediately begins loading
  /// saved credentials from [SharedPreferences].
  PersistentLocalAuthService() {
    _load();
  }

  /// Reads persisted users and session from [SharedPreferences].
  ///
  /// Emits the restored [AppUser] (or null) on [authStateChanges] once
  /// loading is complete.
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

  /// Serialises [_users] and optionally the active [session] email to
  /// [SharedPreferences].
  ///
  /// Passing `null` for [session] removes the session key (sign-out).
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

  /// Creates a persisted account and saves the session.
  ///
  /// Throws if the email is already registered.
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

  /// Signs in to a persisted account and saves the session.
  ///
  /// Throws if the email is not registered or the password is incorrect.
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

  /// Signs out and removes the active session from [SharedPreferences].
  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _save(session: null);
    _controller.add(null);
  }
}
