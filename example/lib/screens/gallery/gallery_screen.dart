import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../services/document_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _picker = ImagePicker();
  final _docs = DocumentService();
  String? front;
  String? back;
  bool busy = false;
  String error = '';

  Future<void> _pick(bool isFront) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      if (isFront) {
        front = picked.path;
      } else {
        back = picked.path;
      }
      error = '';
    });
  }

  Future<void> _recognize() async {
    if (front == null || busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final json = await _docs.recognize(
        front!,
        back: back,
      );
      if (!mounted) return;
      goResult(context, json);
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Front image is required. Back is optional (ID cards).',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _SideCard(
                      label: 'Front',
                      path: front,
                      onPick: () => _pick(true),
                      onClear: () => setState(() => front = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SideCard(
                      label: 'Back (optional)',
                      path: back,
                      onPick: () => _pick(false),
                      onClear: () => setState(() => back = null),
                    ),
                  ),
                ],
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: Color(0xFFF87171))),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.45),
                ),
                onPressed: (front == null || busy) ? null : _recognize,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Recognize',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.label,
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPick,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: path == null
                    ? const Center(
                        child: Text(
                          'Tap to pick',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : Image.file(File(path!), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (path != null)
          TextButton(
            onPressed: onClear,
            child: const Text('Clear', style: TextStyle(color: AppColors.accent)),
          )
        else
          const SizedBox(height: 18),
      ],
    );
  }
}
