import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../utils/validators.dart';
import '../../widgets/app_widgets.dart';

/// Admin creates an instructor account and picks a first password.
/// Pops with `true` when the account was created.
class AddInstructorScreen extends StatefulWidget {
  const AddInstructorScreen({super.key});

  @override
  State<AddInstructorScreen> createState() => _AddInstructorScreenState();
}

class _AddInstructorScreenState extends State<AddInstructorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _schoolId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _schoolId.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post('/admin/instructors', body: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'school_id':
            _schoolId.text.trim().isEmpty ? null : _schoolId.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Instructor account created for ${_name.text.trim()}')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const GradientText(
          'Add instructor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GlassCard(
                hover: true,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const GradientText(
                        'Instructor details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create an account and hand the first password to the instructor.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      const AppPill(
                        'Admin action',
                        kind: AppPillKind.gold,
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppStyle.stroke, height: 1),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _name,
                        label: 'Full name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) => requiredField(v, 'Name'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _schoolId,
                        label: 'School ID (optional)',
                        icon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: emailField,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _password,
                        label: 'First password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _submit,
                        validator: passwordField,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Give this password to the instructor. They can change '
                        'it from the account menu after logging in.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        ErrorBanner(_error!),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Create instructor account',
                        loading: _loading,
                        onPressed: _submit,
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
