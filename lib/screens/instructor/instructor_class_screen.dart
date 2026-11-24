import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/class_info.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import '../common/attendance_calendar.dart';
import '../common/legacy_widgets.dart';
import '../common/live_camera_panel.dart';

/// The old per-class panel, kept as a full page: four tabs with the same
/// labels and flows as the original browser UI.
class InstructorClassScreen extends StatelessWidget {
  const InstructorClassScreen({super.key, required this.classInfo});

  final ClassInfo classInfo;

  @override
  Widget build(BuildContext context) {
    final c = classInfo;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name),
              Text(
                  '${c.section.isEmpty ? 'General' : c.section} · ${c.instructorName}',
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400)),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppStyle.glassDeep,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppStyle.strokeRaised,
                  width: AppStyle.strokeWidth,
                ),
              ),
              child: Row(
                children: [
                  Text(c.code,
                      style: const TextStyle(
                          color: AppColors.lime,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: c.code));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Code copied: ${c.code}')));
                      }
                    },
                    child: const Icon(Icons.copy_all_outlined,
                        size: 16, color: AppColors.lime),
                  ),
                ],
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicator: BoxDecoration(
              gradient: AppStyle.activeGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(
                color: AppStyle.strokeHover,
                width: AppStyle.strokeWidth,
              ),
            ),
            indicatorColor: Colors.transparent,
            labelColor: AppColors.goldHi,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'Announcements'),
              Tab(text: 'Students & Attendance'),
              Tab(text: 'Attendance times'),
              Tab(text: 'Live camera'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AnnouncementsPane(classId: c.id),
            _StudentsPane(classInfo: c),
            _TimesPane(classInfo: c),
            LiveCameraPanel(initialClass: c),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- announcements
class _AnnouncementsPane extends StatefulWidget {
  const _AnnouncementsPane({required this.classId});

  final String classId;

  @override
  State<_AnnouncementsPane> createState() => _AnnouncementsPaneState();
}

class _AnnouncementsPaneState extends State<_AnnouncementsPane> {
  late Future<List<dynamic>> _items;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _load() async {
    final data = await ApiClient.instance
        .get('/classes/${widget.classId}/announcements');
    return data as List? ?? [];
  }

  void _refresh() => setState(() {
        _items = _load();
      });

  Future<void> _post() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      await ApiClient.instance.post('/classes/${widget.classId}/announcements',
          body: {'title': _title.text.trim(), 'body': _body.text.trim()});
      _title.clear();
      _body.clear();
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _delete(int id) async {
    try {
      await ApiClient.instance
          .delete('/classes/${widget.classId}/announcements/$id');
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        InfoCard(
          child: Column(
            children: [
              AppTextField(
                  controller: _title,
                  label: 'New announcement',
                  icon: Icons.title,
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              AppTextField(
                  controller: _body,
                  label: 'Message',
                  icon: Icons.message_outlined,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _post),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: LegacyButton(
                    label: 'Post', busy: _posting, onPressed: _post),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<dynamic>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.lime));
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Text('No announcements posted yet.',
                  style: TextStyle(color: AppColors.muted));
            }
            return Column(
              children: items.map((a) {
                final item = a as Map<String, dynamic>;
                return InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item['title'] ?? '',
                                style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700)),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _delete((item['id'] as num).toInt()),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${item['author'] ?? ''} · ${item['date'] ?? ''}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 10),
                      Text(item['body'] ?? '',
                          style: const TextStyle(color: AppColors.text)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ----------------------------------------------------- students & attendance
class _StudentsPane extends StatefulWidget {
  const _StudentsPane({required this.classInfo});

  final ClassInfo classInfo;

  @override
  State<_StudentsPane> createState() => _StudentsPaneState();
}

class _StudentsPaneState extends State<_StudentsPane> {
  late Future<List<dynamic>> _students;
  late Future<List<dynamic>> _excuses;
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _students = _load('/classes/${widget.classInfo.id}/students');
    _excuses = _load('/attendance/excuses/${widget.classInfo.id}');
  }

  Future<List<dynamic>> _load(String path) async {
    final data = await ApiClient.instance.get(path);
    return data as List? ?? [];
  }

  void _refreshStudents() => setState(() {
        _students = _load('/classes/${widget.classInfo.id}/students');
      });

  void _refreshExcuses() => setState(() {
        _excuses = _load('/attendance/excuses/${widget.classInfo.id}');
      });

  void _select(Map<String, dynamic> student) {
    setState(() => _selected = student);
  }

  Future<void> _remove(dynamic student) async {
    final uid = (student['id'] as num).toInt();
    final name = student['full_name'] ?? student['name'] ?? 'student';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const GradientText('Remove student?'),
        content: Text('Remove $name from this class?',
            style: const TextStyle(color: AppColors.muted)),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
              label: 'Remove',
              icon: Icons.person_remove_outlined,
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.instance
          .delete('/classes/${widget.classInfo.id}/students/$uid');
      if (_selected != null && _selected!['id'] == uid) {
        setState(() => _selected = null);
      }
      _refreshStudents();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = _studentList();
        final main = _selected == null
            ? const Center(
                child: Text(
                    'Choose a student to see their attendance calendar.',
                    style: TextStyle(color: AppColors.muted)))
            : _attendanceView();
        if (constraints.maxWidth < 900) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              side,
              const SizedBox(height: 16),
              main,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 320, child: side),
            Expanded(child: main),
          ],
        );
      },
    );
  }

  Widget _studentList() => FutureBuilder<List<dynamic>>(
        future: _students,
        builder: (context, snapshot) {
          final students = snapshot.data ?? [];
          return InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GradientText(
                  'Students',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selected == null
                      ? null
                      : (_selected!['id'] as num).toInt(),
                  hint: const Text('Choose a student…'),
                  dropdownColor: const Color(0xFF09182F),
                  decoration: AppStyle.inputDecoration('Pick a student'),
                  items: students.map((s) {
                    final item = s as Map<String, dynamic>;
                    return DropdownMenuItem<int>(
                      value: (item['id'] as num).toInt(),
                      child: Text('${item['full_name'] ?? item['name'] ?? ''}',
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id == null) {
                      setState(() => _selected = null);
                      return;
                    }
                    final found = students
                            .firstWhere((s) => (s['id'] as num).toInt() == id)
                        as Map<String, dynamic>;
                    _select(found);
                  },
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(
                      child: CircularProgressIndicator(color: AppColors.lime))
                else if (students.isEmpty)
                  const Text(
                      'No students have joined yet. Share the class code.',
                      style: TextStyle(color: AppColors.muted))
                else
                  ...students.map((s) {
                    final item = s as Map<String, dynamic>;
                    final name = '${item['full_name'] ?? item['name'] ?? ''}';
                    final selected =
                        _selected != null && _selected!['id'] == item['id'];
                    return _StudentTile(
                      name: name,
                      section: '${item['section'] ?? ''}',
                      selected: selected,
                      onTap: () => _select(item),
                      onRemove: () => _remove(item),
                    );
                  }),
              ],
            ),
          );
        },
      );

  Widget _attendanceView() {
    final student = _selected!;
    final name = '${student['full_name'] ?? student['name'] ?? 'Student'}';
    final uid = (student['id'] as num).toInt();
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 4),
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(name,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${widget.classInfo.name} · ${student['section'] ?? ''}',
                  style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AttendanceCalendar(
            classId: widget.classInfo.id, studentId: uid, studentName: name),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: _excuses,
          builder: (context, snapshot) {
            final notes = (snapshot.data ?? []).where((n) {
              final item = n as Map<String, dynamic>;
              return item['user_id'] == uid || item['user_id'] == student['id'];
            }).toList();
            if (notes.isEmpty) return const SizedBox();
            return InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Private student notes',
                      style: TextStyle(
                          color: AppColors.text, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...notes.map((n) {
                    final item = n as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${item['date']}  ${item['note']}',
                          style: const TextStyle(color: AppColors.muted)),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Student row with the same hover lift / lime border as the admin table.
class _StudentTile extends StatefulWidget {
  const _StudentTile({
    required this.name,
    required this.section,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final String section;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<_StudentTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          transform: _hovered && !widget.selected
              ? Matrix4.translationValues(3, 0, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.selected ? AppStyle.activeGradient : null,
            color: widget.selected
                ? null
                : (_hovered
                    ? AppColors.alpha(0x5B9FE8, 0.10)
                    : AppColors.alpha(0x0E2749, 0.28)),
            borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
            border: Border.all(
              color: highlighted ? AppStyle.strokeHover : AppStyle.strokeRaised,
              width: AppStyle.strokeWidth,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor:
                    widget.selected ? AppColors.lime : AppColors.forest,
                child: Text(
                  widget.name.isEmpty ? '?' : widget.name[0].toUpperCase(),
                  style: TextStyle(
                      color:
                          widget.selected ? AppColors.ink900 : AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                          color: highlighted ? AppColors.lime : AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                    if (widget.section.isNotEmpty)
                      Text(
                        widget.section,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    size: 18, color: AppColors.danger),
                tooltip: 'Remove',
                onPressed: widget.onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- attendance times
class _TimesPane extends StatefulWidget {
  const _TimesPane({required this.classInfo});

  final ClassInfo classInfo;

  @override
  State<_TimesPane> createState() => _TimesPaneState();
}

class _TimesPaneState extends State<_TimesPane> {
  late final TextEditingController _present;
  late final TextEditingController _late;
  late final TextEditingController _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _present = TextEditingController(text: widget.classInfo.presentTime);
    _late = TextEditingController(text: widget.classInfo.lateTime);
    _end = TextEditingController(text: widget.classInfo.endTime);
  }

  @override
  void dispose() {
    _present.dispose();
    _late.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.instance.put('/classes/${widget.classInfo.id}', body: {
        'name': widget.classInfo.name,
        'description': widget.classInfo.description,
        'section': widget.classInfo.section,
        'present_time': _present.text.trim(),
        'late_time': _late.text.trim(),
        'end_time': _end.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Times saved. Present / Late / Absent now follow this schedule.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How attendance is decided',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              _rule('Present · Start', AppColors.leaf,
                  'Recognized from the start time until late begins.'),
              _rule('Late', AppColors.gold,
                  'Recognized from the late time until the class ends.'),
              _rule('Absent', AppColors.danger,
                  'Nothing detected by the end time — unless a student has an approved excuse.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                      width: 210,
                      child: LegacyTimeField(
                          controller: _present, label: 'Start / PresentTime')),
                  SizedBox(
                      width: 210,
                      child: LegacyTimeField(
                          controller: _late, label: 'LateTime')),
                  SizedBox(
                      width: 210,
                      child:
                          LegacyTimeField(controller: _end, label: 'EndTime')),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'The camera marks Present or Late on detection. When you end the '
                'class, everyone without a detection is saved as Absent; excuse '
                'letters are always exempt.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: LegacyButton(
                    label: 'Save times', busy: _saving, onPressed: _save),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rule(String title, Color color, String detail) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: '$title  ',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w700)),
                    TextSpan(
                        text: detail,
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
