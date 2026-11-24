import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import 'change_password_screen.dart';
import 'face_registration_screen.dart';

/// The original "My profile" page: identity, picture, details and password.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.text = Session.instance.user?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post('/auth/profile', body: {
        'name': _name.text.trim(),
        'school_id': Session.instance.user?.schoolId ?? '',
        'section': Session.instance.user?.section ?? '',
      });
      await Session.instance.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Name saved.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 900,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _busy = true);
    try {
      await ApiClient.instance
          .post('/auth/avatar', body: {'image': ApiClient.encodeImage(bytes)});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Picture updated.')));
        setState(() {}); // rebuild so the cache-busted URL refreshes
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user!;
    final avatar = '${AppConfig.apiBaseUrl}/avatars/${user.id}.jpg?v=$hashCode';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _PageTitle('My profile',
            subtitle: 'Manage your account details, picture and password.'),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final cards = <Widget>[
              _identityCard(user, avatar),
              _card(
                title: 'Profile picture',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A square image works best.',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Choose picture',
                      icon: Icons.upload,
                      variant: AppButtonVariant.tonal,
                      onPressed: _busy ? null : _uploadAvatar,
                    ),
                  ],
                ),
              ),
              _card(
                title: 'Account details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _name,
                      label: 'Full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _readOnly('Username', user.username),
                    const SizedBox(height: 12),
                    _readOnly('Email', user.email),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Save name',
                      icon: Icons.save_outlined,
                      onPressed: _busy ? null : _saveName,
                    ),
                  ],
                ),
              ),
              _card(
                title: 'Password',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Change your password regularly.',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Change password',
                      icon: Icons.lock_outline,
                      variant: AppButtonVariant.tonal,
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen())),
                    ),
                  ],
                ),
              ),
              if (user.isStudent)
                _card(
                  title: 'My face registration',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.hasFace
                            ? 'Your 3 photos are registered.'
                            : 'Add 3 photos so the camera can recognize you.',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: user.hasFace ? 'Update photos' : 'Add photos',
                        icon: Icons.face_retouching_natural,
                        variant: AppButtonVariant.tonal,
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const FaceRegistrationScreen())),
                      ),
                    ],
                  ),
                ),
            ];
            if (!wide) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...cards.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: c,
                        ))
                  ]);
            }
            final left = <Widget>[], right = <Widget>[];
            for (var i = 0; i < cards.length; i++) {
              (i.isEven ? left : right).add(Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: cards[i],
              ));
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: left)),
                const SizedBox(width: 14),
                Expanded(child: Column(children: right)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _identityCard(dynamic user, String avatar) => _card(
        title: user.name,
        subtitle: '${user.role} · @${user.username}',
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppStyle.strokeRaised,
                  width: AppStyle.strokeWidth,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  avatar,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppStyle.glassRaised,
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.lime,
                          fontSize: 28,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email,
                      style: const TextStyle(color: AppColors.text)),
                  const SizedBox(height: 8),
                  AppPill('${user.role}', kind: AppPillKind.lime),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _readOnly(String label, String value) => TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(color: AppColors.text),
        decoration: AppStyle.inputDecoration(label),
      );

  Widget _card({
    required String title,
    String? subtitle,
    required Widget child,
  }) =>
      GlassCard(
        width: double.infinity,
        hover: true,
        radius: 8,
        borderColor: AppStyle.stroke,
        hoverBorderColor: AppStyle.strokeRaised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: AppStyle.headingGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientText(
                    title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.white)),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _PageTitle extends StatelessWidget {
  const _PageTitle(this.title, {required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white)),
        ],
      );
}
