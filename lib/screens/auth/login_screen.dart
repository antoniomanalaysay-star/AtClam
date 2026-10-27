import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../admin/admin_dashboard.dart';
import '../instructor/instructor_dashboard.dart';
import '../student/student_dashboard.dart';
import 'register_screen.dart';

// ---------------------------------------------------------------------------
// Shared auth UI (colors, logo, split layout, fields). register_screen.dart
// imports this file and reuses these widgets.
// ---------------------------------------------------------------------------

/// Green / yellow palette used by the login and sign-up screens.
class AuthColors {
  AuthColors._();

  static const ink900 = Color(0xFF04100A); // deepest background
  static const ink800 = Color(0xFF071A10); // form panel
  static const ink700 = Color(0xFF0A2415); // input fill

  static const line = Color(0xFF1D5236); // borders
  static const leaf = Color(0xFF4CAF50);
  static const lime = Color(0xFFA8E063);
  static const forest = Color(0xFF1F7A43);
  static const gold = Color(0xFFF5C518);
  static const goldHi = Color(0xFFFFE066);

  static const text = Color(0xFFE7F3E9);
  static const muted = Color(0xFF8FAE99);
  static const label = Color(0xFF9CC4A8);
  static const hint = Color(0xFF5D7A68);

  /// Colour from an RGB hex value (e.g. 0xF5C518) with an alpha from 0 to 1.
  static Color alpha(int rgb, double a) =>
      Color(0xFF000000 | rgb).withAlpha((a * 255).round());
}

/// The hexagon shield + graduation cap logo, drawn in code (no image file).
class ClamLogo extends StatelessWidget {
  const ClamLogo({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _ClamLogoPainter()),
    );
  }
}

class _ClamLogoPainter extends CustomPainter {
  const _ClamLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);

    // Outer hex shield with gradient ring.
    final ring = Path()
      ..moveTo(60, 4)
      ..lineTo(108, 30)
      ..lineTo(108, 76)
      ..lineTo(60, 116)
      ..lineTo(12, 76)
      ..lineTo(12, 30)
      ..close();
    canvas.drawPath(
      ring,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE56B), Color(0xFFB9E04B), Color(0xFF1F7A43)],
          stops: [0, 0.42, 1],
        ).createShader(ring.getBounds()),
    );

    // Inner dark hex.
    final inner = Path()
      ..moveTo(60, 15)
      ..lineTo(98, 36)
      ..lineTo(98, 71)
      ..lineTo(60, 104)
      ..lineTo(22, 71)
      ..lineTo(22, 36)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFF05130C));

    // Graduation cap top.
    final cap = Path()
      ..moveTo(60, 34)
      ..lineTo(92, 47)
      ..lineTo(60, 60)
      ..lineTo(28, 47)
      ..close();
    canvas.drawPath(
      cap,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE98A), Color(0xFFF5C518)],
        ).createShader(cap.getBounds()),
    );

    // Cap band.
    final band = Path()
      ..moveTo(39, 52.5)
      ..lineTo(39, 66)
      ..cubicTo(39, 71.2, 48.4, 74.8, 60, 74.8)
      ..cubicTo(71.6, 74.8, 81, 71.2, 81, 66)
      ..lineTo(81, 52.5);
    canvas.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF8FD14F),
    );

    // Tassel.
    const tassel = Color(0xFFFFD93D);
    canvas.drawLine(
      const Offset(92, 47),
      const Offset(92, 62),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = tassel,
    );
    canvas.drawCircle(const Offset(92, 66), 4, Paint()..color = tassel);

    // Connection nodes.
    final nodes = Path()
      ..moveTo(45, 83)
      ..lineTo(60, 92)
      ..lineTo(75, 83);
    canvas.drawPath(
      nodes,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AuthColors.alpha(0xA8E063, 0.95),
    );
    canvas.drawCircle(
        const Offset(45, 83), 4.4, Paint()..color = AuthColors.gold);
    canvas.drawCircle(
        const Offset(60, 92), 5, Paint()..color = AuthColors.lime);
    canvas.drawCircle(
        const Offset(75, 83), 4.4, Paint()..color = AuthColors.gold);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The logo with a softly pulsing yellow/green glow behind it.
class GlowingLogo extends StatefulWidget {
  const GlowingLogo({super.key, this.size = 100});

  final double size;

  @override
  State<GlowingLogo> createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<GlowingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -s * 0.24,
            top: -s * 0.24,
            width: s * 1.48,
            height: s * 1.48,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_controller.value);
                return Opacity(
                  opacity: 0.75 + 0.25 * t,
                  child: Transform.scale(
                    scale: 1 + 0.06 * t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AuthColors.alpha(0xF5C518, 0.30),
                            AuthColors.alpha(0xA8E063, 0.12),
                            AuthColors.alpha(0xA8E063, 0),
                          ],
                          stops: const [0, 0.5, 1],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(child: ClamLogo(size: s)),
        ],
      ),
    );
  }
}

/// Split-screen layout shared by the login and sign-up screens.
///
/// Wide screens: animated artwork on the left, form on the right.
/// Narrow screens: a short artwork banner on top, form below.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.headlinePrefix,
    required this.headlineAccent,
    this.headlineSuffix = '.',
    required this.description,
    required this.tileIcons,
    required this.child,
  });

  /// Caption shown on the artwork, e.g. "Stay connected on " + "campus" + ".".
  final String headlinePrefix;
  final String headlineAccent;
  final String headlineSuffix;
  final String description;

  /// Five icons for the floating tiles.
  final List<IconData> tileIcons;

  /// The form content.
  final Widget child;

  static const double breakpoint = 860;
  static const double _compactArtHeight = 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.ink900,
      body: LayoutBuilder(
        builder: (context, box) {
          final art = _ArtPanel(
            compact: box.maxWidth < breakpoint,
            headlinePrefix: headlinePrefix,
            headlineAccent: headlineAccent,
            headlineSuffix: headlineSuffix,
            description: description,
            tileIcons: tileIcons,
          );

          if (box.maxWidth >= breakpoint) {
            return Row(
              children: [
                Expanded(flex: 58, child: art),
                Expanded(
                  flex: 42,
                  child: _WideFormPanel(child: child),
                ),
              ],
            );
          }

          final formMinHeight =
              math.max(0.0, box.maxHeight - _compactArtHeight);
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: _compactArtHeight, child: art),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: formMinHeight),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: const BoxDecoration(
                    color: AuthColors.ink800,
                    border: Border(top: BorderSide(color: AuthColors.line)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WideFormPanel extends StatelessWidget {
  const _WideFormPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuthColors.ink800,
        border: Border(left: BorderSide(color: AuthColors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0.0, box.maxHeight - 96),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Artwork panel
// ---------------------------------------------------------------------------

enum _FloaterKind { logo, tile, goldTile }

class _FloaterSpec {
  const _FloaterSpec({
    required this.kind,
    required this.fx,
    required this.fy,
    required this.size,
    required this.opacity,
    required this.periodSec,
    required this.phase,
    this.tileIndex = 0,
    this.showWhenCompact = true,
  });

  final _FloaterKind kind;
  final double fx; // left, as a fraction of panel width
  final double fy; // top, as a fraction of panel height
  final double size;
  final double opacity;
  final int periodSec; // must divide 60 so the loop is seamless
  final double phase;
  final int tileIndex;
  final bool showWhenCompact;
}

const _floaters = <_FloaterSpec>[
  _FloaterSpec(kind: _FloaterKind.logo, fx: .11, fy: .16, size: 86, opacity: .68, periodSec: 15, phase: 0),
  _FloaterSpec(kind: _FloaterKind.tile, fx: .30, fy: .44, size: 46, opacity: .45, periodSec: 20, phase: 1.2, tileIndex: 0),
  _FloaterSpec(kind: _FloaterKind.goldTile, fx: .66, fy: .30, size: 54, opacity: .48, periodSec: 20, phase: 2.4, tileIndex: 1),
  _FloaterSpec(kind: _FloaterKind.tile, fx: .19, fy: .63, size: 38, opacity: .36, periodSec: 30, phase: 3.1, tileIndex: 2, showWhenCompact: false),
  _FloaterSpec(kind: _FloaterKind.logo, fx: .73, fy: .56, size: 62, opacity: .46, periodSec: 30, phase: 4.0, showWhenCompact: false),
  _FloaterSpec(kind: _FloaterKind.tile, fx: .45, fy: .09, size: 42, opacity: .40, periodSec: 20, phase: 5.0, tileIndex: 3),
  _FloaterSpec(kind: _FloaterKind.logo, fx: .47, fy: .74, size: 46, opacity: .30, periodSec: 60, phase: 5.8, showWhenCompact: false),
  _FloaterSpec(kind: _FloaterKind.goldTile, fx: .84, fy: .22, size: 40, opacity: .34, periodSec: 30, phase: 0.7, tileIndex: 4, showWhenCompact: false),
];

class _ArtPanel extends StatefulWidget {
  const _ArtPanel({
    required this.compact,
    required this.headlinePrefix,
    required this.headlineAccent,
    required this.headlineSuffix,
    required this.description,
    required this.tileIcons,
  });

  final bool compact;
  final String headlinePrefix;
  final String headlineAccent;
  final String headlineSuffix;
  final String description;
  final List<IconData> tileIcons;

  @override
  State<_ArtPanel> createState() => _ArtPanelState();
}

class _ArtPanelState extends State<_ArtPanel>
    with SingleTickerProviderStateMixin {
  // One 60-second clock drives every floating item.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Widget _buildFloater(_FloaterSpec f, double w, double h) {
    final angle =
        2 * math.pi * _clock.value * (60 / f.periodSec) + f.phase;
    final dx = 18 * math.sin(angle);
    final dy = -24 * math.sin(angle + 1);
    final rot = 0.08 * math.sin(angle);

    final size = (widget.compact && f.size > 60) ? 60.0 : f.size;

    Widget content;
    if (f.kind == _FloaterKind.logo) {
      content = ClamLogo(size: size);
    } else {
      final gold = f.kind == _FloaterKind.goldTile;
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: gold
              ? AuthColors.alpha(0xF5C518, 0.12)
              : AuthColors.alpha(0x4CAF50, 0.12),
          border: Border.all(
            color: gold
                ? AuthColors.alpha(0xFFE066, 0.30)
                : AuthColors.alpha(0xA8E063, 0.26),
          ),
        ),
        child: Icon(
          widget.tileIcons[f.tileIndex % widget.tileIcons.length],
          size: size * 0.55,
          color: gold ? const Color(0xFFFFE9A3) : const Color(0xFFD6F2C4),
        ),
      );
    }

    return Positioned(
      left: w * f.fx,
      top: h * f.fy,
      child: Opacity(
        opacity: f.opacity,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(angle: rot, child: content),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final moonSize = compact ? 110.0 : 220.0;

    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF04100A), Color(0xFF07200F), Color(0xFF0E3A1F)],
            stops: [0, 0.42, 1],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _SceneryPainter()),
                ),

                // Glowing logo "sun" + floating items (animated together).
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _clock,
                    builder: (context, _) {
                      final a = 2 * math.pi * _clock.value * 3; // 20 s loop
                      final s = (1 - math.cos(a)) / 2;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: h * 0.08 + 16 * s,
                            right: w * (compact ? 0.08 : 0.13) + 12 * s,
                            width: moonSize,
                            height: moonSize,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: -moonSize * 0.2,
                                  top: -moonSize * 0.2,
                                  width: moonSize * 1.4,
                                  height: moonSize * 1.4,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AuthColors.alpha(0xF5C518, 0.20),
                                          AuthColors.alpha(0xA8E063, 0.10),
                                          AuthColors.alpha(0xA8E063, 0),
                                        ],
                                        stops: const [0, 0.5, 1],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.5,
                                    child: ClamLogo(size: moonSize),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final f in _floaters)
                            if (!compact || f.showWhenCompact)
                              _buildFloater(f, w, h),
                        ],
                      );
                    },
                  ),
                ),

                // Caption (drawn last so it stays readable).
                Positioned(
                  left: compact ? 28 : 48,
                  right: compact ? 28 : 48,
                  bottom: compact ? 22 : 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: widget.headlinePrefix),
                            TextSpan(
                              text: widget.headlineAccent,
                              style: const TextStyle(color: AuthColors.gold),
                            ),
                            TextSpan(text: widget.headlineSuffix),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: compact ? 13 : 15,
                          color: const Color(0xFFC6DFCD),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Rolling hills and fireflies, scaled like an SVG "xMidYMid slice".
class _SceneryPainter extends CustomPainter {
  const _SceneryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const vw = 800.0;
    const vh = 900.0;
    final scale = math.max(size.width / vw, size.height / vh);
    canvas.save();
    canvas.translate(
      (size.width - vw * scale) / 2,
      (size.height - vh * scale) / 2,
    );
    canvas.scale(scale);

    Path hill(double y0, double cx1, double cy1, double x1, double y1,
        double cx2, double cy2, double y2) {
      return Path()
        ..moveTo(0, y0)
        ..quadraticBezierTo(cx1, cy1, x1, y1)
        ..quadraticBezierTo(cx2, cy2, 800, y2)
        ..lineTo(800, vh)
        ..lineTo(0, vh)
        ..close();
    }

    canvas.drawPath(
      hill(520, 200, 460, 400, 500, 600, 540, 480),
      Paint()..color = AuthColors.alpha(0x1D5C36, 0.85),
    );
    canvas.drawPath(
      hill(610, 220, 570, 420, 600, 620, 630, 580),
      Paint()..color = const Color(0xFF144228),
    );
    canvas.drawPath(
      hill(700, 240, 670, 460, 690, 680, 710, 675),
      Paint()..color = const Color(0xFF0C2C1B),
    );

    final gold = Paint()..color = AuthColors.alpha(0xF5C518, 0.75);
    for (final p in const [
      Offset(120, 120),
      Offset(340, 150),
      Offset(650, 60),
      Offset(720, 230),
    ]) {
      canvas.drawCircle(p, 2, gold);
    }

    final green = Paint()..color = AuthColors.alpha(0xA8E063, 0.7);
    for (final p in const [
      Offset(220, 80),
      Offset(500, 90),
      Offset(60, 220),
      Offset(420, 60),
      Offset(770, 140),
    ]) {
      canvas.drawCircle(p, 1.5, green);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Label above the field, dark filled input, lime focus border.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.isPassword = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: AuthColors.label,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          obscureText: widget.isPassword && _obscure,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofillHints: widget.autofillHints,
          cursorColor: AuthColors.lime,
          style: const TextStyle(fontSize: 14, color: AuthColors.text),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AuthColors.hint),
            filled: true,
            fillColor: AuthColors.ink700,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: _border(AuthColors.line),
            focusedBorder: _border(AuthColors.lime),
            errorBorder: _border(AuthColors.gold),
            focusedErrorBorder: _border(AuthColors.gold),
            errorStyle: const TextStyle(color: Color(0xFFFFC86B)),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AuthColors.muted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Gold → lime → forest gradient button with a loading state.
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AuthColors.gold, AuthColors.lime, AuthColors.forest],
              stops: [0, 0.55, 1],
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 48,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF06210F),
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: Color(0xFF06210F),
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

enum AuthBannerKind { error, success }

/// Message box with a coloured stripe on the left.
class AuthBanner extends StatelessWidget {
  const AuthBanner({super.key, required this.message, required this.kind});

  final String message;
  final AuthBannerKind kind;

  @override
  Widget build(BuildContext context) {
    final isError = kind == AuthBannerKind.error;
    final background =
        isError ? const Color(0xFF3A2410) : const Color(0xFF123A22);
    final foreground =
        isError ? const Color(0xFFFFC86B) : const Color(0xFF9CE8B0);
    final stripe = isError ? AuthColors.gold : AuthColors.leaf;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: background,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: stripe),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(
                      message,
                      style: TextStyle(fontSize: 13, color: foreground),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "AT CLAM" wordmark: lime "AT", gold "CLAM".
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key, this.fontSize = 20, this.letterSpacing = 1.5});

  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: letterSpacing,
          color: AuthColors.lime,
        ),
        children: const [
          TextSpan(text: 'AT '),
          TextSpan(text: 'CLAM', style: TextStyle(color: AuthColors.gold)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User roles + login result
// ---------------------------------------------------------------------------

/// The three kinds of users in AT CLAM.
///
/// IMPORTANT: the role a person picks on the login screen is only a request.
/// The backend must check the account's real role and return it. Never trust
/// the frontend choice for permissions.
enum UserRole {
  student,
  instructor,
  admin;

  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.instructor => 'Instructor',
        UserRole.admin => 'Admin',
      };

  String get hint => switch (this) {
        UserRole.student => 'View your classes and your own attendance.',
        UserRole.instructor =>
          'Manage classes, sessions, and attendance records.',
        UserRole.admin => 'Manage users and system information.',
      };

  /// Turns a backend value like "instructor" into a role (or null).
  static UserRole? fromName(String? value) {
    if (value == null) return null;
    final v = value.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.name == v) return role;
    }
    return null;
  }
}

/// What the backend returns after a login attempt.
class AuthResult {
  /// Login worked. [role] must be the role stored on the server.
  const AuthResult.success({required UserRole this.role, this.username})
      : error = null;

  /// Login failed. [message] is shown to the user.
  const AuthResult.failure(String message)
      : error = message,
        role = null,
        username = null;

  final UserRole? role;
  final String? username;
  final String? error;

  bool get ok => role != null && error == null;
}

// ---------------------------------------------------------------------------
// Dashboard shell (sidebar, top bar, shared cards) used by all 3 dashboards
// ---------------------------------------------------------------------------

/// Light dashboard palette (green sidebar, pale green background).
class Dash {
  Dash._();

  static const bg = Color(0xFFF1F7F2);
  static const sidebar = Color(0xFF123D25);
  static const accent = Color(0xFF72C982);
  static const title = Color(0xFF123D25);
  static const heading = Color(0xFF173C25);
  static const itemTitle = Color(0xFF24432D);
  static const muted = Color(0xFF71907A);
  static const mutedSoft = Color(0xFF829287);
  static const border = Color(0xFFDCEADE);
  static const divider = Color(0xFFEDF3EE);
  static const tint = Color(0xFFDCF2DF);
  static const tintButton = Color(0xFFE0F3E3);
  static const link = Color(0xFF31844A);
  static const deep = Color(0xFF246438);
  static const menuText = Color(0xFFD9EADC);
  static const menuTitle = Color(0xFF8FB79A);
  static const menuSub = Color(0xFFB8D9BF);
}

class NavEntry {
  const NavEntry(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Honest feedback for buttons whose page does not exist yet.
void showNotBuilt(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what is not built yet.')));
}

// ---------------------------------------------------------------------------
// Shell: sidebar + top bar + scrolling content
// ---------------------------------------------------------------------------

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.roleLabel,
    required this.username,
    required this.mainMenu,
    required this.pageTitle,
    required this.pageSubtitle,
    required this.children,
  });

  final String roleLabel;
  final String username;

  /// First entry is the current page (Dashboard).
  final List<NavEntry> mainMenu;
  final String pageTitle;
  final String pageSubtitle;
  final List<Widget> children;

  static const double breakpoint = 900;
  static const _accountMenu = [
    NavEntry(Icons.person_outline, 'Profile'),
    NavEntry(Icons.settings_outlined, 'Settings'),
  ];

  void _logout(BuildContext context) {
    // TODO: when the backend exists, also end the session/token on the server.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= breakpoint;
        if (wide) {
          return Scaffold(
            backgroundColor: Dash.bg,
            body: Row(
              children: [
                _Sidebar(
                  roleLabel: roleLabel,
                  mainMenu: mainMenu,
                  accountMenu: _accountMenu,
                  inDrawer: false,
                  onLogout: () => _logout(context),
                ),
                Expanded(child: _content(context, wide: true)),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: Dash.bg,
          drawer: Drawer(
            backgroundColor: Dash.sidebar,
            child: SafeArea(
              child: _Sidebar(
                roleLabel: roleLabel,
                mainMenu: mainMenu,
                accountMenu: _accountMenu,
                inDrawer: true,
                onLogout: () => _logout(context),
              ),
            ),
          ),
          body: _content(context, wide: false),
        );
      },
    );
  }

  Widget _content(BuildContext context, {required bool wide}) {
    final initial =
        username.trim().isEmpty ? '?' : username.trim()[0].toUpperCase();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 40 : 18,
          vertical: wide ? 30 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!wide)
                  Builder(
                    builder: (ctx) => IconButton(
                      tooltip: 'Menu',
                      icon: const Icon(Icons.menu, color: Dash.title),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageTitle,
                        style: TextStyle(
                          fontSize: wide ? 28 : 22,
                          fontWeight: FontWeight.bold,
                          color: Dash.title,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        pageSubtitle,
                        style:
                            const TextStyle(fontSize: 14, color: Dash.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showNotBuilt(context, 'Notifications'),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD9E8DC)),
                    ),
                    child: const Icon(Icons.notifications_none,
                        color: Dash.deep, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                if (wide)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Dash.title,
                          ),
                        ),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                              fontSize: 11, color: Dash.muted),
                        ),
                      ],
                    ),
                  ),
                CircleAvatar(
                  radius: 21.5,
                  backgroundColor: Dash.accent,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Dash.title,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SampleDataNotice(),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Reminds everyone that the numbers on these dashboards are not real.
class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1DC8B)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF8A6A00)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Sample data for design only. Not connected to the database yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B5300)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.roleLabel,
    required this.mainMenu,
    required this.accountMenu,
    required this.inDrawer,
    required this.onLogout,
  });

  final String roleLabel;
  final List<NavEntry> mainMenu;
  final List<NavEntry> accountMenu;
  final bool inDrawer;
  final VoidCallback onLogout;

  void _tap(BuildContext context, NavEntry entry, bool isCurrent) {
    if (inDrawer) Navigator.of(context).pop();
    if (!isCurrent) showNotBuilt(context, entry.label);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: inDrawer ? null : 250,
      color: Dash.sidebar,
      padding: const EdgeInsets.fromLTRB(18, 25, 18, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const ClamLogo(size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AT CLAM',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$roleLabel Portal',
                        style: const TextStyle(
                            fontSize: 11, color: Dash.menuSub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _MenuTitle('Main Menu'),
                  for (var i = 0; i < mainMenu.length; i++)
                    _MenuItem(
                      entry: mainMenu[i],
                      active: i == 0,
                      onTap: () => _tap(context, mainMenu[i], i == 0),
                    ),
                  const _MenuTitle('Account'),
                  for (final entry in accountMenu)
                    _MenuItem(
                      entry: entry,
                      active: false,
                      onTap: () => _tap(context, entry, false),
                    ),
                ],
              ),
            ),
          ),
          _MenuItem(
            entry: const NavEntry(Icons.logout, 'Logout'),
            active: false,
            muted: true,
            onTap: () {
              if (inDrawer) Navigator.of(context).pop();
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTitle extends StatelessWidget {
  const _MenuTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          color: Dash.menuTitle,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.entry,
    required this.active,
    required this.onTap,
    this.muted = false,
  });

  final NavEntry entry;
  final bool active;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Dash.title
        : muted
            ? Dash.menuSub
            : Dash.menuText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: active ? Dash.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(entry.icon, size: 20, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable dashboard building blocks
// ---------------------------------------------------------------------------

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF174C2C), Color(0xFF287342)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFFCCE6D1)),
          ),
        ],
      ),
    );
  }
}

/// Lays children out in as many equal columns as fit.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 240,
    this.gap = 18,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        var cols = ((width + gap) / (minItemWidth + gap)).floor();
        cols = math.min(math.max(cols, 1), children.length);
        final itemWidth = (width - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Dash.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Dash.tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Dash.deep, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF799381)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Dash.title,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Dash.heading,
            ),
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: () => showNotBuilt(context, title),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Dash.link,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Dash.border),
      ),
      child: child,
    );
  }
}

/// Two panels side by side on wide screens, stacked on narrow ones.
class TwoColumn extends StatelessWidget {
  const TwoColumn({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 820) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 14, child: left),
              const SizedBox(width: 20),
              Expanded(flex: 10, child: right),
            ],
          );
        }
        return Column(
          children: [left, const SizedBox(height: 20), right],
        );
      },
    );
  }
}

/// Card with a coloured banner, a code badge, a title and a button.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.tone,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.buttonLabel,
  });

  /// 0, 1 or 2 picks one of three banner colours.
  final int tone;
  final String code;
  final String title;
  final String subtitle;
  final String footer;
  final String buttonLabel;

  static const _tones = [
    [Color(0xFF246B3B), Color(0xFF72C982)],
    [Color(0xFF1B5732), Color(0xFF4C9B61)],
    [Color(0xFF356F45), Color(0xFF8ACB95)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _tones[tone % _tones.length];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Dash.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 113,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 90,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 67,
                  left: 20,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF226438),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Dash.heading,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF809386)),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '● $footer',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF4D8060)),
                      ),
                    ),
                    Material(
                      color: Dash.tintButton,
                      borderRadius: BorderRadius.circular(7),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () => showNotBuilt(context, title),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          child: Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Dash.deep,
                            ),
                          ),
                        ),
                      ),
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

/// A row with a date box on the left (used for sessions and schedules).
class DateTile extends StatelessWidget {
  const DateTile({
    super.key,
    required this.day,
    required this.month,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final String day;
  final String month;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Dash.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
              color: Dash.tintButton,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF28683B),
                  ),
                ),
                Text(
                  month.toUpperCase(),
                  style:
                      const TextStyle(fontSize: 9, color: Color(0xFF28683B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Dash.itemTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Dash.mutedSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A row with a small coloured tag, a title and a subtitle.
class TagTile extends StatelessWidget {
  const TagTile({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    this.tagBackground = Dash.tint,
    this.tagForeground = const Color(0xFF2D7041),
    this.last = false,
  });

  final String tag;
  final String title;
  final String subtitle;
  final Color tagBackground;
  final Color tagForeground;
  final bool last;

  /// Ready-made colours for attendance statuses.
  static const present = (Color(0xFFDCF2DF), Color(0xFF2D7041));
  static const late = (Color(0xFFFFF1C2), Color(0xFF8A6A00));
  static const absent = (Color(0xFFFDE2E0), Color(0xFF9B2C2C));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Dash.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagBackground,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              tag,
              style: TextStyle(fontSize: 10, color: tagForeground),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Dash.itemTitle,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Dash.mutedSoft),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role selector (Student / Instructor / Admin)
// ---------------------------------------------------------------------------

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.roles = UserRole.values,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  final List<UserRole> roles;

  static IconData iconFor(UserRole role) => switch (role) {
        UserRole.student => Icons.school_outlined,
        UserRole.instructor => Icons.menu_book_outlined,
        UserRole.admin => Icons.admin_panel_settings_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            'I am a',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: AuthColors.label,
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < roles.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: _RoleChip(
                    role: roles[i],
                    selected: roles[i] == selected,
                    onTap: () => onChanged(roles[i]),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selected.hint,
          style: const TextStyle(fontSize: 12, color: AuthColors.muted),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AuthColors.gold : AuthColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: role.label,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? AuthColors.alpha(0xF5C518, 0.12)
                : AuthColors.ink700,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AuthColors.gold : AuthColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(RoleSelector.iconFor(role), size: 22, color: color),
                  const SizedBox(height: 4),
                  Text(
                    role.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login screen
// ---------------------------------------------------------------------------

/// Sends the credentials to the backend.
///
/// [requestedRole] is only what the person clicked. The backend must check the
/// account's real role and return it inside [AuthResult.success].
typedef LoginSubmit = Future<AuthResult> Function(
  String email,
  String password,
  UserRole requestedRole,
);

/// Opens the dashboard that matches [role], replacing the auth screens.
void openDashboard(
  BuildContext context, {
  required UserRole role,
  required String username,
}) {
  final Widget page = switch (role) {
    UserRole.student => StudentDashboard(username: username),
    UserRole.instructor => InstructorDashboard(username: username),
    UserRole.admin => AdminDashboard(username: username),
  };
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => page),
    (route) => false,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onSubmit,
    this.onSuccess,
    this.onGoToRegister,
    this.onForgotPassword,
    this.successMessage,
    this.demoMode = false,
  });

  /// Real login call. While this is null the screen is a DESIGN PREVIEW only.
  final LoginSubmit? onSubmit;

  /// Called after a successful login. Defaults to [openDashboard].
  final ValueChanged<AuthResult>? onSuccess;

  /// Defaults to opening [RegisterScreen].
  final VoidCallback? onGoToRegister;

  /// The "Forgot Password?" link is only shown when this is provided.
  final VoidCallback? onForgotPassword;

  /// Green banner, e.g. "Account created! Please log in."
  final String? successMessage;

  /// DEMO ONLY. When true and [onSubmit] is null, the Login button skips all
  /// checks and opens the dashboard of the selected role. Nobody is
  /// authenticated. Remove this once the backend login exists.
  final bool demoMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  UserRole _role = UserRole.student;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
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
    if (value == null || value.isEmpty) return 'Please enter your password.';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final submit = widget.onSubmit;
    if (submit == null) {
      if (widget.demoMode) {
        openDashboard(
          context,
          role: _role,
          username: _email.text.trim().split('@').first,
        );
        return;
      }
      setState(() => _error =
          'Design preview only: login is not connected to the backend yet.');
      return;
    }

    setState(() => _loading = true);
    AuthResult result;
    try {
      result = await submit(_email.text.trim(), _password.text, _role);
    } catch (_) {
      result = const AuthResult.failure(
          'Could not reach the server. Please try again.');
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.ok ? null : (result.error ?? 'Login failed.');
    });
    if (!result.ok) return;

    final custom = widget.onSuccess;
    if (custom != null) {
      custom(result);
    } else {
      // Use the role the SERVER returned, not the one that was clicked.
      openDashboard(
        context,
        role: result.role!,
        username: result.username ?? _email.text.trim().split('@').first,
      );
    }
  }

  void _goToRegister() {
    final custom = widget.onGoToRegister;
    if (custom != null) {
      custom();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < AuthLayout.breakpoint;

    return AuthLayout(
      headlinePrefix: 'Attendance, made ',
      headlineAccent: 'effortless',
      description:
          'Log in to manage your classes, sessions, and attendance records.',
      tileIcons: const [
        Icons.groups_outlined,
        Icons.event_available_outlined,
        Icons.chat_bubble_outline,
        Icons.school_outlined,
        Icons.videocam_outlined,
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: GlowingLogo(size: narrow ? 88 : 112)),
            const SizedBox(height: 28),
            const Center(child: AuthWordmark()),
            const SizedBox(height: 22),
            const Text(
              'Welcome',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF3FAF3),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log in to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AuthColors.muted),
            ),
            const SizedBox(height: 26),
            if (_error != null)
              AuthBanner(message: _error!, kind: AuthBannerKind.error)
            else if (widget.successMessage != null)
              AuthBanner(
                  message: widget.successMessage!,
                  kind: AuthBannerKind.success),
            RoleSelector(
              selected: _role,
              onChanged: (role) => setState(() => _role = role),
            ),
            AuthTextField(
              controller: _email,
              label: 'Email',
              hint: 'Enter email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            AuthTextField(
              controller: _password,
              label: 'Password',
              hint: 'Enter password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: _validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (widget.onForgotPassword != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AuthColors.gold,
                    padding: const EdgeInsets.only(top: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AuthButton(label: 'Login', loading: _loading, onPressed: _submit),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 13, color: AuthColors.muted),
                ),
                InkWell(
                  onTap: _goToRegister,
                  child: const Text(
                    'Sign up',
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