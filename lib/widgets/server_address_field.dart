import 'package:flutter/material.dart';

import '../config.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import 'app_widgets.dart';

/// Lets a device point the app at the backend *before* logging in.
///
/// Without this, a second device falls back to http://localhost:8000, which
/// points at that device instead of the computer running the backend.
class ServerAddressField extends StatefulWidget {
  const ServerAddressField({super.key});

  @override
  State<ServerAddressField> createState() => _ServerAddressFieldState();
}

class _ServerAddressFieldState extends State<ServerAddressField> {
  Future<void> _openDialog() async {
    final controller = TextEditingController(text: AppConfig.apiBaseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppStyle.glassRaised,
        title: const Text('Server address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'On another device on the same Wi-Fi, enter this computer\'s '
              'LAN address, e.g. http://192.168.30.35:8000. If the backend is '
              'hosted online, paste its https:// address instead.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: controller,
              label: 'Backend URL',
              icon: Icons.dns_outlined,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      await AppConfig.setBaseUrl(controller.text);
      if (mounted) setState(() {});
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _openDialog,
        icon: const Icon(Icons.dns_outlined, size: 16),
        label: Text(
          'Server: ${AppConfig.apiBaseUrl}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
