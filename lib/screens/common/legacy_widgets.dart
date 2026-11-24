import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/class_info.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';

/// Page heading used by every workspace screen.
class LegacyPageTitle extends StatelessWidget {
  const LegacyPageTitle(this.title,
      {required this.subtitle, this.actions = const []});

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientText(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: AppColors.muted)),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    );
  }
}

/// The big glass "card" sections from the original browser UI.
class LegacySectionCard extends StatelessWidget {
  const LegacySectionCard({
    super.key,
    required this.title,
    this.action,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  final String title;
  final Widget? action;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: double.infinity,
      padding: padding,
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppStyle.headingGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              GradientText(
                title,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppStyle.stroke, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A class tile with the banner / code / actions layout of the old UI,
/// now a frosted glass tile that lifts on hover.
class LegacyClassCard extends StatelessWidget {
  const LegacyClassCard({
    super.key,
    required this.info,
    required this.onOpen,
    this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  final ClassInfo info;
  final String? subtitle;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      hover: true,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0x33164C87),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppStyle.radius - 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(info.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                AppPill(info.section.isEmpty ? 'General' : info.section),
              ],
            ),
          ),
          const Divider(color: AppStyle.stroke, height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  info.description.isEmpty
                      ? 'No description'
                      : info.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  '${info.studentCount} students · ${subtitle ?? info.instructorName}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x9904122A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppStyle.strokeRaised,
                          width: AppStyle.strokeWidth,
                        ),
                      ),
                      child: Text(info.code,
                          style: const TextStyle(
                              color: AppColors.lime,
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Copy',
                      icon: Icons.copy_all_outlined,
                      variant: AppButtonVariant.text,
                      minimumSize: const Size(0, 34),
                      fontSize: 12,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: info.code));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Class code copied: ${info.code}')));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Open class',
                      icon: Icons.class_outlined,
                      onPressed: onOpen,
                      minimumSize: const Size(0, 34),
                      fontSize: 12,
                    ),
                    if (onEdit != null)
                      AppButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        variant: AppButtonVariant.outline,
                        onPressed: onEdit,
                        minimumSize: const Size(0, 34),
                        fontSize: 12,
                      ),
                    if (onDelete != null)
                      AppButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        variant: AppButtonVariant.outline,
                        onPressed: onDelete,
                        minimumSize: const Size(0, 34),
                        fontSize: 12,
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

/// Read-only time field that opens Flutter's time picker.
class LegacyTimeField extends StatefulWidget {
  const LegacyTimeField({
    super.key,
    required this.controller,
    required this.label,
    this.icon = Icons.access_time,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  static Future<void> pick(
      BuildContext context, TextEditingController controller) async {
    final parts = controller.text.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  State<LegacyTimeField> createState() => _LegacyTimeFieldState();
}

class _LegacyTimeFieldState extends State<LegacyTimeField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TextFormField(
        controller: widget.controller,
        readOnly: true,
        onTap: () => LegacyTimeField.pick(context, widget.controller),
        style: const TextStyle(color: AppColors.text),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? '${widget.label} is required'
            : null,
        decoration: AppStyle.inputDecoration(
          widget.label,
          icon: widget.icon,
          borderColor: _hovered ? AppColors.alpha(0x5B9FE8, 0.6) : null,
        ),
      ),
    );
  }
}

/// Compact button used throughout the old UI, with hover feedback.
class LegacyButton extends StatelessWidget {
  const LegacyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add,
    this.danger = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool danger;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      loading: busy,
      variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      fontSize: 12,
    );
  }
}
