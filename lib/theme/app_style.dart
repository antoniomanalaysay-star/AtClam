import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Background photo declared in pubspec.yaml.
const String appBackgroundAsset = 'assets/images/thisimage.jpeg';

/// Shared visual language inspired by the dark gradient cards and frosted text
/// panels: deep navy glass, azure highlights and soft elevation.
class AppStyle {
  AppStyle._();

  static const double radius = 10;
  static const double radiusSmall = 8;

  /// Darkened light-blue -> azure fade, still clipped to heading glyphs.
  static const LinearGradient headingGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.goldHi, AppColors.lime],
  );

  /// Darker active-surface fade: deep navy blue -> mid azure.
  static const LinearGradient activeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x66164C87), Color(0x332C70C4)],
  );

  static const LinearGradient activeGradientHovered = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x88164C87), Color(0x55438AD8)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.goldHi, AppColors.lime],
  );

  /// Deep navy -> azure fade used as the full background of primary buttons.
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B2244), Color(0xFF2C70C4)],
  );

  /// Brightened version of [buttonGradient] for the CSS `filter:brightness(1.08)`
  /// hover state on buttons.
  static const LinearGradient buttonGradientHovered = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF123763), Color(0xFF438AD8)],
  );

  /// Dark-blue stroke system. `strokeDeep` is the outer outline, `stroke` is
  /// the default edge, `strokeRaised` is for inputs/insets, and `strokeHover`
  /// is the brighter active edge. All are darker than the old azure borders.
  static const Color strokeDeep = Color(0xFF041026);
  static const Color stroke = Color(0xFF102B52);
  static const Color strokeRaised = Color(0xFF1B4375);
  static const Color strokeHover = Color(0xFF2E6AAE);
  static const double strokeWidth = 1.4;

  static const Color darkBorder = stroke;
  static const Color hoverBorder = strokeHover;

  /// Small brightness lift used by button hover states.
  static Color brighten(Color color, [double amount = 0.08]) =>
      Color.lerp(color, Colors.white, amount) ?? color;

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x5908172F), blurRadius: 50, offset: Offset(0, 18)),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(color: Color(0x730E2850), blurRadius: 34, offset: Offset(0, 14)),
  ];

  static const Color glass = Color(0x9909182F);
  static const Color glassRaised = Color(0xB30D2242);
  static const Color glassDeep = Color(0xE604122A);

  static const Duration motion = Duration(milliseconds: 220);

  static Duration motionFor(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : motion;

  /// Input decoration with dark glass, blue borders and azure focus.
  static InputDecoration inputDecoration(
    String label, {
    IconData? icon,
    Color? borderColor,
    bool filled = true,
    bool dense = false,
  }) {
    final side = BorderSide(
      color: borderColor ?? AppStyle.strokeRaised,
      width: AppStyle.strokeWidth,
    );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.label),
      floatingLabelStyle: const TextStyle(color: AppColors.lime),
      hintStyle: const TextStyle(color: AppColors.hint),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
      filled: filled,
      fillColor: filled ? const Color(0x9904122A) : null,
      contentPadding: dense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: side,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: side,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: AppColors.lime, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
    );
  }
}

/// The photo + blue fade that sits behind every screen, dialog and route.
/// Attached once through `MaterialApp.builder` in main.dart.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          appBackgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF050E21)),
        ),
        // Deep navy at the edges with a blue-lit centre, like the inspiration.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.5, 1],
              colors: [Color(0xED050E21), Color(0x66091F3D), Color(0xF2050E21)],
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Frosted panel used by cards, dialogs and form sections.
/// Hover lifts the panel, brightens its border and deepens its shadow.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    this.radius = AppStyle.radius,
    this.color,
    this.hoverColor,
    this.borderColor,
    this.hoverBorderColor,
    this.blur = true,
    this.hover = false,
    this.hoverLift = true,
    this.glow = false,
    this.glowColor = AppColors.lime,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final double radius;
  final Color? color;
  final Color? hoverColor;
  final Color? borderColor;
  final Color? hoverBorderColor;
  final bool blur;
  final bool hover;
  final bool hoverLift;
  final bool glow;
  final Color glowColor;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final canHover = widget.hover || widget.onTap != null;
    final active = canHover && _hovered;
    final border = active
        ? (widget.hoverBorderColor ?? AppStyle.strokeRaised)
        : (widget.borderColor ?? AppStyle.stroke);
    final base = widget.color ?? AppStyle.glass;
    final lifted = widget.hoverColor ?? const Color(0xC40E2850);
    final surface = active ? lifted : base;
    final deep = Color.lerp(surface, AppColors.ink900, 0.28) ?? surface;

    // Optional radial glow for stat-style cards; it grows on hover.
    final content = widget.glow
        ? Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: AnimatedContainer(
                  duration: AppStyle.motionFor(context),
                  width: active ? 140 : 100,
                  height: active ? 140 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.glowColor.withAlpha(active ? 90 : 60),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          )
        : widget.child;

    Widget panel = AnimatedContainer(
      duration: AppStyle.motionFor(context),
      curve: Curves.easeOut,
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      alignment: widget.alignment,
      padding: widget.padding,
      transform: active && widget.hoverLift
          ? Matrix4.translationValues(0, -4, 0)
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      clipBehavior: widget.clipBehavior,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surface, deep],
        ),
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: border, width: AppStyle.strokeWidth),
        boxShadow: active ? AppStyle.hoverShadow : AppStyle.cardShadow,
      ),
      child: content,
    );

    if (widget.blur) {
      panel = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        clipBehavior: widget.clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: panel,
        ),
      );
    }

    if (canHover) {
      panel = MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: panel,
      );
    }

    if (widget.onTap != null) {
      panel = GestureDetector(onTap: widget.onTap, child: panel);
    }
    return panel;
  }
}

/// Heading with the bright-blue gradient used across the system.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style = const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppStyle.headingGradient.createShader(bounds),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Text block with the earlier frosted dark-blue gradient fill: the panel
/// itself fades from raised navy to deeper navy while the backdrop is blurred.
/// Strokes stay a darker blue so the fill remains the focus.
class GlassTextPanel extends StatelessWidget {
  const GlassTextPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = AppStyle.radiusSmall,
    this.color,
    this.border,
    this.sigma = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? border;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppStyle.glassRaised;
    final deep = Color.lerp(tint, AppColors.ink900, 0.32) ?? tint;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tint, deep],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: border ?? AppStyle.stroke,
              width: AppStyle.strokeWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

enum AppButtonVariant { primary, outline, dangerOutline, danger, tonal, text }

/// Button with hover lift / colour transitions for mouse and touch users.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.minimumSize = const Size(0, 40),
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.fullWidth = false,
    this.fontSize = 13,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;
  final Size minimumSize;
  final EdgeInsetsGeometry padding;
  final bool fullWidth;
  final double fontSize;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final action = disabled ? null : widget.onPressed;
    final spinner = SizedBox(
      width: 15,
      height: 15,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: widget.variant == AppButtonVariant.primary ||
                widget.variant == AppButtonVariant.tonal
            ? Colors.white
            : (widget.variant == AppButtonVariant.dangerOutline ||
                    widget.variant == AppButtonVariant.danger
                ? AppColors.danger
                : AppColors.lime),
      ),
    );
    final icon = widget.loading
        ? spinner
        : (widget.icon == null ? null : Icon(widget.icon, size: 16));
    final textStyle =
        TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.w700);

    Widget faded(
      Widget child,
      Gradient gradient, {
      Gradient? hoverGradient,
    }) {
      final highlight = !disabled && _hovered;
      return Opacity(
        opacity: disabled ? 0.55 : 1,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: highlight ? (hoverGradient ?? gradient) : gradient,
            borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
            border: Border.all(
              color: highlight ? AppStyle.strokeHover : AppStyle.stroke,
              width: AppStyle.strokeWidth,
            ),
            boxShadow: highlight ? AppStyle.hoverShadow : null,
          ),
          child: child,
        ),
      );
    }

    Widget button;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        button = faded(
          FilledButton.icon(
            onPressed: action,
            icon: icon ?? const SizedBox.shrink(),
            label: Text(widget.label),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              minimumSize: widget.minimumSize,
              padding: widget.padding,
              elevation: 0,
              textStyle: textStyle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
              ),
            ),
          ),
          AppStyle.buttonGradient,
          hoverGradient: AppStyle.buttonGradientHovered,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton.icon(
          onPressed: action,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: _hovered
                ? AppColors.alpha(0x164C87, 0.28)
                : AppColors.alpha(0x06162D, 0.35),
            side: BorderSide(
              color: _hovered ? AppStyle.strokeHover : AppStyle.stroke,
              width: AppStyle.strokeWidth,
            ),
            minimumSize: widget.minimumSize,
            padding: widget.padding,
            elevation: _hovered ? 4 : 0,
            shadowColor: const Color(0x55000000),
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
            ),
          ),
        );
        break;
      case AppButtonVariant.dangerOutline:
        button = OutlinedButton.icon(
          onPressed: action,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: _hovered ? Colors.white : AppColors.danger,
            backgroundColor:
                _hovered ? AppColors.alpha(0xFF5D6C, 0.2) : Colors.transparent,
            side: BorderSide(
              color:
                  _hovered ? AppColors.danger : AppColors.alpha(0xFF5D6C, 0.5),
              width: AppStyle.strokeWidth,
            ),
            minimumSize: widget.minimumSize,
            padding: widget.padding,
            elevation: _hovered ? 4 : 0,
            shadowColor: AppColors.alpha(0xFF5D6C, 0.4),
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
            ),
          ),
        );
        break;
      case AppButtonVariant.danger:
        button = FilledButton.icon(
          onPressed: action,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(widget.label),
          style: FilledButton.styleFrom(
            backgroundColor:
                _hovered ? const Color(0xFFFF8A95) : AppColors.danger,
            disabledBackgroundColor: AppColors.alpha(0xFF5D6C, 0.5),
            foregroundColor: Colors.white,
            minimumSize: widget.minimumSize,
            padding: widget.padding,
            elevation: _hovered ? 6 : 0,
            shadowColor: AppColors.alpha(0xFF5D6C, 0.45),
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
            ),
          ),
        );
        break;
      case AppButtonVariant.tonal:
        button = faded(
          FilledButton.tonalIcon(
            onPressed: action,
            icon: icon ?? const SizedBox.shrink(),
            label: Text(widget.label),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              minimumSize: widget.minimumSize,
              padding: widget.padding,
              elevation: 0,
              textStyle: textStyle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
              ),
            ),
          ),
          AppStyle.activeGradient,
          hoverGradient: AppStyle.activeGradientHovered,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton.icon(
          onPressed: action,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(widget.label),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: widget.minimumSize,
            padding: widget.padding,
            textStyle: textStyle,
          ),
        );
        break;
    }

    return MouseRegion(
      onEnter: disabled ? null : (_) => setState(() => _hovered = true),
      onExit: disabled ? null : (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: !disabled && _hovered ? const Offset(0, -0.08) : Offset.zero,
        duration: AppStyle.motionFor(context),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: !disabled && _hovered ? 1.025 : 1,
          duration: AppStyle.motionFor(context),
          curve: Curves.easeOut,
          child: widget.fullWidth
              ? SizedBox(width: double.infinity, child: button)
              : button,
        ),
      ),
    );
  }
}

/// Rounded initials tile matching the avatars in the admin table.
/// Hovering scales/rotates it and brightens the fill, like `tr:hover .avatar`.
class AvatarTile extends StatefulWidget {
  const AvatarTile(
    this.name, {
    super.key,
    this.size = 42,
    this.classTile = false,
    this.hovered,
  });

  final String name;
  final double size;
  final bool classTile;

  /// Optional external hover state, e.g. from the surrounding table row.
  final bool? hovered;

  @override
  State<AvatarTile> createState() => _AvatarTileState();
}

class _AvatarTileState extends State<AvatarTile> {
  bool _localHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.hovered ?? _localHovered;
    final parts =
        widget.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    final text = initials.isEmpty ? '?' : initials;
    final radius = widget.classTile ? 12.0 : 100.0;

    return MouseRegion(
      onEnter: widget.hovered == null
          ? (_) => setState(() => _localHovered = true)
          : null,
      onExit: widget.hovered == null
          ? (_) => setState(() => _localHovered = false)
          : null,
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        transform: active
            ? (Matrix4.identity()
              ..scale(1.12)
              ..rotateZ(-0.07))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.alpha(0x5B9FE8, 0.3)
              : AppColors.alpha(0x164C87, 0.5),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: active ? AppStyle.strokeHover : AppStyle.strokeRaised,
            width: AppStyle.strokeWidth,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppStyle.motionFor(context),
          style: TextStyle(
            color: active ? Colors.white : AppColors.goldHi,
            fontSize: widget.size * 0.34,
            fontWeight: FontWeight.w800,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

/// Small coloured label (sections, class codes, statuses).
class AppPill extends StatelessWidget {
  const AppPill(
    this.label, {
    super.key,
    this.kind = AppPillKind.section,
    this.icon,
  });

  final String label;
  final AppPillKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Highlight pills use the same dark-blue fade as active tabs/buttons.
    // `warning` is the only amber pill and is reserved for Late/Blink.
    final gradient = switch (kind) {
      AppPillKind.gold => AppStyle.buttonGradient,
      AppPillKind.lime => AppStyle.activeGradient,
      _ => null,
    };
    final (background, foreground) = switch (kind) {
      AppPillKind.gold => (AppColors.alpha(0x164C87, 0.18), AppColors.goldHi),
      AppPillKind.warning => (AppColors.alpha(0xF5C518, 0.18), AppColors.warn),
      AppPillKind.section => (AppColors.alpha(0x0E2749, 0.5), AppColors.label),
      AppPillKind.lime => (AppColors.alpha(0x5B9FE8, 0.14), AppColors.goldHi),
      AppPillKind.danger => (AppColors.alpha(0xFF5D6C, 0.15), AppColors.danger),
      AppPillKind.muted => (AppColors.alpha(0x8FABD0, 0.1), AppColors.muted),
    };
    // Status pills keep their semantic red/amber edge; the rest use the
    // dark-blue stroke system so every chip reads as an outlined UI element.
    final border = kind == AppPillKind.warning || kind == AppPillKind.danger
        ? foreground.withAlpha(100)
        : AppStyle.strokeRaised;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: AppStyle.strokeWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum AppPillKind { gold, warning, section, lime, danger, muted }
