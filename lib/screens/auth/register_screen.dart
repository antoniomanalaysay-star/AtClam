import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../utils/validators.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/server_address_field.dart';
import 'auth_hero.dart';

/// Old-style signup: choose Student or Instructor, then continue.
/// Students add their 3 face photos here; instructors skip that step.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final List<Uint8List?> _photos = [null, null, null];

  String _role = 'student';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _username, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _photos[index] = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'student' && _photos.any((p) => p == null)) {
      setState(() => _error = 'Please choose 3 face photos.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Session.instance.register(
        name: _name.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
      );
      if (_role == 'student') {
        await ApiClient.instance.post('/auth/photos', body: {
          'photos': _photos
              .whereType<Uint8List>()
              .map((b) => ApiClient.encodeImage(b))
              .toList(),
        });
        await Session.instance.refresh();
      }
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      hero: const AuthHero(
        title: 'Join the classroom\nwith your own workspace',
        description:
            'Students get a personal attendance calendar. Instructors create '
            'classes, share codes and use the live camera roster.',
        points: [
          'Pick Student or Instructor',
          'Students add 3 face photos',
          'Instructors skip face setup',
          'Land on your own dashboard',
        ],
        footer: Text(
          'Already registered? Log in from the previous screen.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GradientText(
              'Create your account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us who you are. You’ll go straight to your workspace.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            _rolePicker(),
            const SizedBox(height: 20),
            AppTextField(
              controller: _name,
              label: 'Full name',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredField(v, 'Full name'),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _username,
              label: 'Username',
              icon: Icons.alternate_email,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Username is required';
                if (value.contains(RegExp(r'\s'))) {
                  return 'Username cannot contain spaces';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: emailField,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
              textInputAction: TextInputAction.next,
              validator: passwordField,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _confirm,
              label: 'Confirm password',
              icon: Icons.lock_outline,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 18),
            if (_role == 'student') _photoSlots() else _instructorNote(),
            const ServerAddressField(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(_error!),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Sign up & continue',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: AppColors.muted)),
                AppButton(
                  label: 'Log in',
                  variant: AppButtonVariant.text,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rolePicker() => Row(
        children: [
          Expanded(
            child: _roleButton(
              'student',
              Icons.school_outlined,
              'Student',
              'View my attendance',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _roleButton(
              'instructor',
              Icons.person_outline,
              'Instructor',
              'Create & manage classes',
            ),
          ),
        ],
      );

  Widget _roleButton(String value, IconData icon, String label, String sub) {
    return _RoleCard(
      icon: icon,
      label: label,
      sub: sub,
      selected: _role == value,
      onTap: () => setState(() => _role = value),
    );
  }

  Widget _photoSlots() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registration photos (3 required)',
              style: TextStyle(
                  color: AppColors.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Front, left and right views let the camera recognize you.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
                3,
                (i) => Expanded(
                      child: _PhotoSlot(
                        label: ['Front', 'Left', 'Right'][i],
                        bytes: _photos[i],
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        onTap: () => _pickPhoto(i),
                      ),
                    )),
          ),
        ],
      );

  Widget _instructorNote() => GlassCard(
        radius: AppStyle.radiusSmall,
        color: const Color(0xB304122A),
        padding: const EdgeInsets.all(14),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.lime, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Instructors don’t need face photos. You can create classes '
                'and take attendance right away.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

/// Selectable role card with the lime/gold gradient on selection and a
/// gentle hover lift.
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          padding: const EdgeInsets.all(14),
          transform: _hovered
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: widget.selected
                ? null
                : (_hovered
                    ? const Color(0xB304122A)
                    : const Color(0x9909182F)),
            gradient: widget.selected ? AppStyle.activeGradient : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected || _hovered
                  ? AppStyle.strokeHover
                  : AppStyle.strokeRaised,
              width: widget.selected
                  ? AppStyle.strokeWidth + 0.4
                  : AppStyle.strokeWidth,
            ),
            boxShadow: _hovered ? AppStyle.hoverShadow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon,
                      size: 20,
                      color: active ? AppColors.lime : AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.label,
                        style: TextStyle(
                          color: active ? AppColors.text : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                  if (widget.selected)
                    const Icon(Icons.check_circle,
                        size: 18, color: AppColors.lime),
                ],
              ),
              const SizedBox(height: 6),
              Text(widget.sub,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 11, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo upload slot with a hover glow and a lime border once filled.
class _PhotoSlot extends StatefulWidget {
  const _PhotoSlot({
    required this.label,
    required this.bytes,
    required this.margin,
    required this.onTap,
  });

  final String label;
  final Uint8List? bytes;
  final EdgeInsetsGeometry margin;
  final VoidCallback onTap;

  @override
  State<_PhotoSlot> createState() => _PhotoSlotState();
}

class _PhotoSlotState extends State<_PhotoSlot> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.bytes != null || _hovered
        ? AppStyle.strokeHover
        : AppStyle.strokeRaised;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          height: 92,
          margin: widget.margin,
          transform: _hovered
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: const Color(0xB304122A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: AppStyle.strokeWidth),
            boxShadow: _hovered ? AppStyle.hoverShadow : null,
          ),
          child: widget.bytes == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: _hovered ? AppColors.lime : AppColors.muted,
                        size: 24),
                    const SizedBox(height: 6),
                    Text(widget.label,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11)),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.memory(widget.bytes!, fit: BoxFit.cover),
                ),
        ),
      ),
    );
  }
}
