import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';
import '../common/legacy_shell.dart';
import '../common/live_camera_panel.dart';
import '../common/profile_screen.dart';

/// Admin-only tweaks: softer corners, borderless glass and white body text.
const double _adminCorner = 8.0;
const double _adminInputCorner = 6.0;
const Color _adminBorder = AppStyle.stroke;
const Color _adminHoverBorder = AppStyle.strokeHover;

InputDecoration _adminInputDecoration(
  String label, {
  IconData? icon,
  bool dense = false,
}) {
  OutlineInputBorder border(Color color,
          [double width = AppStyle.strokeWidth]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(_adminInputCorner),
        borderSide: BorderSide(color: color, width: width),
      );

  return AppStyle.inputDecoration(
    label,
    icon: icon,
    dense: dense,
    borderColor: _adminBorder,
  ).copyWith(
    labelStyle: const TextStyle(color: AppColors.muted),
    floatingLabelStyle: const TextStyle(color: AppColors.lime),
    hintStyle: const TextStyle(color: AppColors.hint),
    border: border(_adminBorder),
    enabledBorder: border(AppStyle.strokeRaised),
    focusedBorder: border(AppColors.lime, 1.4),
    errorBorder: border(AppColors.danger, 1.2),
    focusedErrorBorder: border(AppColors.danger, 1.4),
  );
}

ThemeData _adminDialogThemeData(BuildContext context) =>
    Theme.of(context).copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: AppStyle.glassRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_adminCorner),
          side: const BorderSide(
            color: _adminBorder,
            width: AppStyle.strokeWidth,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );

class _AdminPageTitle extends StatelessWidget {
  const _AdminPageTitle(this.title, {required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
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
        ],
      );
}

class _AdminData {
  _AdminData(this.students, this.instructors, this.classes);

  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> instructors;
  final List<Map<String, dynamic>> classes;
}

/// Administration page: glass stat cards, segmented tabs with counts, a live
/// search field and a table with hover-highlighted rows.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _tab = 'student';
  String _query = '';
  late Future<_AdminData> _data;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _data = _load();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<_AdminData> _load() async {
    final results = await Future.wait([
      ApiClient.instance.get('/admin/users', query: {'role': 'student'}),
      ApiClient.instance.get('/admin/users', query: {'role': 'instructor'}),
      ApiClient.instance.get('/admin/classes'),
    ]);
    List<Map<String, dynamic>> rows(dynamic value) =>
        (value as List? ?? []).cast<Map<String, dynamic>>();
    return _AdminData(rows(results[0]), rows(results[1]), rows(results[2]));
  }

  void _refresh() => setState(() {
        _data = _load();
      });

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _setTab(String tab) {
    setState(() {
      _tab = tab;
      _query = '';
      _search.clear();
    });
  }

  Future<void> _delete(String kind, Map<String, dynamic> row) async {
    final name = row['full_name'] ?? row['name'] ?? 'this record';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: _adminDialogThemeData(ctx),
        child: AlertDialog(
          title: const GradientText('Delete record?'),
          content: Text(
              'Delete ${kind == 'classes' ? 'class' : 'account'} $name?',
              style: const TextStyle(color: Colors.white)),
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
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.instance.delete('/admin/$kind/${row['id']}');
      _refresh();
      _toast('Deleted.');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _openEditor(_AdminData data, {Map<String, dynamic>? row}) async {
    final isClass = _tab == 'classes';
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AdminEditor(
        isClass: isClass,
        row: row,
        tab: _tab,
        instructors: data.instructors,
      ),
    );
    if (saved == true) {
      _refresh();
      _toast('Saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LegacyShell(
      user: Session.instance.user!,
      destinations: [
        LegacyDestination(
            label: 'People & classes',
            icon: Icons.admin_panel_settings_outlined,
            child: _workspace()),
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

  Widget _workspace() => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _AdminPageTitle(
              'Administration',
              subtitle:
                  'Manage instructors, students and every class in the system.',
            ),
            const SizedBox(height: 18),
            FutureBuilder<_AdminData>(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: AppColors.lime)));
                }
                if (snapshot.hasError) {
                  return ErrorBanner((snapshot.error as ApiException).message);
                }
                final data = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _StatCard('Instructors', data.instructors.length,
                            icon: Icons.school_outlined),
                        _StatCard('Students', data.students.length,
                            icon: Icons.people_outline),
                        _StatCard('Classes', data.classes.length,
                            icon: Icons.class_outlined),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _recordsCard(data),
                  ],
                );
              },
            ),
          ],
        ),
      );

  String get _addLabel => _tab == 'classes'
      ? 'Add class'
      : (_tab == 'instructor' ? 'Add instructor' : 'Add student');

  Widget _recordsCard(_AdminData data) => GlassCard(
        radius: _adminCorner,
        borderColor: _adminBorder,
        hoverBorderColor: _adminHoverBorder,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
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
                const Text('Records',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                AppButton(
                  label: _addLabel,
                  icon: Icons.add,
                  onPressed: () => _openEditor(data),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: _adminBorder, height: 1),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0x99050E21),
                    borderRadius: BorderRadius.circular(_adminCorner),
                    border: Border.all(
                      color: _adminBorder,
                      width: AppStyle.strokeWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TabButton('Students', data.students.length,
                          active: _tab == 'student',
                          onTap: () => _setTab('student')),
                      _TabButton('Instructors', data.instructors.length,
                          active: _tab == 'instructor',
                          onTap: () => _setTab('instructor')),
                      _TabButton('Classes', data.classes.length,
                          active: _tab == 'classes',
                          onTap: () => _setTab('classes')),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: AppStyle.motionFor(context),
                  width: _searchFocus.hasFocus ? 400 : 300,
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.sizeOf(context).width > 700 ? 400 : 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_adminInputCorner),
                    boxShadow: _searchFocus.hasFocus
                        ? [
                            BoxShadow(
                              color: AppColors.alpha(0x5B9FE8, 0.22),
                              blurRadius: 0,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    style: const TextStyle(color: AppColors.text),
                    cursorColor: AppColors.lime,
                    decoration: _adminInputDecoration(
                      'Search $_tab',
                      icon: Icons.search,
                      dense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _table(data),
          ],
        ),
      );

  Widget _table(_AdminData data) {
    final isClass = _tab == 'classes';
    final source = isClass
        ? data.classes
        : (_tab == 'instructor' ? data.instructors : data.students);
    final rows = _query.isEmpty
        ? source
        : source
            .where((row) => row.toString().toLowerCase().contains(_query))
            .toList();
    final headers = isClass
        ? ['Class', 'Code', 'Instructor', 'Students', 'Schedule', 'Actions']
        : ['Name', 'Username', 'Section', 'Face', 'Actions'];
    final flexes = isClass ? const [3, 1, 2, 1, 2, 2] : const [3, 2, 1, 2, 2];

    return ClipRRect(
      borderRadius: BorderRadius.circular(_adminCorner),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x9904122A),
          borderRadius: BorderRadius.circular(_adminCorner),
          border: Border.all(
            color: _adminBorder,
            width: AppStyle.strokeWidth,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth =
                constraints.maxWidth.isFinite && constraints.maxWidth > 880
                    ? constraints.maxWidth
                    : 880.0;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xD904122A),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < headers.length; i++)
                            Expanded(
                              flex: flexes[i],
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  headers[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Text(
                          _query.isNotEmpty
                              ? 'No matches found.'
                              : 'No ${_tab} yet. Use “$_addLabel” to create the first one.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    else
                      ...rows.map((row) => _TableRow(
                            flexes: flexes,
                            cells: isClass
                                ? _classCells(row, data)
                                : _userCells(row),
                          )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _userCells(Map<String, dynamic> row) => [
        _identity('${row['full_name'] ?? ''}', '${row['email'] ?? ''}'),
        _cell(Text('${row['username'] ?? ''}',
            style: const TextStyle(color: AppColors.text))),
        _cell((row['section'] ?? '').toString().isEmpty
            ? const Text('—', style: TextStyle(color: Colors.white))
            : AppPill('${row['section']}')),
        _cell(row['role'] == 'instructor'
            ? const AppPill('Not required', kind: AppPillKind.muted)
            : (row['has_face'] == true
                ? const AppPill('Registered', kind: AppPillKind.lime)
                : const AppPill('No photos', kind: AppPillKind.warning))),
        _actions([
          AppButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              variant: AppButtonVariant.outline,
              minimumSize: const Size(0, 34),
              fontSize: 12,
              onPressed: () => _openEditor(_AdminData([], [], []), row: row)),
          AppButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              variant: AppButtonVariant.dangerOutline,
              minimumSize: const Size(0, 34),
              fontSize: 12,
              onPressed: () => _delete('users', row)),
        ]),
      ];

  List<Widget> _classCells(Map<String, dynamic> row, _AdminData data) {
    final start = _shortTime('${row['present_time'] ?? ''}');
    final end = _shortTime('${row['end_time'] ?? ''}');
    final late = _shortTime('${row['late_time'] ?? ''}');
    return [
      _identity(
        '${row['name'] ?? ''}',
        '${row['description'] ?? ''}'.isEmpty
            ? 'No description'
            : '${row['description']}',
        classTile: true,
      ),
      _cell(AppPill('${row['code'] ?? ''}', kind: AppPillKind.gold)),
      _cell(Text(
        '${row['instructor_name'] ?? ''}'.isEmpty
            ? 'Unassigned'
            : '${row['instructor_name']}',
        style: TextStyle(color: Colors.white),
      )),
      _cell(Text('${row['student_count'] ?? 0}',
          style: const TextStyle(
              color: AppColors.text, fontWeight: FontWeight.w700))),
      _cell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            start.isNotEmpty && end.isNotEmpty ? '$start–$end' : 'Not set',
            style: const TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w700),
          ),
          if (late.isNotEmpty)
            Text('Late after $late',
                style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      )),
      _actions([
        AppButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.outline,
            minimumSize: const Size(0, 34),
            fontSize: 12,
            onPressed: () => _openEditor(data, row: row)),
        AppButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            variant: AppButtonVariant.dangerOutline,
            minimumSize: const Size(0, 34),
            fontSize: 12,
            onPressed: () => _delete('classes', row)),
      ]),
    ];
  }

  Widget _cell(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: child,
      );

  Widget _identity(String name, String sub, {bool classTile = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            AvatarTile(name, classTile: classTile),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(sub,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _actions(List<Widget> buttons) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 6,
          children: buttons,
        ),
      );

  static String _shortTime(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
}

/// Centred stat tile with a radial glow and hover lift, as in admin.php.
class _StatCard extends StatefulWidget {
  const _StatCard(this.label, this.value, {this.icon});

  final String label;
  final int value;
  final IconData? icon;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        curve: Curves.easeOut,
        transform:
            _hovered ? Matrix4.translationValues(0, -4, 0) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        constraints: const BoxConstraints(minWidth: 170),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xC404122A) : const Color(0x9904122A),
          borderRadius: BorderRadius.circular(_adminCorner),
          border: Border.all(
            color: _hovered ? _adminHoverBorder : _adminBorder,
            width: AppStyle.strokeWidth,
          ),
          boxShadow: _hovered ? AppStyle.hoverShadow : AppStyle.cardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: AnimatedContainer(
                duration: AppStyle.motionFor(context),
                width: _hovered ? 140 : 100,
                height: _hovered ? 140 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.alpha(0x5B9FE8, _hovered ? 0.35 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: AppStyle.motionFor(context),
                  style: TextStyle(
                    color: _hovered ? AppColors.lime : Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  child: Text('${widget.value}'),
                ),
                const SizedBox(width: 12),
                AnimatedDefaultTextStyle(
                  duration: AppStyle.motionFor(context),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  child: widget.icon == null
                      ? Text(widget.label)
                      : Row(
                          children: [
                            Icon(widget.icon, size: 14),
                            const SizedBox(width: 6),
                            Text(widget.label),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented tab button with a count badge and hover state.
class _TabButton extends StatefulWidget {
  const _TabButton(this.label, this.count,
      {required this.active, required this.onTap});

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          transform: _hovered
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: widget.active
                ? null
                : (_hovered
                    ? AppColors.alpha(0x5B9FE8, 0.15)
                    : Colors.transparent),
            gradient: widget.active ? AppStyle.activeGradient : null,
            borderRadius: BorderRadius.circular(_adminInputCorner),
            border: Border.all(
              color: highlighted ? _adminHoverBorder : _adminBorder,
              width: AppStyle.strokeWidth,
            ),
            boxShadow: highlighted ? AppStyle.hoverShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: widget.active
                      ? Colors.white.withAlpha(60)
                      : Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(_adminInputCorner),
                ),
                child: Text(
                  '${widget.count}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Table row with the admin.php hover highlight and inset lime edge.
class _TableRow extends StatefulWidget {
  const _TableRow({required this.cells, required this.flexes});

  final List<Widget> cells;
  final List<int> flexes;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        decoration: BoxDecoration(
          color:
              _hovered ? AppColors.alpha(0x5B9FE8, 0.07) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppStyle.stroke,
              width: AppStyle.strokeWidth,
            ),
          ),
        ),
        child: Stack(
          children: [
            if (_hovered)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: Container(color: AppColors.lime),
              ),
            Row(
              children: [
                for (var i = 0; i < widget.cells.length; i++)
                  Expanded(flex: widget.flexes[i], child: widget.cells[i]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- editor
class _AdminEditor extends StatefulWidget {
  const _AdminEditor({
    required this.isClass,
    required this.row,
    required this.tab,
    required this.instructors,
  });

  final bool isClass;
  final Map<String, dynamic>? row;
  final String tab;
  final List<Map<String, dynamic>> instructors;

  @override
  State<_AdminEditor> createState() => _AdminEditorState();
}

class _AdminEditorState extends State<_AdminEditor> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _section;
  late final TextEditingController _password;
  late final TextEditingController _description;
  late String _role;
  int? _instructorId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    _name =
        TextEditingController(text: row?['full_name'] ?? row?['name'] ?? '');
    _username = TextEditingController(text: row?['username'] ?? '');
    _email = TextEditingController(text: row?['email'] ?? '');
    _section = TextEditingController(text: row?['section'] ?? '');
    _password = TextEditingController();
    _description = TextEditingController(text: row?['description'] ?? '');
    _role =
        row?['role'] ?? (widget.tab == 'instructor' ? 'instructor' : 'student');
    _instructorId = row?['instructor_id'] == null
        ? null
        : (row!['instructor_id'] as num).toInt();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _username,
      _email,
      _section,
      _password,
      _description
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Fill in the name field.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final editing = widget.row != null;
      if (widget.isClass) {
        final body = <String, dynamic>{
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'section':
              _section.text.trim().isEmpty ? 'General' : _section.text.trim(),
          'instructor_id': _instructorId,
          'present_time': '${widget.row?['present_time'] ?? '08:00'}',
          'late_time': '${widget.row?['late_time'] ?? '08:15'}',
          'end_time': '${widget.row?['end_time'] ?? '09:00'}',
        };
        if (editing) {
          await ApiClient.instance
              .put('/admin/classes/${widget.row!['id']}', body: body);
        } else {
          await ApiClient.instance.post('/admin/classes', body: body);
        }
      } else if (editing) {
        final body = <String, dynamic>{
          'name': _name.text.trim(),
          'username': _username.text.trim(),
          'email': _email.text.trim(),
          'role': _role,
          'section': _section.text.trim(),
          'school_id': widget.row!['school_id'] ?? '',
        };
        if (_password.text.isNotEmpty) body['password'] = _password.text;
        await ApiClient.instance
            .put('/admin/users/${widget.row!['id']}', body: body);
      } else {
        final body = <String, dynamic>{
          'full_name': _name.text.trim(),
          'username': _username.text.trim(),
          'email': _email.text.trim(),
          'role': _role,
          'section': _section.text.trim(),
        };
        if (_password.text.isNotEmpty) body['password'] = _password.text;
        await ApiClient.instance.post('/admin/users', body: body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _adminDialogThemeData(context),
      child: AlertDialog(
        title: GradientText(
          widget.isClass
              ? (widget.row == null ? 'Add class' : 'Rename / edit class')
              : (widget.row == null
                  ? 'Add ${widget.tab == 'instructor' ? 'instructor' : 'student'}'
                  : 'Edit account'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isClass) ...[
                  AppTextField(
                      controller: _name,
                      label: 'Class name',
                      icon: Icons.class_outlined),
                  const SizedBox(height: 12),
                  AppTextField(
                      controller: _description,
                      label: 'Description',
                      icon: Icons.description_outlined),
                  const SizedBox(height: 12),
                  AppTextField(
                      controller: _section,
                      label: 'Section',
                      icon: Icons.groups_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _instructorId,
                    hint: const Text('Unassigned'),
                    dropdownColor: const Color(0xFF09182F),
                    decoration: _adminInputDecoration('Instructor'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Unassigned')),
                      ...widget.instructors.map((i) => DropdownMenuItem<int?>(
                            value: (i['id'] as num).toInt(),
                            child: Text('${i['full_name'] ?? ''}'),
                          )),
                    ],
                    onChanged: (value) => setState(() => _instructorId = value),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                          child: AppTextField(
                              controller: _name, label: 'Full name')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: AppTextField(
                              controller: _username, label: 'Username')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: AppTextField(
                              controller: _email,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: AppTextField(
                              controller: _section, label: 'Section')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _role,
                          dropdownColor: const Color(0xFF09182F),
                          decoration: _adminInputDecoration('Role'),
                          items: const [
                            DropdownMenuItem(
                                value: 'student', child: Text('Student')),
                            DropdownMenuItem(
                                value: 'instructor', child: Text('Instructor')),
                          ],
                          onChanged: (value) =>
                              setState(() => _role = value ?? 'student'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _password,
                          label: widget.row == null
                              ? 'Password (default: Attendance123)'
                              : 'Password (blank keeps current)',
                          obscure: true,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  ErrorBanner(_error!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(label: 'Save', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
