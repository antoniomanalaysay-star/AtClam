import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Sends the new account to the backend.
/// Return `null` on success, or an error message to show the user.
typedef RegisterSubmit = Future<String?> Function(
  String username,
  String email,
  String password,
  UserRole requestedRole,
);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.onSubmit,
    this.onRegistered,
    this.onGoToLogin,
  });

  /// Real sign-up call. While this is null the screen is a DESIGN PREVIEW only.
  final RegisterSubmit? onSubmit;

  /// Called after [onSubmit] succeeds. Defaults to opening [LoginScreen].
  final VoidCallback? onRegistered;

  /// Defaults to opening [LoginScreen].
  final VoidCallback? onGoToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  UserRole _role = UserRole.student;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter a username.';
    if (v.length < 3) return 'Username must be at least 3 characters.';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password.';
    if (value.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != _password.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final submit = widget.onSubmit;
    if (submit == null) {
      setState(() => _error =
          'Design preview only: sign-up is not connected to the backend yet. '
          'No account was created.');
      return;
    }

    setState(() => _loading = true);
    String? error;
    try {
      error = await submit(
        _username.text.trim(),
        _email.text.trim(),
        _password.text,
        _role,
      );
    } catch (_) {
      error = 'Could not reach the server. Please try again.';
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
    if (error != null) return;

    final custom = widget.onRegistered;
    if (custom != null) {
      custom();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(
            successMessage: 'Account created! Please log in.',
          ),
        ),
      );
    }
  }

  void _goToLogin() {
    final custom = widget.onGoToLogin;
    if (custom != null) {
      custom();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      headlinePrefix: 'Join your ',
      headlineAccent: 'classroom',
      description:
          'Create an account to start tracking and viewing attendance.',
      tileIcons: const [
        Icons.groups_outlined,
        Icons.how_to_reg_outlined,
        Icons.chat_bubble_outline,
        Icons.school_outlined,
        Icons.face_retouching_natural_outlined,
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const GlowingLogo(size: 52),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthWordmark(fontSize: 18, letterSpacing: 0.6),
                    SizedBox(height: 2),
                    Text(
                      'Classroom Attendance',
                      style: TextStyle(fontSize: 11, color: AuthColors.muted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Create account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF3FAF3),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign up to access your AT CLAM dashboard.',
              style: TextStyle(fontSize: 13, color: AuthColors.muted),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              AuthBanner(message: _error!, kind: AuthBannerKind.error),
            RoleSelector(
              selected: _role,
              roles: const [UserRole.student, UserRole.instructor],
              onChanged: (role) => setState(() => _role = role),
            ),
            const SizedBox(height: 4),
            const Text(
              'Admin accounts cannot be created here.',
              style: TextStyle(fontSize: 11, color: AuthColors.muted),
            ),
            AuthTextField(
              controller: _username,
              label: 'Username',
              hint: 'Username',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              validator: _validateUsername,
            ),
            AuthTextField(
              controller: _email,
              label: 'Email',
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            AuthTextField(
              controller: _password,
              label: 'Password',
              hint: 'Password',
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validatePassword,
            ),
            AuthTextField(
              controller: _confirm,
              label: 'Confirm Password',
              hint: 'Confirm Password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: _validateConfirm,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AuthButton(
                label: 'Register', loading: _loading, onPressed: _submit),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 13, color: AuthColors.muted),
                ),
                InkWell(
                  onTap: _goToLogin,
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AuthColors.lime,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}