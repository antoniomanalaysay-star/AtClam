import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_style.dart';

OutlineInputBorder _border(Color color, {double width = AppStyle.strokeWidth}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// Text field in the app's glass style. Set [obscure] for passwords (adds an eye button).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;
  bool _hovered = false;
  bool _focused = false;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.alpha(0x5B9FE8, 0.22),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          focusNode: _focus,
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _hidden,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onFieldSubmitted:
              widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
          style: const TextStyle(color: AppColors.text),
          cursorColor: AppColors.lime,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: const TextStyle(color: AppColors.label),
            floatingLabelStyle: const TextStyle(color: AppColors.lime),
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, color: AppColors.muted),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xB304122A),
            border: _border(AppStyle.strokeRaised),
            enabledBorder: _border(
              _hovered ? AppStyle.strokeHover : AppStyle.strokeRaised,
            ),
            focusedBorder: _border(AppColors.lime, width: 1.6),
            errorBorder: _border(AppColors.danger),
            focusedErrorBorder: _border(AppColors.danger, width: 1.6),
          ),
        ),
      ),
    );
  }
}

/// Big gold button with hover lift. Shows a spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AppButton(
        label: label,
        onPressed: onPressed,
        loading: loading,
        fullWidth: true,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        fontSize: 16,
      ),
    );
  }
}

/// Frosted red box for error messages.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: false,
      radius: AppStyle.radiusSmall,
      padding: const EdgeInsets.all(12),
      color: AppColors.alpha(0xFF5D6C, 0.12),
      borderColor: AppColors.alpha(0xFF5D6C, 0.5),
      hover: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

/// Frosted card used on the dashboards, forms and dialogs.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.hover = false,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool hover;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: double.infinity,
      padding: padding,
      hover: hover,
      onTap: onTap,
      color: color,
      child: child,
    );
  }
}
