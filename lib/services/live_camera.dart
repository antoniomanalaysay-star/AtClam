import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'live_camera_io.dart' if (dart.library.html) 'live_camera_web.dart';

/// Camera abstraction used by the live scan screen.
///
/// On web it uses getUserMedia directly, avoiding camera_web's
/// availableCameras() lookup that can fail with cameraNotFound. On mobile it
/// wraps the regular camera plugin.
abstract class LiveCamera {
  LiveCamera();

  bool get isInitialized;

  bool get mirrored;

  double get aspectRatio;

  Future<void> initialize({required bool preferFront});

  /// Captures a JPEG frame. Web downscales to [maxWidth] before encoding,
  /// which keeps the upload small and the scan responsive.
  Future<Uint8List> captureBytes({int maxWidth = 720});

  Widget buildPreview();

  Future<void> dispose();
}

LiveCamera createLiveCamera() => LiveCameraImpl();
