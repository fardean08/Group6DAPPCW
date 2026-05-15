import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Login and registration screen shown by [AuthGate] when no user is signed in.
///
/// Presents a [SegmentedButton] to switch between log-in and sign-up modes.
/// Validation, loading state, and error messages are all managed locally.
class AuthScreen extends StatefulWidget {
  /// Creates an [AuthScreen] backed by [authService].
  ///
  /// [firebaseReady] controls the subtitle text shown beneath the app name so
  /// the user knows whether real Firebase Auth or local fallback is active.
  const AuthScreen({
    super.key,
    required this.authService,
    required this.firebaseReady,
  });

  /// The service used to perform sign-in and sign-up operations.
  final AuthService authService;

  /// Whether Firebase was successfully initialised at startup.
  final bool firebaseReady;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// Returns true when the error message suggests the user needs to sign up,
  /// so that a shortcut button can be shown.
  bool get _showSignUpShortcut {
    if (_isSignUp || _errorMessage == null) {
      return false;
    }

    return _errorMessage!.toLowerCase().contains('please sign up first');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates the form and delegates to [AuthService.signUp] or
  /// [AuthService.signIn] depending on [_isSignUp].
  ///
  /// Sets [_isLoading] during the async call and populates [_errorMessage]
  /// on failure.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await widget.authService.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Switches between log-in and sign-up mode and clears any error message.
  void _switchMode(bool signUp) {
    setState(() {
      _isSignUp = signUp;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? 'Create your account' : 'Log in';
    final subtitle = widget.firebaseReady
        ? 'Firebase Authentication is connected.'
        : 'Firebase is not configured yet, so the app is using local fallback mode. Run flutterfire configure for real Firebase Auth.';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_parking, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        'Smart Parking Finder',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Log in'),
                            icon: Icon(Icons.login),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Sign up'),
                            icon: Icon(Icons.person_add),
                          ),
                        ],
                        selected: {_isSignUp},
                        onSelectionChanged: (values) {
                          _switchMode(values.first);
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 14),
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!_isSignUp) {
                              return null;
                            }

                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your name.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email address.';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (!_isSignUp) {
                              return null;
                            }

                            if (value != _passwordController.text) {
                              return 'Passwords do not match.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_errorMessage != null) ...[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                          ),
                        ),
                        if (_showSignUpShortcut) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _switchMode(true),
                              icon: const Icon(Icons.person_add),
                              label: const Text('No account? Sign up'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(_isSignUp ? Icons.person_add : Icons.login),
                          label: Text(_isSignUp ? 'Create account' : 'Log in'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create an account first. Log in only works for emails that have already been registered.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
