import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import 'live_camera.dart';

/// Native camera implementation for Android/iOS/desktop targets.
class LiveCameraImpl extends LiveCamera {
  CameraController? _controller;
  bool _mirrored = false;

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get mirrored => _mirrored;

  @override
  double get aspectRatio => _controller?.value.aspectRatio ?? 16 / 9;

  @override
  Future<void> initialize({required bool preferFront}) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException(
          'cameraNotFound', 'No camera found on this device.');
    }

    final wanted =
        preferFront ? CameraLensDirection.front : CameraLensDirection.back;
    final ordered = [
      ...cameras.where((c) => c.lensDirection == wanted),
      ...cameras.where((c) => c.lensDirection != wanted),
    ];

    Object? lastError;
    for (final camera in ordered) {
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      try {
        await controller.initialize();
        _controller = controller;
        _mirrored = camera.lensDirection != CameraLensDirection.back;
        return;
      } catch (e) {
        lastError = e;
        await controller.dispose();
      }
    }
    throw CameraException('cameraNotFound', '$lastError');
  }

  @override
  Future<Uint8List> captureBytes({int maxWidth = 720}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraException('cameraNotInitialized', 'Camera is not ready.');
    }
    final picture = await controller.takePicture();
    return picture.readAsBytes();
  }

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    final preview = CameraPreview(controller);
    return _mirrored ? Transform.flip(flipX: true, child: preview) : preview;
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) await controller.dispose();
  }
}
