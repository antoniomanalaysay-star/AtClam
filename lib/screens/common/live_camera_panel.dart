import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/class_info.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import '../instructor/scan_screen.dart';

/// The original "Live camera" page, adapted to send frames from a phone.
class LiveCameraPanel extends StatefulWidget {
  const LiveCameraPanel({super.key, this.initialClass});

  /// When opened from a class page, start with that class selected.
  final ClassInfo? initialClass;

  @override
  State<LiveCameraPanel> createState() => _LiveCameraPanelState();
}

class _LiveCameraPanelState extends State<LiveCameraPanel> {
  late Future<List<ClassInfo>> _classes;
  ClassInfo? _selected;
  Map<String, dynamic> _status = {};
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialClass;
    _classes = _loadClasses();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<ClassInfo>> _loadClasses() async {
    final data = await ApiClient.instance.get('/classes');
    final list = (data as List? ?? [])
        .map((c) => ClassInfo.fromJson(c as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty && _selected == null) _selected = list.first;
    return list;
  }

  Future<void> _poll() async {
    try {
      final data = await ApiClient.instance.get('/attendance/session');
      if (mounted) setState(() => _status = data as Map<String, dynamic>);
    } on ApiException {
      // Ignore transient polling errors.
    }
  }

  Future<void> _start() async {
    if (_selected == null) return;
    try {
      await ApiClient.instance
          .post('/attendance/session/start', body: {'class_id': _selected!.id});
      await _poll();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _end() async {
    try {
      await ApiClient.instance.post('/attendance/session/end');
      await _poll();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _status['active'] == true;
    final roster =
        (_status['roster'] as List? ?? []).cast<Map<String, dynamic>>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _Title('Live camera',
            subtitle:
                'Start a class, then use the instructor’s phone to scan students.'),
        const SizedBox(height: 18),
        if (_error != null) ...[
          ErrorBanner(_error!),
          const SizedBox(height: 12),
        ],
        GlassCard(
          radius: 8,
          borderColor: AppStyle.stroke,
          hoverBorderColor: AppStyle.strokeRaised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppPill(
                    active ? 'CLASS RUNNING' : 'NO CLASS RUNNING',
                    kind: active ? AppPillKind.lime : AppPillKind.muted,
                    icon: Icons.circle,
                  ),
                  const Spacer(),
                  Text(
                    _status['model_ready'] == true
                        ? 'Model ready'
                        : 'Model loading…',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<ClassInfo>>(
                future: _classes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(color: AppColors.lime);
                  }
                  final classes = snapshot.data!;
                  if (classes.isEmpty) {
                    return const Text('Create a class first.',
                        style: TextStyle(color: Colors.white));
                  }
                  final value = classes.any((c) => c.id == _selected?.id)
                      ? _selected!.id
                      : classes.first.id;
                  return DropdownButtonFormField<String>(
                    value: value,
                    dropdownColor: const Color(0xFF09182F),
                    decoration: AppStyle.inputDecoration('Class'),
                    items: classes
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name,
                                  style:
                                      const TextStyle(color: AppColors.text)),
                            ))
                        .toList(),
                    onChanged: active
                        ? null
                        : (id) => setState(() =>
                            _selected = classes.firstWhere((c) => c.id == id)),
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppButton(
                    label: 'Start class & detection',
                    icon: Icons.play_arrow,
                    onPressed: active || _selected == null ? null : _start,
                  ),
                  AppButton(
                    label: 'End class',
                    icon: Icons.stop,
                    variant: AppButtonVariant.danger,
                    onPressed: active ? _end : null,
                  ),
                  AppButton(
                    label: 'Open phone scanner',
                    icon: Icons.phone_android,
                    variant: AppButtonVariant.tonal,
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ScanScreen(classInfo: _selected!))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Title('In the room', subtitle: '${roster.length} student(s) enrolled'),
        const SizedBox(height: 10),
        GlassCard(
          radius: 8,
          borderColor: AppStyle.stroke,
          hoverBorderColor: AppStyle.strokeRaised,
          child: roster.isEmpty
              ? const Text('No students enrolled in this class.',
                  style: TextStyle(color: Colors.white))
              : Column(
                  children: roster.map((r) {
                    final status = r['status'] ?? 'absent';
                    return _HoverRosterTile(
                      name: r['name'] ?? '',
                      status: status,
                      time: r['time'] ?? '',
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, {required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white)),
        ],
      );
}

class _HoverRosterTile extends StatefulWidget {
  const _HoverRosterTile({
    required this.name,
    required this.status,
    required this.time,
  });

  final String name;
  final String status;
  final String time;

  @override
  State<_HoverRosterTile> createState() => _HoverRosterTileState();
}

class _HoverRosterTileState extends State<_HoverRosterTile> {
  bool _hovered = false;

  Color get _statusColor {
    switch (widget.status) {
      case 'present':
        return AppColors.leaf;
      case 'late':
        return AppColors.gold;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        transform:
            _hovered ? Matrix4.translationValues(4, 0, 0) : Matrix4.identity(),
        transformAlignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.alpha(0x5B9FE8, 0.10)
              : AppColors.alpha(0x0E2749, 0.30),
          borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
          border: Border.all(
            color: _hovered ? AppStyle.strokeHover : AppStyle.strokeRaised,
            width: AppStyle.strokeWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _statusColor.withValues(alpha: 0.55),
                    blurRadius: _hovered ? 12 : 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.name,
                style: TextStyle(
                  color: _hovered ? AppColors.lime : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${widget.status.toUpperCase()} ${widget.time}',
              style: TextStyle(
                color: _hovered ? AppColors.lime : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
