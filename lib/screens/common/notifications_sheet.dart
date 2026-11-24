import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';

/// Bell + badge for announcements and excuse letters.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  Timer? _timer;
  int _unread = 0;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final data = await ApiClient.instance.get('/notifications');
      if (!mounted) return;
      setState(() {
        _unread = data['unread'] as int? ?? 0;
        _items = data['items'] as List? ?? [];
      });
    } on ApiException {
      // Staying silent avoids interrupting the user while they work.
    }
  }

  Future<void> _open() async {
    await _refresh();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppStyle.glassRaised,
      builder: (ctx) => SafeArea(
        child: GlassCard(
          radius: 0,
          blur: false,
          padding: EdgeInsets.zero,
          color: AppStyle.glassDeep,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: GradientText(
                              'Notifications',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (_unread > 0) ...[
                            const SizedBox(width: 8),
                            AppPill('$_unread unread', kind: AppPillKind.gold),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AppButton(
                      label: 'Mark all read',
                      icon: Icons.done_all,
                      variant: AppButtonVariant.text,
                      fontSize: 12,
                      minimumSize: const Size(0, 34),
                      onPressed: () async {
                        await ApiClient.instance
                            .post('/notifications/read', body: {'all': true});
                        if (ctx.mounted) Navigator.pop(ctx);
                        _refresh();
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _items.isEmpty
                    ? const Center(
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              color: AppColors.hint, size: 34),
                          SizedBox(height: 10),
                          Text('No notifications yet.',
                              style: TextStyle(color: AppColors.muted)),
                        ],
                      ))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => Divider(
                            color: AppColors.alpha(0x0E2749, 0.6), height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index] as Map<String, dynamic>;
                          return _NotificationTile(
                            item: item,
                            onTap: () async {
                              await ApiClient.instance.post(
                                  '/notifications/read',
                                  body: {'id': item['id']});
                              if (ctx.mounted) Navigator.pop(ctx);
                              _refresh();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          onPressed: _open,
          tooltip: 'Notifications',
          color: AppColors.muted,
          hoverColor: AppColors.alpha(0x5B9FE8, 0.18),
          focusColor: AppColors.alpha(0x5B9FE8, 0.18),
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.alpha(0xFF5D6C, 0.55), blurRadius: 8)
                ],
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$_unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

/// Notification row with a lime hover lift. The caller keeps the read/update
/// behaviour; this widget only draws the glass tile and its feedback states.
class _NotificationTile extends StatefulWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final read = widget.item['read'] == true;
    final icon = widget.item['kind'] == 'excuse'
        ? Icons.mail_outline
        : Icons.campaign_outlined;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          transform: _hovered
              ? Matrix4.translationValues(4, 0, 0)
              : Matrix4.identity(),
          transformAlignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.alpha(0x5B9FE8, 0.12)
                : AppColors.alpha(0x0E2749, 0.28),
            borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
            border: Border.all(
              color: _hovered ? AppStyle.strokeHover : AppStyle.strokeRaised,
              width: AppStyle.strokeWidth,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: _hovered
                    ? AppColors.lime
                    : (read ? AppColors.muted : AppColors.lime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.item['title'] ?? ''}',
                      style: TextStyle(
                        color: _hovered ? AppColors.lime : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.item['body'] ?? ''} · ${widget.item['time'] ?? ''}',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!read) const AppPill('NEW', kind: AppPillKind.gold),
            ],
          ),
        ),
      ),
    );
  }
}
