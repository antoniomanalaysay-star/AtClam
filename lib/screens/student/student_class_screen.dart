import 'package:flutter/material.dart';

import '../../models/class_info.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import '../common/attendance_calendar.dart';

/// The old per-class student panel: announcements + my attendance, with the
/// class name, section / instructor and a Leave class button in the header.
class StudentClassScreen extends StatefulWidget {
  const StudentClassScreen({super.key, required this.classInfo});

  final ClassInfo classInfo;

  @override
  State<StudentClassScreen> createState() => _StudentClassScreenState();
}

class _StudentClassScreenState extends State<StudentClassScreen> {
  final _calendarKey = GlobalKey<AttendanceCalendarState>();
  late Future<List<dynamic>> _announcements;
  late Future<List<dynamic>> _excuses;

  @override
  void initState() {
    super.initState();
    _announcements = _load('/classes/${widget.classInfo.id}/announcements');
    _excuses = _load('/attendance/excuses/${widget.classInfo.id}');
  }

  Future<List<dynamic>> _load(String path) async {
    final data = await ApiClient.instance.get(path);
    return data as List? ?? [];
  }

  void _refreshExcuses() => setState(() {
        _excuses = _load('/attendance/excuses/${widget.classInfo.id}');
      });

  Future<void> _leave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const GradientText('Leave class?'),
        content: const Text(
          'Your private notes in this class will be removed. You will need the '
          'class code to join again.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
              label: 'Leave',
              icon: Icons.exit_to_app,
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.instance.post('/classes/${widget.classInfo.id}/leave');
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteNote(String day) async {
    try {
      await ApiClient.instance
          .delete('/attendance/excuse/${widget.classInfo.id}/$day');
      _calendarKey.currentState?.load();
      _refreshExcuses();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classInfo;
    return DefaultTabController(
      length: 2,
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
            TextButton.icon(
              onPressed: _leave,
              icon: const Icon(Icons.exit_to_app, size: 17),
              label: const Text('Leave class'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
          bottom: TabBar(
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
              Tab(text: 'My attendance'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _announcementsPane(),
            _attendancePane(),
          ],
        ),
      ),
    );
  }

  Widget _announcementsPane() => FutureBuilder<List<dynamic>>(
        future: _announcements,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.lime));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
                child: Text('No announcements yet.',
                    style: TextStyle(color: AppColors.muted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = items[index] as Map<String, dynamic>;
              return InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['title'] ?? '',
                        style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${a['author'] ?? ''} · ${a['date'] ?? ''}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 10),
                    Text(a['body'] ?? '',
                        style: const TextStyle(color: AppColors.text)),
                  ],
                ),
              );
            },
          );
        },
      );

  Widget _attendancePane() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AttendanceCalendar(
            key: _calendarKey,
            classId: widget.classInfo.id,
            canAddExcuse: true,
            onChanged: _refreshExcuses,
          ),
          const SizedBox(height: 16),
          _notesCard(),
        ],
      );

  Widget _notesCard() => FutureBuilder<List<dynamic>>(
        future: _excuses,
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your saved notes',
                    style: TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (notes.isEmpty)
                  const Text('No private notes saved yet.',
                      style: TextStyle(color: AppColors.muted))
                else
                  ...notes.map((n) {
                    final item = n as Map<String, dynamic>;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: '${item['date']}  ',
                                    style: const TextStyle(
                                        color: AppColors.lime,
                                        fontWeight: FontWeight.w700)),
                                TextSpan(
                                    text: '${item['note']}',
                                    style: const TextStyle(
                                        color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.danger),
                          tooltip: 'Delete note',
                          onPressed: () => _deleteNote('${item['date']}'),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          );
        },
      );
}
