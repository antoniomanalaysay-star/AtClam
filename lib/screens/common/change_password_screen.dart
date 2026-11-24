import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../utils/validators.dart';
import '../../widgets/app_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post('/auth/change-password', body: {
        'old_password': _old.text,
        'new_password': _new.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed')),
      );
      Navigator.of(context).pop();
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
          'Change password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppPill('SECURITY',
                            kind: AppPillKind.gold,
                            icon: Icons.shield_outlined),
                      ),
                      const SizedBox(height: 12),
                      const GradientText(
                        'Update your password',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose a strong password you have not used before.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _old,
                        label: 'Current password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) => requiredField(v, 'Current password'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _new,
                        label: 'New password',
                        icon: Icons.lock_reset,
                        obscure: true,
                        textInputAction: TextInputAction.next,
                        validator: passwordField,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirm,
                        label: 'Confirm new password',
                        icon: Icons.lock_reset,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _submit,
                        validator: (v) =>
                            v != _new.text ? 'Passwords do not match' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        ErrorBanner(_error!),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Save new password',
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
