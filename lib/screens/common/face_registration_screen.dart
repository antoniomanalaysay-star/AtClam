import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/app_widgets.dart';

/// Students register the 3 face photos used by the classroom camera.
class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final List<String> _photos = [];
  bool _saving = false;
  String? _error;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final index = _photos.length;
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (index < _photos.length) {
        _photos[index] = ApiClient.encodeImage(bytes);
      } else {
        _photos.add(ApiClient.encodeImage(bytes));
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_photos.length != 3) {
      setState(() => _error = 'Choose exactly 3 photos.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post('/auth/photos', body: {'photos': _photos});
      await Session.instance.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face registration saved')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFace = Session.instance.user?.hasFace ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const GradientText(
          'Face verification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: GradientText(
                              'Three clear photos of your face',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          AppPill('$_photos.length/3', kind: AppPillKind.gold),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Face the camera, keep good lighting and avoid hats or '
                        'sunglasses. The instructor\'s phone will recognise you '
                        'during class.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                      if (hasFace) ...[
                        const SizedBox(height: 12),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: AppColors.lime, size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                  'You already have a registered face. '
                                  'Uploading again replaces it.',
                                  style: TextStyle(
                                      color: AppColors.lime, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (i) {
                  final selected = i < _photos.length;
                  return _PhotoTile(
                    index: i,
                    selected: selected,
                    onTap: _saving ? null : _pick,
                  );
                }),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  ErrorBanner(_error!),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save my photos',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass photo slot with a lime hover lift and a selected-state accent.
/// [onTap] is the unchanged picker callback supplied by the parent.
class _PhotoTile extends StatefulWidget {
  const _PhotoTile({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final highlighted = _hovered || widget.selected;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppStyle.motionFor(context),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          transform: _hovered
              ? Matrix4.translationValues(4, 0, 0)
              : Matrix4.identity(),
          transformAlignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.alpha(0x5B9FE8, _hovered ? 0.18 : 0.10)
                : (_hovered
                    ? AppColors.alpha(0x5B9FE8, 0.10)
                    : AppColors.alpha(0x0E2749, 0.30)),
            borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
            border: Border.all(
              color: highlighted ? AppStyle.strokeHover : AppStyle.strokeRaised,
              width: AppStyle.strokeWidth,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.alpha(0x164C87, 0.5),
                  border: Border.all(
                    color: AppStyle.strokeRaised,
                    width: AppStyle.strokeWidth,
                  ),
                ),
                child: Icon(
                  widget.selected ? Icons.check : Icons.add_a_photo_outlined,
                  color: widget.selected ? AppColors.lime : AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo ${widget.index + 1}${widget.selected ? ' selected' : ''}',
                      style: TextStyle(
                        color:
                            widget.selected ? AppColors.lime : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Tap to choose from your gallery',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (widget.selected)
                const Icon(Icons.verified, color: AppColors.lime, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
