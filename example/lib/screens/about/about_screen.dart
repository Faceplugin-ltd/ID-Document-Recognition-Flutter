import 'package:flutter/material.dart';
import 'package:document_reader_sdk/document_reader_sdk.dart';

import '../../app/theme.dart';
import '../../widgets/face_plugin_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _licenseText = 'License: …';

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    try {
      final status = await getLicenseStatus();
      if (!mounted) return;
      setState(() => _licenseText = 'License: ${status.label}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _licenseText = 'License: Not licensed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FacePluginLogo(
            size: 120,
            onPressed: FacePluginLogo.openWebsite,
          ),
          const SizedBox(height: 16),
          const Text(
            'FacePlugin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Document Reader SDK',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.accent, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _card(_licenseText, centered: true, compact: true),
          _card(
            'FacePlugin builds on-device identity technology — document '
            'recognition, face matching, and liveness — so biometric data never '
            'has to leave the phone.',
          ),
          _card(
            'This app demos the Document Reader SDK for Flutter: ID cards, '
            'passports, and driver licenses with OCR, MRZ, barcode, and optional '
            'authenticity checks. Everything runs fully on-premise.',
          ),
          const TextButton(
            onPressed: FacePluginLogo.openWebsite,
            child: Text(
              'faceplugin.com',
              style: TextStyle(color: AppColors.accent, fontSize: 16),
            ),
          ),
          const Text(
            '© 2026 FacePlugin. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _card(String body, {bool centered = false, bool compact = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        body,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: AppColors.text,
          fontSize: compact ? 13 : 14,
          height: 1.5,
        ),
      ),
    );
  }
}
