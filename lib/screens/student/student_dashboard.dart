import 'package:flutter/material.dart';

import '../../models/class_info.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import '../common/face_registration_screen.dart';
import '../common/legacy_shell.dart';
import '../common/legacy_widgets.dart';
import '../common/profile_screen.dart';
import 'student_class_screen.dart';

/// Student workspace with the old class-card layout and inline join form.
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<List<ClassInfo>> _classes;
  bool _joining = false;
  bool _busy = false;
  String? _error;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _classes = _load();
  }

  @override
  void dispose() {
    _code.dispose();
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

  Future<void> _join() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Enter the class code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.post('/classes/join',
          body: {'code': _code.text.trim().toUpperCase()});
      _code.clear();
      setState(() => _joining = false);
      _refresh();
      _toast('Joined ${data['name'] ?? 'the class'}!');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
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
            child: _workspace()),
        const LegacyDestination(
            label: 'My profile',
            icon: Icons.person_outline,
            child: ProfileScreen()),
      ],
    );
  }

  Widget _workspace() => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const LegacyPageTitle(
              'Student workspace',
              subtitle: 'Join a class with its code, read announcements and '
                  'track your attendance.',
            ),
            const SizedBox(height: 20),
            if (!hasFace()) _faceCard() else _faceReadyCard(),
            const SizedBox(height: 18),
            LegacySectionCard(
              title: 'My classes',
              action: AppButton(
                label: _joining ? 'Close' : 'Join a class',
                icon: _joining ? Icons.close : Icons.add,
                variant: AppButtonVariant.tonal,
                onPressed: () => setState(() => _joining = !_joining),
              ),
              children: [
                if (_joining) _joinForm(),
                if (_joining) const SizedBox(height: 18),
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
                      return const Text(
                        'No classes yet. Join one with a class code.',
                        style: TextStyle(color: AppColors.muted),
                      );
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
                                    StudentClassScreen(classInfo: c)));
                            _refresh();
                          },
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

  bool hasFace() => Session.instance.user?.hasFace ?? false;

  Widget _faceCard() => LegacySectionCard(
        title: 'Register your face',
        children: [
          const Text(
            'Add 3 clear photos (front, left and right) so the instructor’s '
            'phone can recognize you during class.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: LegacyButton(
              label: 'Add my 3 photos',
              icon: Icons.face_retouching_natural,
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const FaceRegistrationScreen()));
                await Session.instance.refresh();
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      );

  Widget _faceReadyCard() => InfoCard(
        hover: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.leaf),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Your face is registered',
                  style: TextStyle(color: AppColors.text)),
            ),
            AppButton(
              label: 'Update photos',
              icon: Icons.face_retouching_natural_outlined,
              variant: AppButtonVariant.text,
              fontSize: 12,
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const FaceRegistrationScreen()));
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      );

  Widget _joinForm() => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _code,
                  label: 'Class code',
                  icon: Icons.qr_code,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _join,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: LegacyButton(
                    label: 'Join class', busy: _busy, onPressed: _join),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
        ],
      );
}
