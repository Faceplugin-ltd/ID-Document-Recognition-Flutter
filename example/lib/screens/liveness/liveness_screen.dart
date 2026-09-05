import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/constants/capture.dart';
import '../../widgets/document_overlay.dart';
import '../../widgets/loading/busy_overlay.dart';
import '../document/document_controller.dart';

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  late final DocumentController controller;
  String? error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    controller = DocumentController();
    _boot();
  }

  Future<void> _boot() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => error = 'Camera permission is required');
      return;
    }
    try {
      await controller.initCamera();
      controller.addListener(_onUpdate);
      setState(() {});
    } catch (e) {
      setState(() => error = '$e');
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    final json = controller.lastResultJson;
    if (!_navigated && json != null && json.isNotEmpty) {
      _navigated = true;
      goResult(context, json);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, style: const TextStyle(color: AppColors.text)),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final cam = controller.camera;
    if (cam == null || !cam.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final locked =
        controller.scorePct >= highThreshold && controller.corners != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          controller.updateViewSize(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(cam),
              if (controller.corners != null)
                DocumentOverlay(
                  corners: controller.corners!,
                  locked: locked,
                ),
              Positioned(
                top: 56,
                left: 16,
                child: Material(
                  color: AppColors.accentDim,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Text(
                          '✕',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.scorePct}%',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 110,
                child: Text(
                  controller.hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 180,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            AppColors.accent.withValues(alpha: 0.4),
                      ),
                      onPressed: (!controller.captureEnabled || controller.busy)
                          ? null
                          : () => controller.onCapture(),
                      child: controller.busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Capture',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ),
              if (controller.busy) const BusyOverlay(),
            ],
          );
        },
      ),
    );
  }
}
