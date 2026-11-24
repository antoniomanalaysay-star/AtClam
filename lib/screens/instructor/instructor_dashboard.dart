import 'package:flutter/material.dart';

import '../../models/class_info.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../utils/validators.dart';
import '../../widgets/app_widgets.dart';
import '../common/legacy_shell.dart';
import '../common/legacy_widgets.dart';
import '../common/live_camera_panel.dart';
import '../common/profile_screen.dart';
import 'instructor_class_screen.dart';

/// Instructor workspace with the original desktop layout: side navigation,
/// a "My classes" card with an inline create form and a grid of class tiles.
class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  late Future<List<ClassInfo>> _classes;
  bool _creating = false;
  bool _saving = false;
  String? _error;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _section = TextEditingController(text: 'General');
  final _present = TextEditingController(text: '08:00');
  final _late = TextEditingController(text: '08:15');
  final _end = TextEditingController(text: '09:00');

  @override
  void initState() {
    super.initState();
    _classes = _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _section, _present, _late, _end]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<List<ClassInfo>> _load() async {
    final data = await ApiClient.instance.get('/classes');
    return (data as List? ?? [])
        .map((c) => ClassInfo.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  void _refresh() => setState(() {
        _classes = _load();
      });

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the class a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post('/classes', body: {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'section':
            _section.text.trim().isEmpty ? 'General' : _section.text.trim(),
        'present_time': _present.text.trim(),
        'late_time': _late.text.trim(),
        'end_time': _end.text.trim(),
      });
      _name.clear();
      _description.clear();
      setState(() => _creating = false);
      _refresh();
      _toast('Class created! Share its code with your students.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(ClassInfo c) async {
    final name = TextEditingController(text: c.name);
    final desc = TextEditingController(text: c.description);
    final section = TextEditingController(text: c.section);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const GradientText('Rename / edit class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: name, label: 'Class name'),
              const SizedBox(height: 12),
              AppTextField(controller: desc, label: 'Description'),
              const SizedBox(height: 12),
              AppTextField(controller: section, label: 'Section'),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
              label: 'Save changes',
              icon: Icons.save_outlined,
              onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await ApiClient.instance.put('/classes/${c.id}', body: {
        'name': name.text.trim(),
        'description': desc.text.trim(),
        'section': section.text.trim(),
        'present_time': c.presentTime,
        'late_time': c.lateTime,
        'end_time': c.endTime,
      });
      _refresh();
      _toast('Class updated.');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _delete(ClassInfo c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const GradientText('Delete class?'),
        content: const Text(
          'This also removes its announcements and attendance records.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.instance.delete('/classes/${c.id}');
      _refresh();
      _toast('Class deleted.');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user!;
    return LegacyShell(
      user: user,
      destinations: [
        LegacyDestination(
            label: 'My classes',
            icon: Icons.class_outlined,
            child: _workspace(user.name)),
        const LegacyDestination(
            label: 'Live camera',
            icon: Icons.videocam_outlined,
            child: LiveCameraPanel()),
        const LegacyDestination(
            label: 'My profile',
            icon: Icons.person_outline,
            child: ProfileScreen()),
      ],
    );
  }

  Widget _workspace(String name) => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            LegacyPageTitle(
              'Instructor workspace',
              subtitle: 'Welcome back, $name. Create classes, share the code, '
                  'post announcements and check attendance.',
            ),
            const SizedBox(height: 20),
            LegacySectionCard(
              title: 'My classes',
              action: AppButton(
                label: _creating ? 'Close' : 'New class',
                icon: _creating ? Icons.close : Icons.add,
                variant: AppButtonVariant.tonal,
                onPressed: () => setState(() => _creating = !_creating),
              ),
              children: [
                if (_creating) _createForm(),
                if (_creating) const SizedBox(height: 18),
                FutureBuilder<List<ClassInfo>>(
                  future: _classes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(28),
                              child: CircularProgressIndicator(
                                  color: AppColors.lime)));
                    }
                    if (snapshot.hasError) {
                      return ErrorBanner(
                          (snapshot.error as ApiException).message);
                    }
                    final classes = snapshot.data!;
                    if (classes.isEmpty) {
                      return const Text('No classes yet. Create one above.',
                          style: TextStyle(color: AppColors.muted));
                    }
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: classes.map((c) {
                        return LegacyClassCard(
                          info: c,
                          onOpen: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    InstructorClassScreen(classInfo: c)));
                            _refresh();
                          },
                          onEdit: () => _edit(c),
                          onDelete: () => _delete(c),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );

  Widget _createForm() => Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 320,
                  child: AppTextField(
                    controller: _name,
                    label: 'Class name',
                    icon: Icons.class_outlined,
                    validator: (v) => requiredField(v, 'Class name'),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: AppTextField(
                    controller: _section,
                    label: 'Section',
                    icon: Icons.groups_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _description,
              label: 'Description (optional)',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                    width: 210,
                    child: LegacyTimeField(
                        controller: _present, label: 'Start / Present time')),
                SizedBox(
                    width: 210,
                    child: LegacyTimeField(
                        controller: _late, label: 'Late begins')),
                SizedBox(
                    width: 210,
                    child:
                        LegacyTimeField(controller: _end, label: 'Class ends')),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'These times decide who is Present, Late or Absent. You can change '
              'them later in the class’s Attendance times tab.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(_error!),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: LegacyButton(
                  label: 'Create class', busy: _saving, onPressed: _create),
            ),
          ],
        ),
      );
}
