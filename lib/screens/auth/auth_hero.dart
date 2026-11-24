import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/clam_logo.dart';

/// The left-hand introduction panel from the original browser signup/login page.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.title,
    required this.description,
    required this.points,
    this.footer,
  });

  final String title;
  final String description;
  final List<String> points;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 0,
      height: double.infinity,
      blur: true,
      padding: EdgeInsets.zero,
      color: const Color(0xB304122A),
      hover: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const ClamLogo(size: 54),
                      const SizedBox(width: 14),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'AtClam\n',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: 'CLASSROOM ATTENDANCE',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  GradientText(
                    title,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassTextPanel(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ...points.asMap().entries.map(
                        (e) => _HeroPoint(number: e.key + 1, text: e.value),
                      ),
                  if (footer != null) ...[
                    const SizedBox(height: 24),
                    footer!,
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Feature line with a hover highlight, mirroring the numbered admin list.
class _HeroPoint extends StatefulWidget {
  const _HeroPoint({required this.number, required this.text});

  final int number;
  final String text;

  @override
  State<_HeroPoint> createState() => _HeroPointState();
}

class _HeroPointState extends State<_HeroPoint> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(_hovered ? 10 : 0),
        transform:
            _hovered ? Matrix4.translationValues(6, 0, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color:
              _hovered ? AppColors.alpha(0x5B9FE8, 0.09) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered ? AppStyle.strokeHover : AppStyle.stroke,
            width: AppStyle.strokeWidth,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '0${widget.number}',
              style: const TextStyle(
                color: AppColors.lime,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.text,
                style: TextStyle(
                  color: _hovered ? Colors.white : AppColors.text,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive wrapper: hero on the left for desktop, hidden on small screens.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.hero, required this.child});

  final Widget hero;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  SizedBox(width: 460, child: hero),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(48),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: GlassCard(
                            padding: const EdgeInsets.all(32),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ),
      ),
    );
  }
}
