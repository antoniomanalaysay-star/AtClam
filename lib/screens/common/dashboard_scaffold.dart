import 'package:flutter/material.dart';

import '../../config.dart';
import '../../models/app_user.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/clam_logo.dart';
import 'change_password_screen.dart';
import 'face_registration_screen.dart';
import 'notifications_sheet.dart';

/// Shared frame for every dashboard: app bar with logo and an account menu.
class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottom,
  });

  final String title;
  final Widget body;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        backgroundColor: AppStyle.glassRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const ClamLogo(size: 30),
            const SizedBox(width: 10),
            GradientText(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        bottom: bottom,
        actions: [
          const NotificationBell(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            color: AppStyle.glassRaised,
            onSelected: (value) {
              if (value == 'password') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'photos') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FaceRegistrationScreen(),
                  ),
                );
              } else if (value == 'server') {
                _showServerDialog(context);
              } else if (value == 'logout') {
                Session.instance.logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'password', child: Text('Change password')),
              if (Session.instance.user?.isStudent ?? false)
                const PopupMenuItem(
                    value: 'photos', child: Text('My face photos')),
              const PopupMenuItem(
                  value: 'server', child: Text('Server address')),
              const PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: body,
    );
  }
}

/// Lets a real phone point at the computer running the Python backend.
Future<void> _showServerDialog(BuildContext context) async {
  final controller = TextEditingController(text: AppConfig.apiBaseUrl);
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const GradientText('Server address'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.alpha(0x5B9FE8, 0.08),
              borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
              border: Border.all(
                color: AppStyle.strokeRaised,
                width: AppStyle.strokeWidth,
              ),
            ),
            child: const Text(
              'Use your computer\'s LAN address when running the app on a phone, '
              'for example http://192.168.1.10:8000',
              style: TextStyle(color: AppColors.label, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: controller,
            label: 'Backend URL',
            icon: Icons.dns_outlined,
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppButton(
          label: 'Save',
          icon: Icons.save_outlined,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  if (saved == true) {
    await AppConfig.setBaseUrl(controller.text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Server address saved. Log in again to refresh.')));
    }
  }
}

/// "Welcome, name" card at the top of a dashboard.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.user, required this.roleLabel});

  final AppUser user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      roleLabel,
      if (user.schoolId != null) 'ID ${user.schoolId}',
      user.email,
    ];
    return GlassCard(
      hover: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              AvatarTile(user.name.isEmpty ? '?' : user.name, size: 54),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppStyle.strokeDeep,
                    width: 2,
                  ),
                ),
                child:
                    const Icon(Icons.star, size: 12, color: AppColors.ink900),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(
                  'Welcome, ${user.name}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final detail in details)
                      AppPill(
                        detail,
                        kind: detail == roleLabel
                            ? AppPillKind.gold
                            : AppPillKind.muted,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A feature card for something that is built in a later step.
class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      hover: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppStyle.activeGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppStyle.strokeRaised,
                    width: AppStyle.strokeWidth,
                  ),
                ),
                child: Icon(icon, color: AppColors.lime, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientText(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const AppPill('Coming next', kind: AppPillKind.gold),
            ],
          ),
          const SizedBox(height: 12),
          GlassTextPanel(
            padding: const EdgeInsets.all(10),
            child: Text(
              description,
              style: const TextStyle(color: AppColors.text, height: 1.45),
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 14),
            extra!,
          ],
        ],
      ),
    );
  }
}
