import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'live_camera.dart';

int _cameraViewCounter = 0;

/// Web implementation that asks the browser directly for a camera stream.
/// This avoids camera_web's availableCameras() metadata requirement.
class LiveCameraImpl extends LiveCamera {
  html.MediaStream? _stream;
  html.VideoElement? _video;
  String? _viewType;
  bool _mirrored = false;

  @override
  bool get isInitialized =>
      _video?.videoWidth != null && _video!.videoWidth! > 0;

  @override
  bool get mirrored => _mirrored;

  @override
  double get aspectRatio {
    final video = _video;
    if (video == null || !isInitialized) return 16 / 9;
    return video.videoWidth! / video.videoHeight!;
  }

  Future<html.MediaStream> _getUserMedia(bool preferFront) async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw StateError('This browser does not expose camera devices.');
    }
    final preferred = jsify({
      'audio': false,
      'video': {
        'facingMode': preferFront ? 'user' : 'environment',
      },
    });
    try {
      return await promiseToFuture<html.MediaStream>(
        callMethod(mediaDevices, 'getUserMedia', [preferred]),
      );
    } catch (_) {
      // Some desktop cameras do not implement facingMode constraints.
      final fallback = jsify({'audio': false, 'video': true});
      return await promiseToFuture<html.MediaStream>(
        callMethod(mediaDevices, 'getUserMedia', [fallback]),
      );
    }
  }

  @override
  Future<void> initialize({required bool preferFront}) async {
    await dispose();

    final stream = await _getUserMedia(preferFront);
    _mirrored = preferFront;
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '');
    setProperty(video, 'srcObject', stream);
    video.style
      ..setProperty('width', '100%')
      ..setProperty('height', '100%')
      ..setProperty('display', 'block')
      ..setProperty('object-fit', 'cover')
      ..setProperty('transform-origin', 'center');
    if (_mirrored) video.style.setProperty('transform', 'scaleX(-1)');

    await video.play();

    _stream = stream;
    _video = video;

    _viewType = 'live-camera-$_cameraViewCounter';
    _cameraViewCounter++;
    ui.platformViewRegistry
        .registerViewFactory(_viewType!, (int viewId) => video);
  }

  @override
  Future<Uint8List> captureBytes({int maxWidth = 720}) async {
    final video = _video;
    final srcWidth = video?.videoWidth ?? 0;
    final srcHeight = video?.videoHeight ?? 0;
    if (video == null || srcWidth == 0 || srcHeight == 0) {
      throw StateError('Camera is not ready.');
    }

    // Encode a smaller frame: JPEG + base64 + JSON get much cheaper, and the
    // backend detects at this width directly instead of rescaling a full frame.
    final scale =
        maxWidth > 0 && srcWidth > maxWidth ? maxWidth / srcWidth : 1.0;
    final outWidth = (srcWidth * scale).round();
    final outHeight = (srcHeight * scale).round();
    final canvas = html.CanvasElement(width: outWidth, height: outHeight);
    final context = canvas.getContext('2d') as html.CanvasRenderingContext2D;
    // dart:html exposes only the 3-argument drawImage; call the DOM method
    // directly so the canvas can scale the video while encoding.
    callMethod(context, 'drawImage', [video, 0, 0, outWidth, outHeight]);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.72);
    return base64.decode(dataUrl.split(',').last);
  }

  @override
  Widget buildPreview() {
    final viewType = _viewType;
    if (viewType == null) return const SizedBox.expand();
    return HtmlElementView(viewType: viewType);
  }

  @override
  Future<void> dispose() async {
    final stream = _stream;
    _stream = null;
    _video = null;
    _viewType = null;
    if (stream != null) {
      for (final track in stream.getVideoTracks()) {
        track.stop();
      }
    }
  }
}
