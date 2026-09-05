import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../live/locate_session.dart';
import '../normalize_result.dart';
import '../result/result_parser.dart';
import '../src/document_reader_sdk_platform_interface.dart';

/// Drop-in document camera: live locate + Capture → [recognize].
class DocumentCapture extends StatefulWidget {
  const DocumentCapture({
    super.key,
    this.settings = const LocateSettings(),
    required this.onRecognized,
    this.onCancel,
    this.authenticity = true,
    this.authenticityMode,
  });

  final LocateSettings settings;
  final void Function(String json) onRecognized;
  final VoidCallback? onCancel;
  final bool authenticity;
  final String? authenticityMode;

  @override
  State<DocumentCapture> createState() => _DocumentCaptureState();
}

class _DocumentCaptureState extends State<DocumentCapture> {
  CameraController? _camera;
  LocateSession? _session;
  bool _ready = false;
  bool _busy = false;
  bool _captureEnabled = false;
  int _scorePct = 0;
  List<Point>? _corners;
  String? _latestPath;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    unawaited(_session?.dispose());
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      _session = LocateSession(
        settings: widget.settings,
        onFrame: (frame) {
          if (!mounted || _busy) return;
          setState(() {
            _scorePct = frame.scorePct;
            _corners = frame.corners;
            _captureEnabled =
                frame.scorePct >= widget.settings.keepCaptureMin;
            if (_captureEnabled) _latestPath = frame.path;
          });
        },
      );
      await _session!.attach(controller);
      await _session!.start();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  Future<void> _capture() async {
    final path = _latestPath;
    if (path == null || _busy) return;
    setState(() => _busy = true);
    await _session?.stop();
    try {
      final json = normalizeResultJson(
        await DocumentReaderSdkPlatform.instance.recognize(
          path,
          null,
          widget.authenticityMode ??
              (widget.authenticity ? 'normal' : 'none'),
        ),
      );
      widget.onRecognized(json);
    } catch (_) {
      await _session?.start();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    if (!_ready || cam == null || !cam.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _session?.updateViewSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(cam),
            if (_corners != null)
              CustomPaint(painter: _QuadPainter(corners: _corners!)),
            if (widget.onCancel != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 16,
                child: IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '$_scorePct%',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _captureEnabled && !_busy ? _capture : null,
                  child: Text(_busy ? 'Reading…' : 'Capture'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter({required this.corners});

  final List<Point> corners;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length < 4) return;
    final path = Path()..moveTo(corners[0].x, corners[0].y);
    for (var i = 1; i < 4; i++) {
      path.lineTo(corners[i].x, corners[i].y);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFF60A5FA),
    );
  }

  @override
  bool shouldRepaint(covariant _QuadPainter old) => old.corners != corners;
}
