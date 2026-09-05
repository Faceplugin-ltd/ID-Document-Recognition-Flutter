import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/sdk_status.dart';
import '../../services/sdk_service.dart';
import '../../widgets/buttons/tile_button.dart';
import '../../widgets/face_plugin_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sdk = context.watch<SdkService>();
    final ready = sdk.ready;
    final statusStyle = ready
        ? AppColors.statusOk
        : sdk.status.phase == SdkPhase.loading
            ? AppColors.statusInfo
            : AppColors.statusError;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
                child: Column(
                  children: [
                    const FacePluginLogo(
                      size: 120,
                      onPressed: FacePluginLogo.openWebsite,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'FacePlugin DocumentReader',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TileButton(
                            title: 'CAMERA',
                            icon: Icons.photo_camera,
                            disabled: !ready,
                            onPressed: () => _guard(
                              context,
                              ready,
                              sdk.statusMessage,
                              () => context.push('/camera'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TileButton(
                            title: 'GALLERY',
                            icon: Icons.photo_library,
                            disabled: !ready,
                            onPressed: () => _guard(
                              context,
                              ready,
                              sdk.statusMessage,
                              () => context.push('/gallery'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TileButton(
                            title: 'ABOUT',
                            icon: Icons.info_outline,
                            onPressed: () => context.push('/about'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              constraints: const BoxConstraints(minHeight: 64),
              decoration: BoxDecoration(
                color: statusStyle,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                sdk.statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _guard(
    BuildContext context,
    bool ready,
    String status,
    VoidCallback go,
  ) {
    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status.isEmpty ? 'SDK not ready' : status)),
      );
      return;
    }
    go();
  }
}
