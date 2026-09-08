import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';

import '../result/result_parser.dart';
import '../src/document_reader_sdk_platform_interface.dart';
import 'camera_frame_jpeg.dart';

Future<String> _locate(String image) {
  return DocumentReaderSdkPlatform.instance.locateDocument(image);
}

class LocateSettings {
  const LocateSettings({
    this.showThreshold = 50,
    this.highThreshold = 85,
    this.keepCaptureMin = 50,
    this.pollMs = 450,
  });

  final int showThreshold;
  final int highThreshold;
  final int keepCaptureMin;
  final int pollMs;
}

class LocateFrame {
  const LocateFrame({
    required this.scorePct,
    required this.corners,
    required this.path,
    required this.high,
    required this.show,
  });

  final int scorePct;
  final List<Point>? corners;
  final String path;
  final bool high;
  final bool show;
}

class LocateSession {
  LocateSession({
    this.settings = const LocateSettings(),
    required this.onFrame,
  });

  final LocateSettings settings;
  final void Function(LocateFrame frame) onFrame;

  CameraController? _camera;
  Size viewSize = Size.zero;
  bool _streaming = false;
  bool _locating = false;
  bool _stopped = false;
  int _lastPollMs = 0;

  Future<void> attach(CameraController camera) async {
    _camera = camera;
  }

  void updateViewSize(Size size) {
    viewSize = size;
  }

  Future<void> start() async {
    _stopped = false;
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || _streaming) return;
    await cam.startImageStream(_onCameraImage);
    _streaming = true;
  }

  Future<void> stop() async {
    _stopped = true;
    final cam = _camera;
    if (cam == null || !_streaming) return;
    try {
      if (cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
    } catch (_) {}
    _streaming = false;
  }

  Future<void> dispose() => stop();

  void _onCameraImage(CameraImage image) {
    if (_stopped || _locating) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPollMs < settings.pollMs) return;
    _lastPollMs = now;
    _locating = true;
    unawaited(_processFrame(image));
  }

  Future<void> _processFrame(CameraImage image) async {
    String? path;
    try {
      path = await writeCameraFrameJpeg(image, quality: 60);
      if (path == null || _stopped || _camera == null) return;

      final locateJson = await _locate(path);
      final pct = documentPercent(locateJson);
      final pts = documentCorners(locateJson);
      final show = pct >= settings.showThreshold && pts != null;
      final high = pct >= settings.highThreshold;

      final imageSize = locateImageSize(locateJson) ??
          uprightSnapshotSize(
            _camera!.value.previewSize?.height ?? image.height.toDouble(),
            _camera!.value.previewSize?.width ?? image.width.toDouble(),
          );

      final mapped = (pts != null && show && viewSize.width > 0)
          ? mapUprightCornersToView(
              pts,
              imageSize.width,
              imageSize.height,
              viewSize.width,
              viewSize.height,
            )
          : null;

      onFrame(LocateFrame(
        scorePct: pct,
        corners: mapped,
        path: path,
        high: high,
        show: show,
      ));
      path = null;
    } catch (_) {
    } finally {
      if (path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
      _locating = false;
    }
  }
}
