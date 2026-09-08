import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:document_reader_sdk/document_reader_sdk.dart';
import 'package:flutter/material.dart';

import '../../core/constants/capture.dart';
import '../../services/document_service.dart';

class DocumentController extends ChangeNotifier {
  DocumentController();

  final DocumentService _docs = DocumentService();
  LocateSession? _session;

  CameraController? camera;
  bool captured = false;
  bool busy = false;
  bool captureEnabled = false;
  int scorePct = 0;
  List<Point>? corners;
  String hint = 'Align the ID inside the frame';
  String? latestPath;
  String? lastResultJson;
  int lastStillMs = 0;
  Size viewSize = Size.zero;

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    camera = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );
    await camera!.initialize();
    notifyListeners();

    _session = LocateSession(
      settings: const LocateSettings(
        showThreshold: showThreshold,
        highThreshold: highThreshold,
        keepCaptureMin: keepCaptureMin,
        pollMs: pollMs,
      ),
      onFrame: _onLocateFrame,
    );
    _session!.updateViewSize(viewSize);
    await _session!.attach(camera!);
    await _session!.start();
  }

  void updateViewSize(Size size) {
    viewSize = size;
    _session?.updateViewSize(size);
  }

  void _onLocateFrame(LocateFrame frame) {
    if (captured || busy) return;
    scorePct = frame.scorePct;
    corners = frame.corners;
    if (frame.scorePct >= keepCaptureMin) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (frame.high || now - lastStillMs > 500) {
        _deleteQuiet(latestPath);
        latestPath = frame.path;
        lastStillMs = now;
      } else {
        _deleteQuiet(frame.path);
      }
      captureEnabled = true;
      hint = 'Ready — tap Capture or keep holding';
    } else {
      _deleteQuiet(frame.path);
      captureEnabled = false;
      hint = 'Align the ID inside the frame';
    }
    notifyListeners();
  }

  Future<String?> beginRecognize(String path) async {
    if (captured) return null;
    captured = true;
    busy = true;
    hint = 'Reading document…';
    notifyListeners();
    await _session?.stop();
    try {
      final json = await _docs.recognize(
        path,
      );
      lastResultJson = json;
      notifyListeners();
      return json;
    } catch (e) {
      captured = false;
      busy = false;
      hint = '$e';
      notifyListeners();
      await _session?.start();
      return null;
    } finally {
      if (path != latestPath) _deleteQuiet(path);
    }
  }

  Future<String?> onCapture() async {
    final path = latestPath;
    if (path == null) return null;
    return beginRecognize(path);
  }

  void _deleteQuiet(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_session?.dispose());
    final cam = camera;
    camera = null;
    if (cam != null) {
      unawaited(cam.dispose());
    }
    _deleteQuiet(latestPath);
    super.dispose();
  }
}
