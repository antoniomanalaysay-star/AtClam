import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/class_info.dart';
import '../../services/api_client.dart';
import '../../services/live_camera.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';

/// Instructor's phone camera: streams frames to the backend, which recognises
/// students and marks the attendance live.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.classInfo});

  final ClassInfo classInfo;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final FlutterTts _tts = FlutterTts();

  final LiveCamera _liveCamera = createLiveCamera();

  Timer? _timer;
  bool _busy = false;
  bool _useFrontCamera = false;
  bool _mirrorPreview = false;
  bool _cameraPermissionNeeded = false;
  bool _starting = false;
  bool _sessionActive = false;
  String? _error;
  List<dynamic> _faces = [];
  List<dynamic> _roster = [];
  List<int>? _meshContours;
  List<int>? _meshIrises;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _checkSession();
    _initTts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_liveCamera.dispose());
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.92);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Speech is optional; scanning still works if the platform has no voice.
    }
  }

  Future<bool> _requestCameraAccess() async {
    // Web asks for permission inside getUserMedia during camera initialization.
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied && !kIsWeb) {
        await openAppSettings();
      }
      return status.isGranted || status.isLimited;
    } catch (_) {
      // On some browsers the camera plugin performs its own prompt; let it try.
      return true;
    }
  }

  Future<void> _retryCameraAccess() async {
    if (mounted) setState(() => _error = null);
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final granted = await _requestCameraAccess();
      if (!granted && !kIsWeb) {
        if (mounted) {
          setState(() {
            _cameraPermissionNeeded = true;
            _error = 'Camera permission was denied. Allow it, then retry.';
          });
        }
        return;
      }

      await _liveCamera.dispose();
      await _liveCamera.initialize(preferFront: _useFrontCamera);
      if (!mounted) {
        await _liveCamera.dispose();
        return;
      }
      setState(() {
        _mirrorPreview = _liveCamera.mirrored;
        _cameraPermissionNeeded = false;
        _error = null;
      });
      _startStreaming();
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraPermissionNeeded = true;
          _error = kIsWeb
              ? 'Camera unavailable. Allow camera access in your browser, then retry. $e'
              : 'Camera error: $e';
        });
      }
    }
  }

  void _switchCamera() {
    setState(() => _useFrontCamera = !_useFrontCamera);
    unawaited(_initCamera());
  }

  Future<void> _checkSession() async {
    try {
      final data = await ApiClient.instance.get('/attendance/session');
      if (mounted) {
        setState(() => _sessionActive = data['active'] as bool? ?? false);
      }
    } on ApiException {
      // The start button remains available.
    }
  }

  void _startStreaming() {
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(milliseconds: 380), (_) => _sendFrame());
  }

  static List<int> _readIndices(Object? value) {
    final raw = value as List?;
    if (raw == null) return const <int>[];
    return raw.map((e) => (e as num).toInt()).toList(growable: false);
  }

  Future<void> _sendFrame() async {
    if (_busy || !_sessionActive || !_liveCamera.isInitialized || !mounted) {
      return;
    }
    _busy = true;
    try {
      final bytes = await _liveCamera.captureBytes(maxWidth: 720);
      final data = await ApiClient.instance.post('/attendance/frame',
          body: {'image': ApiClient.encodeImage(bytes)});
      if (!mounted) return;
      final announcements = data['announcements'] as List? ?? [];
      final layout = data['mesh_layout'] as Map?;
      final contours = layout == null ? null : _readIndices(layout['contours']);
      final irises = layout == null ? null : _readIndices(layout['irises']);
      setState(() {
        _faces = data['faces'] as List? ?? [];
        _roster = data['roster'] as List? ?? [];
        if (contours != null) _meshContours = contours;
        if (irises != null) _meshIrises = irises;
        _error = null;
      });
      // The backend only sends an announcement when a student is newly marked,
      // so an already-present face never triggers speech.
      unawaited(_speakAnnouncements(announcements));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      // A frame can fail while the camera is focusing; the next one will work.
    } finally {
      _busy = false;
    }
  }

  Future<void> _speakAnnouncements(List<dynamic> announcements) async {
    for (final entry in announcements) {
      final item = entry as Map<String, dynamic>;
      final first = '${item['first_name'] ?? ''}'.trim();
      if (first.isEmpty) continue;
      try {
        await _tts.speak('$first Present');
      } catch (_) {
        // Ignore TTS failures; visual attendance feedback still works.
      }
    }
  }

  Future<void> _startClass() async {
    setState(() => _starting = true);
    unawaited(_initTts()); // Browsers often unlock speech on a user gesture.
    try {
      await ApiClient.instance.post('/attendance/session/start',
          body: {'class_id': widget.classInfo.id});
      if (!mounted) return;
      setState(() => _sessionActive = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _endClass() async {
    _timer?.cancel();
    try {
      await ApiClient.instance.post('/attendance/session/end');
      if (!mounted) return;
      setState(() {
        _sessionActive = false;
        _faces = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class ended. Attendance saved.')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
      _startStreaming();
    }
  }

  Color _stateColor(String state) => switch (state) {
        'present' => AppColors.leaf,
        'blink' => AppColors.warn,
        'unknown' => AppColors.danger,
        _ => AppColors.muted,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GradientText(
          'Scan · ${widget.classInfo.name}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          _HoverIconButton(
            tooltip: 'Switch camera',
            icon: Icons.cameraswitch_outlined,
            onPressed: _switchCamera,
          ),
          _HoverIconButton(
            tooltip: 'Refresh roster',
            icon: Icons.refresh,
            onPressed: () =>
                ApiClient.instance.get('/attendance/session').then((data) {
              if (mounted) {
                setState(() {
                  _sessionActive = data['active'] as bool? ?? false;
                  _roster = data['roster'] as List? ?? [];
                });
              }
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              hover: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: AppColors.alpha(0x0E2749, 0.35),
              child: Row(
                children: [
                  AvatarTile(widget.classInfo.name, classTile: true, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GradientText(
                          'Live scan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.classInfo.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppPill(
                    _sessionActive ? 'SESSION LIVE' : 'SESSION IDLE',
                    kind: _sessionActive ? AppPillKind.lime : AppPillKind.muted,
                    icon: Icons.circle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 12),
            ],
            if (_cameraPermissionNeeded) ...[
              AppButton(
                label: 'Allow camera / Retry',
                icon: Icons.camera_alt,
                fullWidth: true,
                onPressed: _retryCameraAccess,
              ),
              const SizedBox(height: 12),
            ],
            if (!_sessionActive)
              GlassCard(
                hover: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      'Start the class first',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Students are marked Present before the Late time and '
                      'Late after it. Everyone not seen when the class ends '
                      'is marked Absent.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Start class',
                      loading: _starting,
                      onPressed: _starting ? null : _startClass,
                    ),
                  ],
                ),
              ),
            if (_sessionActive) ...[
              _buildPreview(),
              const SizedBox(height: 12),
              GlassCard(
                hover: true,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Reset tracking',
                        icon: Icons.restart_alt,
                        variant: AppButtonVariant.outline,
                        fullWidth: true,
                        onPressed: () =>
                            ApiClient.instance.post('/attendance/frame/reset'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'End class',
                        icon: Icons.stop_circle_outlined,
                        variant: AppButtonVariant.danger,
                        fullWidth: true,
                        onPressed: _endClass,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                hover: true,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GradientText(
                          'Detected (${_faces.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        AppPill('${_faces.length}', kind: AppPillKind.gold),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_faces.isEmpty)
                      const Text('Point the phone at your students…',
                          style: TextStyle(color: AppColors.muted))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _faces.map((f) {
                          final face = f as Map<String, dynamic>;
                          final state = '${face['state'] ?? 'checking'}';
                          return _FaceChip(
                            name: '${face['name'] ?? '?'}',
                            state: state,
                            color: _stateColor(state),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                hover: true,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GradientText(
                          'Live roster (${_roster.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        AppPill('${_roster.length}', kind: AppPillKind.lime),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._roster.map((r) {
                      final row = r as Map<String, dynamic>;
                      final status = '${row['status'] ?? 'absent'}';
                      return _HoverRosterTile(
                        name: '${row['name'] ?? ''}',
                        status: status,
                        time: '${row['time'] ?? ''}',
                        color: _stateColor(status),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (!_liveCamera.isInitialized) {
      return GlassCard(
        height: 260,
        blur: false,
        hover: true,
        padding: EdgeInsets.zero,
        color: AppColors.alpha(0x09182F, 0.75),
        borderColor: AppColors.alpha(0x0E2749, 0.8),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.lime),
              SizedBox(height: 12),
              Text('Opening camera…', style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
    }
    final overlayFaces = _faces
        .map((f) {
          final face = f as Map<String, dynamic>;
          final raw = (face['landmarks'] as List?) ?? const [];
          final points = <Offset>[];
          if (raw.isNotEmpty && raw.first is num) {
            // Dense mesh: flat [x0, y0, x1, y1, ...] from the backend.
            for (var i = 0; i + 1 < raw.length; i += 2) {
              final x = (raw[i] as num).toDouble();
              final y = (raw[i + 1] as num).toDouble();
              points.add(Offset(_mirrorPreview ? 1 - x : x, y));
            }
          } else {
            // Backward-compatible fallback for the old 13-point payload.
            for (final p in raw) {
              final pos = p as List;
              final x = (pos[0] as num).toDouble();
              points.add(Offset(
                _mirrorPreview ? 1 - x : x,
                (pos[1] as num).toDouble(),
              ));
            }
          }
          return _LandmarkFace(
            points,
            _stateColor('${face['state'] ?? 'checking'}'),
          );
        })
        .where((overlay) => overlay.points.length >= 13)
        .toList();

    return GlassCard(
      blur: false,
      hover: true,
      padding: EdgeInsets.zero,
      borderColor: AppColors.alpha(0x0E2749, 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyle.radius),
        child: AspectRatio(
          aspectRatio: _liveCamera.aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(child: _liveCamera.buildPreview()),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _FaceLandmarkPainter(
                        faces: overlayFaces,
                        contourEdges: _meshContours ?? const <int>[],
                        irisEdges: _meshIrises ?? const <int>[],
                      ),
                    ),
                  ),
                ),
                ..._faces.map((f) {
                  final face = f as Map<String, dynamic>;
                  final box = (face['box'] as List?) ?? [];
                  if (box.length != 4) return const SizedBox();
                  final rawLeft = (box[0] as num).toDouble();
                  final top = (box[1] as num).toDouble();
                  final rawRight = (box[2] as num).toDouble();
                  final bottom = (box[3] as num).toDouble();
                  // Front-camera preview is mirrored by camera_web, so flip the
                  // normalized coordinates back to match what the user sees.
                  final left = _mirrorPreview ? 1 - rawRight : rawLeft;
                  final right = _mirrorPreview ? 1 - rawLeft : rawRight;
                  final color = _stateColor(face['state'] ?? 'checking');
                  return Positioned(
                    left: left * constraints.maxWidth,
                    top: top * constraints.maxHeight,
                    width: (right - left) * constraints.maxWidth,
                    height: (bottom - top) * constraints.maxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.topLeft,
                      child: Container(
                        color: color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text(
                          '${face['name'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One detected face plus every normalized FaceMesh point.
class _LandmarkFace {
  const _LandmarkFace(this.points, this.color);

  final List<Offset> points;
  final Color color;
}

class _FacePart {
  const _FacePart(this.label, this.point);

  final String label;
  final Offset point;
}

/// Draws the same dense mesh as face-check: contour lines, iris lines and
/// labelled eye/nose/mouth/ear points that follow the face as it moves.
/// Text painters are static: the four labels repeat every frame, so laying
/// them out again on each repaint was wasted work on the scan screen.
class _LabelPainters {
  _LabelPainters(String text) {
    outline = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = const Color(0xFF041026),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fill = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9BC7F0),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  late final TextPainter outline;
  late final TextPainter fill;
}

class _FaceLandmarkPainter extends CustomPainter {
  const _FaceLandmarkPainter({
    required this.faces,
    required this.contourEdges,
    required this.irisEdges,
  });

  final List<_LandmarkFace> faces;
  final List<int> contourEdges;
  final List<int> irisEdges;

  static const _rightEye = [33, 160, 158, 133, 153, 144];
  static const _leftEye = [362, 385, 387, 263, 373, 380];
  static const _meshColor = Color(0xCC9BC7F0);
  static const _irisColor = Color(0xFF2C70C4);
  static final Map<String, _LabelPainters> _labels = {};

  @override
  void paint(Canvas canvas, Size size) {
    final mesh = Paint()
      ..color = _meshColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final iris = Paint()
      ..color = _irisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final dotOutline = Paint()..color = const Color(0xCC041026);
    final dotFill = Paint();

    for (final face in faces) {
      final pts = face.points
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList(growable: false);
      if (pts.isEmpty) continue;

      _drawEdges(canvas, pts, contourEdges, mesh);
      _drawEdges(canvas, pts, irisEdges, iris);

      dotFill.color = face.color;
      for (final part in _faceParts(pts)) {
        canvas.drawCircle(part.point, 5.5, dotOutline);
        canvas.drawCircle(part.point, 3.3, dotFill);
        _drawLabel(canvas, part.point + const Offset(7, -12), part.label);
      }
    }
  }

  void _drawEdges(
      Canvas canvas, List<Offset> pts, List<int> edges, Paint paint) {
    for (var i = 0; i + 1 < edges.length; i += 2) {
      final a = edges[i];
      final b = edges[i + 1];
      if (a >= pts.length || b >= pts.length) continue;
      canvas.drawLine(pts[a], pts[b], paint);
    }
  }

  List<_FacePart> _faceParts(List<Offset> pts) {
    Offset centre(List<int> ids) {
      var x = 0.0;
      var y = 0.0;
      var count = 0;
      for (final i in ids) {
        if (i >= pts.length) continue;
        x += pts[i].dx;
        y += pts[i].dy;
        count++;
      }
      return count == 0 ? Offset.zero : Offset(x / count, y / count);
    }

    Offset at(int i) => i < pts.length ? pts[i] : Offset.zero;

    return [
      _FacePart('Eye', centre(_rightEye)),
      _FacePart('Eye', centre(_leftEye)),
      _FacePart('Nose', at(1)),
      _FacePart('Mouth', at(13)),
      _FacePart('Ear', at(234)),
      _FacePart('Ear', at(454)),
    ].where((part) => part.point != Offset.zero).toList();
  }

  void _drawLabel(Canvas canvas, Offset position, String text) {
    final painters = _labels.putIfAbsent(text, () => _LabelPainters(text));
    painters.outline.paint(canvas, position);
    painters.fill.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _FaceLandmarkPainter oldDelegate) =>
      oldDelegate.faces != faces ||
      oldDelegate.contourEdges != contourEdges ||
      oldDelegate.irisEdges != irisEdges;
}

/// Refresh control with a glass hover/focus halo.
class _HoverIconButton extends StatefulWidget {
  const _HoverIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: active ? 1.08 : 1,
          duration: AppStyle.motionFor(context),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppStyle.motionFor(context),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color:
                  active ? AppColors.alpha(0x5B9FE8, 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
              border: Border.all(
                color: active ? AppStyle.strokeHover : AppStyle.stroke,
                width: AppStyle.strokeWidth,
              ),
            ),
            child: IconButton(
              tooltip: widget.tooltip,
              onPressed: widget.onPressed,
              icon: Icon(
                widget.icon,
                color: active ? AppColors.lime : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Detected face with a status dot and a hover-lifted glass pill.
class _FaceChip extends StatefulWidget {
  const _FaceChip({
    required this.name,
    required this.state,
    required this.color,
  });

  final String name;
  final String state;
  final Color color;

  @override
  State<_FaceChip> createState() => _FaceChipState();
}

class _FaceChipState extends State<_FaceChip> {
  bool _hovered = false;

  AppPillKind get _kind => switch (widget.state) {
        'present' => AppPillKind.lime,
        'blink' => AppPillKind.warning,
        'unknown' => AppPillKind.danger,
        _ => AppPillKind.muted,
      };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        curve: Curves.easeOut,
        transform:
            _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.alpha(0x5B9FE8, 0.16)
              : AppColors.alpha(0x0E2749, 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _hovered ? AppStyle.strokeHover : AppStyle.strokeRaised,
            width: AppStyle.strokeWidth,
          ),
          boxShadow: _hovered ? AppStyle.hoverShadow : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: _hovered ? 10 : 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.name,
              style: TextStyle(
                color: _hovered ? AppColors.lime : AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            AppPill(widget.state.toUpperCase(), kind: _kind),
          ],
        ),
      ),
    );
  }
}

/// Roster row with the same lime hover glide as the other dashboards.
class _HoverRosterTile extends StatefulWidget {
  const _HoverRosterTile({
    required this.name,
    required this.status,
    required this.time,
    required this.color,
  });

  final String name;
  final String status;
  final String time;
  final Color color;

  @override
  State<_HoverRosterTile> createState() => _HoverRosterTileState();
}

class _HoverRosterTileState extends State<_HoverRosterTile> {
  bool _hovered = false;

  AppPillKind get _kind => switch (widget.status) {
        'present' => AppPillKind.lime,
        'blink' => AppPillKind.warning,
        'unknown' => AppPillKind.danger,
        _ => AppPillKind.muted,
      };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppStyle.motionFor(context),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            AvatarTile(widget.name, size: 34),
            const SizedBox(width: 10),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: _hovered ? 10 : 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _hovered ? AppColors.lime : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppPill(
              '${widget.status.toUpperCase()} ${widget.time}'.trim(),
              kind: _kind,
            ),
          ],
        ),
      ),
    );
  }
}
