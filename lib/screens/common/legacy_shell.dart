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

class LegacyDestination {
  const LegacyDestination({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;
}

/// Desktop-style frame from the original browser app: top bar + side navigation.
/// On narrow screens the side navigation becomes a drawer. All surfaces are
/// frosted glass so the background photo stays visible.
class LegacyShell extends StatefulWidget {
  const LegacyShell({
    super.key,
    required this.user,
    required this.destinations,
    this.initialIndex = 0,
  });

  final AppUser user;
  final List<LegacyDestination> destinations;
  final int initialIndex;

  @override
  State<LegacyShell> createState() => _LegacyShellState();
}

class _LegacyShellState extends State<LegacyShell> {
  late int _index = widget.initialIndex;

  void _select(int index) {
    setState(() => _index = index);
    Navigator.of(context).maybePop(); // close the drawer on phones
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    final current = widget.destinations[_index];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: AppStyle.glass,
              title: Row(
                children: [
                  const ClamLogo(size: 28),
                  const SizedBox(width: 10),
                  const GradientText(
                    'AtClam',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [_accountMenu(), const NotificationBell()],
            ),
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: AppStyle.glassRaised,
              child: _navColumn(compact: false),
            ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _navColumn(compact: true),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(current.label),
                      Expanded(child: current.child),
                    ],
                  ),
                ),
              ],
            )
          : current.child,
    );
  }

  Widget _topBar(String title) => GlassCard(
        radius: 0,
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            const ClamLogo(size: 30),
            const SizedBox(width: 12),
            GradientText(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            _rolePill(),
            const SizedBox(width: 14),
            Text(
              widget.user.name,
              style: const TextStyle(color: AppColors.text, fontSize: 13),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.alpha(0x164C87, 0.7),
              child: Text(
                widget.user.name.isEmpty
                    ? '?'
                    : widget.user.name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            const NotificationBell(),
            _accountMenu(),
            AppButton(
              label: 'Log out',
              variant: AppButtonVariant.text,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onPressed: Session.instance.logout,
            ),
          ],
        ),
      );

  Widget _rolePill() => AppPill(
        widget.user.role.toUpperCase(),
        kind: AppPillKind.lime,
      );

  Widget _navColumn({required bool compact}) => GlassCard(
        radius: 0,
        blur: true,
        padding: EdgeInsets.zero,
        width: compact ? 236 : null,
        height: compact ? double.infinity : double.infinity,
        color: const Color(0xB306122A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact)
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0x33164C87)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const ClamLogo(size: 40),
                        const SizedBox(width: 10),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'AtClam\n',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: 'CLASSROOM ATTENDANCE',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(widget.user.name,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700)),
                    Text(widget.user.email,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              )
            else
              Container(
                height: 66,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppStyle.stroke,
                      width: AppStyle.strokeWidth,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const ClamLogo(size: 30),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'AtClam\n',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: 'CLASSROOM ATTENDANCE',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 8,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  color: AppColors.hint,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            ...List.generate(widget.destinations.length, (i) {
              final d = widget.destinations[i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: _NavTile(
                  label: d.label,
                  icon: d.icon,
                  active: i == _index,
                  onTap: () => _select(i),
                ),
              );
            }),
            const Spacer(),
            if (compact)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  radius: 12,
                  hover: true,
                  color: AppStyle.glassRaised,
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.ok),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attendance ready\nCamera and calendars are active.',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _accountMenu() => PopupMenuButton<String>(
        icon: const Icon(Icons.account_circle_outlined,
            color: AppColors.muted, size: 22),
        onSelected: (value) {
          if (value == 'password') {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen()));
          } else if (value == 'photos') {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const FaceRegistrationScreen()));
          } else if (value == 'server') {
            _showServerDialog(context);
          } else if (value == 'logout') {
            Session.instance.logout();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
              value: 'password', child: Text('Change password')),
          if (widget.user.isStudent)
            const PopupMenuItem(value: 'photos', child: Text('My face photos')),
          const PopupMenuItem(value: 'server', child: Text('Server address')),
          const PopupMenuItem(value: 'logout', child: Text('Log out')),
        ],
      );
}

/// Sidebar item with the active lime/gold gradient and a hover lift.
class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          transform: _hovered && !widget.active
              ? Matrix4.translationValues(3, 0, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: widget.active
                ? null
                : (_hovered
                    ? AppColors.alpha(0x5B9FE8, 0.1)
                    : Colors.transparent),
            gradient: widget.active ? AppStyle.activeGradient : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active
                  ? AppStyle.strokeHover
                  : (_hovered ? AppStyle.strokeRaised : AppStyle.strokeDeep),
              width: AppStyle.strokeWidth,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 19,
                  color: highlighted ? AppColors.lime : AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: highlighted ? AppColors.text : AppColors.muted,
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
              if (widget.active)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lime,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showServerDialog(BuildContext context) async {
  final controller = TextEditingController(text: AppConfig.apiBaseUrl);
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppStyle.glassRaised,
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
              'For a phone, use your computer’s LAN address, e.g. '
              'http://192.168.1.10:8000',
              style: TextStyle(color: AppColors.label, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
              controller: controller,
              label: 'Backend URL',
              icon: Icons.dns_outlined),
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
