import 'dart:convert';

/// Parsed DocumentReaderSDK.getLicenseStatus JSON — same contract as native LicenseStatus.
class LicenseStatus {
  const LicenseStatus({
    required this.licensed,
    required this.level,
    required this.levelName,
    required this.recognition,
    required this.authenticity,
    required this.label,
  });

  final bool licensed;
  final int level;
  final String levelName;
  final bool recognition;
  final bool authenticity;
  final String label;

  static const notLicensed = LicenseStatus(
    licensed: false,
    level: -1,
    levelName: 'None',
    recognition: false,
    authenticity: false,
    label: 'Not licensed',
  );

  factory LicenseStatus.fromJson(String? json) {
    try {
      final decoded = jsonDecode(json ?? '{}');
      if (decoded is! Map) return notLicensed;
      final o = Map<String, dynamic>.from(decoded);
      final rawLabel = o['label'];
      final label = rawLabel is String && rawLabel.trim().isNotEmpty
          ? rawLabel
          : 'Not licensed';
      return LicenseStatus(
        licensed: o['licensed'] == true,
        level: o['level'] is num ? (o['level'] as num).toInt() : -1,
        levelName: o['levelName'] is String ? o['levelName'] as String : 'None',
        recognition: o['recognition'] == true,
        authenticity: o['authenticity'] == true,
        label: label,
      );
    } catch (_) {
      return notLicensed;
    }
  }
}

/// Home status bar after a successful init — Android `Ready · %s`.
String readyStatusMessage(String label) {
  final t = label.trim();
  return t.isEmpty ? 'Ready' : 'Ready · $t';
}
