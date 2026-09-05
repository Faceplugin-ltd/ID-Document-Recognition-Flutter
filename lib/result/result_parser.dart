import 'dart:convert';
import 'dart:typed_data';

import '../normalize_result.dart';

class FieldRow {
  FieldRow({required this.key, required this.value, required this.source});
  final String key;
  final String value;
  final String source;
}

class SecurityRow {
  SecurityRow({required this.page, required this.check, required this.status});
  final String page;
  final String check;
  final String status;
}

class ResultImage {
  ResultImage({
    required this.category,
    required this.source,
    required this.bytes,
  });
  final String category;
  final String source;
  /// Decoded image bytes for [Image.memory] (Flutter cannot reliably load large
  /// `data:` URIs via [Image.network]).
  final Uint8List bytes;
}

class Point {
  Point(this.x, this.y);
  final double x;
  final double y;
}

const _longValue = 300;

const _skipKeys = {
  'checkSums',
  'contrastPrint',
  'docFormat',
  'mrzFormat',
  'mrzFormatCheckdigit',
  'mrzStringsWithCorrectCheckSums',
  'numberChecksumValidity',
  'numberValidity',
  'overallValidity',
  'symbolMatrix',
  'images',
};

const _imageQaOrder = [
  'focus',
  'glares',
  'resolution',
  'colorness',
  'perspective',
  'bounds',
  'portrait',
  'handwritten',
  'brightness',
  'occlusion',
];

/// Always parse through [DocResult] so UI never sees Android-nested JSON.
Map<String, dynamic>? _jsonObject(Object raw) {
  try {
    final DocResult normalized;
    if (raw is DocResult) {
      normalized = raw;
    } else if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      normalized = normalizeResult(trimmed);
    } else {
      return null;
    }
    final map = normalized.toJson();
    return map.isEmpty ? null : map;
  } catch (_) {
    return null;
  }
}

String _summarizeLong(String value) {
  var type = 'string';
  if (value.startsWith('/9j/') || value.startsWith('data:image/jpeg')) {
    type = 'jpeg';
  } else if (value.startsWith('iVBOR') || value.startsWith('data:image/png')) {
    type = 'png';
  } else if (value.startsWith('R0lGOD') || value.startsWith('data:image/gif')) {
    type = 'gif';
  } else if (value.startsWith('Qk') && value.length > 100) {
    type = 'bmp';
  } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value)) {
    type = 'base64';
  }
  return '$type, ${value.length} chars';
}

dynamic _sanitize(dynamic value) {
  if (value is List) return value.map(_sanitize).toList();
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, _sanitize(v)));
  }
  if (value is String && value.length > _longValue) {
    return _summarizeLong(value);
  }
  return value;
}

String pretty(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '(empty response)';
  try {
    final obj = normalizeResult(trimmed).toJson();
    return const JsonEncoder.withIndent('  ').convert(_sanitize(obj));
  } catch (_) {
    return _summarizeLong(trimmed);
  }
}

num? _statusCode(dynamic value) {
  if (value is num) return value;
  if (value is String && value.trim().isNotEmpty) {
    return num.tryParse(value);
  }
  return null;
}

String _overallLabel(num code) {
  switch (code.toInt()) {
    case 0:
      return 'Verified';
    case 1:
      return 'Not verified';
    case 2:
      return 'Not checked';
    default:
      return '$code';
  }
}

String _checkLabel(num code) {
  switch (code.toInt()) {
    case 0:
      return 'Pass';
    case 1:
      return 'Fail';
    case 2:
      return 'Not checked';
    default:
      return '$code';
  }
}

String _checkResultLabel(num code) {
  switch (code.toInt()) {
    case 0:
      return 'Fail';
    case 1:
      return 'Pass';
    case 2:
      return 'Not checked';
    default:
      return '$code';
  }
}

num? _qaScoreToCheckResultInt(dynamic value) {
  final n = _statusCode(value);
  if (n == null) return null;
  if (n == 0 || n == 1 || n == 2) return n;
  if (n > 0 && n <= 1) return n >= 0.9 ? 1 : 0;
  return null;
}

num? _checkResultCode(dynamic value) {
  final qa = _qaScoreToCheckResultInt(value);
  if (qa != null) return qa;
  return _statusCode(value);
}

List<FieldRow> _rowsFromMap(Map<String, dynamic>? data, String source) {
  if (data == null) return [];
  final out = <FieldRow>[];
  final keys = data.keys.toList()..sort();
  for (final key in keys) {
    if (_skipKeys.contains(key)) continue;
    if (RegExp(r'^field\d+$').hasMatch(key)) continue;
    final value = data[key];
    if (value is Map || value is List) continue;
    out.add(FieldRow(key: key, value: '$value', source: source));
  }
  return out;
}

List<FieldRow> _rowsFromImageQuality(dynamic value) {
  final checks = extractImageQualityChecks(value);
  if (checks.isEmpty) return [];
  final out = <FieldRow>[];
  final seen = <String>{};
  for (final key in _imageQaOrder) {
    if (!checks.containsKey(key)) continue;
    seen.add(key);
    final code = _checkResultCode(checks[key]);
    out.add(FieldRow(
      key: key,
      value: code != null ? _checkResultLabel(code) : '${checks[key]}',
      source: 'Image QA',
    ));
  }
  final rest = checks.keys.toList()..sort();
  for (final key in rest) {
    if (seen.contains(key)) continue;
    final code = _checkResultCode(checks[key]);
    out.add(FieldRow(
      key: key,
      value: code != null ? _checkResultLabel(code) : '${checks[key]}',
      source: 'Image QA',
    ));
  }
  return out;
}

num _worseCheckResult(num a, num b) {
  if (a == 0 || b == 0) return 0;
  if (a == 2 || b == 2) return 2;
  return 1;
}

num _checkResultToStatus(num checkResult) {
  if (checkResult == 0) return 1;
  if (checkResult == 2) return 2;
  return 0;
}

num? _imageQaStatusFromChecks(Map<String, dynamic> obj) {
  final checks = extractImageQualityChecks(obj['imageQuality']);
  if (checks.isEmpty) return null;
  num worst = 1;
  var any = false;
  for (final val in checks.values) {
    final code = _checkResultCode(val);
    if (code == null) continue;
    any = true;
    worst = _worseCheckResult(worst, code);
  }
  return any ? _checkResultToStatus(worst) : null;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .where((item) => item is String || item is num)
        .map((item) => '$item')
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (value is String && value.isNotEmpty) return [value];
  return [];
}

Map<String, dynamic>? _verificationMap(Map<String, dynamic> obj) {
  Map<String, dynamic>? v;
  final verification = obj['verification'];
  if (verification is Map && verification.isNotEmpty) {
    v = Map<String, dynamic>.from(verification);
  } else if (obj['status'] is Map) {
    final st = Map<String, dynamic>.from(obj['status'] as Map);
    v = {};
    if (st['overallStatus'] != null) v['overall'] = st['overallStatus'];
    if (st['detailsOptical'] is Map) {
      final opt = Map<String, dynamic>.from(st['detailsOptical'] as Map);
      for (final key in [
        'docType',
        'expiry',
        'text',
        'mrz',
        'security',
        'imageQA',
      ]) {
        if (opt[key] != null) v[key] = opt[key];
      }
    }
    if (st['portrait'] != null) v['portrait'] = st['portrait'];
    if (v.isEmpty) v = null;
  }
  if (v == null) return null;

  final qa = _imageQaStatusFromChecks(obj);
  if (qa != null) {
    v['imageQA'] = qa;
    if (v['reasons'] is Map) {
      final reasons = Map<String, dynamic>.from(v['reasons'] as Map);
      reasons.remove('imageQA');
      v['reasons'] = reasons;
    }
  }
  return v;
}

List<String> _failedImageQaReasons(Map<String, dynamic> obj) {
  final checks = extractImageQualityChecks(obj['imageQuality']);
  final out = <String>[];
  final seen = <String>{};
  for (final key in _imageQaOrder) {
    if (!checks.containsKey(key)) continue;
    if (_checkResultCode(checks[key]) != 0) continue;
    seen.add(key);
    out.add(key);
  }
  final rest = checks.keys.toList()..sort();
  for (final key in rest) {
    if (seen.contains(key)) continue;
    if (_checkResultCode(checks[key]) != 0) continue;
    out.add(key);
  }
  return out;
}

List<String> _failedAuthReasons(dynamic value) {
  final out = <String>[];
  void walk(dynamic node) {
    if (node is List) {
      for (final item in node) {
        walk(item);
      }
      return;
    }
    if (node is! Map) return;
    final d = Map<String, dynamic>.from(node);
    for (final key in [
      'liveness',
      'barcode',
      'IPI',
      'ipi',
      'imagePattern',
      'faceMatch',
      'photoEmbedding',
    ]) {
      if (_statusCode(d[key]) == 0) {
        out.add(key);
        continue;
      }
      final items = d[key];
      if (items is! List) continue;
      for (final item in items) {
        if (item is! Map) continue;
        final e = Map<String, dynamic>.from(item);
        final result = _statusCode(e['result'] ?? e['elementResult']) ?? 1;
        if (result != 0) continue;
        final t = (e['type'] is String && (e['type'] as String).isNotEmpty)
            ? e['type'] as String
            : (e['elementDiagnoseName'] is String &&
                    (e['elementDiagnoseName'] as String).isNotEmpty)
                ? e['elementDiagnoseName'] as String
                : key;
        out.add(t);
      }
    }
  }

  walk(value);
  return out;
}

List<String> _reasonsForCheck(
  String key,
  Map<String, dynamic> verification,
  Map<String, dynamic> obj,
) {
  final code = _statusCode(verification[key]);
  if (code != null && code != 1) return [];

  final reasonsObj = verification['reasons'];
  if (reasonsObj is Map) {
    final stored = _stringList(reasonsObj[key]);
    if (stored.isNotEmpty) return stored;
  }
  switch (key) {
    case 'imageQA':
      return _failedImageQaReasons(obj);
    case 'security':
      return _failedAuthReasons(obj['authenticity']);
    case 'docType':
      return ['not recognized'];
    case 'expiry':
      return ['expired'];
    case 'text':
      return ['comparison failed'];
    case 'mrz':
      return ['checksums'];
    case 'portrait':
      return ['mismatch'];
    case 'overall':
      return [
        'docType',
        'expiry',
        'text',
        'mrz',
        'security',
        'imageQA',
        'portrait',
      ].where((k) => _statusCode(verification[k]) == 1).toList();
    default:
      return [];
  }
}

String _labelValue(dynamic value, bool overall, [List<String> reasons = const []]) {
  final code = _statusCode(value);
  if (code != null) {
    final label = overall ? _overallLabel(code) : _checkLabel(code);
    if (code == 1 && reasons.isNotEmpty) {
      return '$label (${reasons.join(', ')})';
    }
    return label;
  }
  if (value is String && value.isNotEmpty) return value;
  return value != null ? '$value' : '';
}

List<FieldRow> _rowsFromVerification(Map<String, dynamic> obj) {
  final v = _verificationMap(obj);
  if (v == null) return [];
  final out = <FieldRow>[];
  if (v['overall'] != null) {
    out.add(FieldRow(
      key: 'overall',
      value: _labelValue(v['overall'], true, _reasonsForCheck('overall', v, obj)),
      source: 'Verify',
    ));
  }
  for (final key in [
    'docType',
    'expiry',
    'text',
    'mrz',
    'security',
    'imageQA',
    'portrait',
  ]) {
    if (v[key] == null) continue;
    out.add(FieldRow(
      key: key,
      value: _labelValue(v[key], false, _reasonsForCheck(key, v, obj)),
      source: 'Verify',
    ));
  }
  return out;
}

String summary(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return raw.length > 200 ? raw.substring(0, 200) : raw;
  if (obj['msg'] is String) return obj['msg'] as String;
  final err = obj['errorCode'] is num
      ? (obj['errorCode'] as num).toInt()
      : int.tryParse('${obj['errorCode']}') ?? -1;
  final score = obj['score'] is num
      ? (obj['score'] as num).toStringAsFixed(3)
      : obj['score'] != null
          ? '${obj['score']}'
          : '—';
  final v = _verificationMap(obj);
  final verification = v?['overall'] != null
      ? _labelValue(v!['overall'], true, _reasonsForCheck('overall', v, obj))
      : 'Not checked';
  return [
    'Status: ${err == 0 ? 'OK' : 'Failed'} (errorCode=$err)',
    'Document: ${obj['documentName'] is String ? obj['documentName'] : '—'}',
    'Country: ${obj['countryName'] is String ? obj['countryName'] : '—'}',
    'Verification: $verification',
    'Score: $score',
  ].join('\n');
}

List<FieldRow> rows(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return [];
  final out = <FieldRow>[
    FieldRow(
      key: 'documentName',
      value: obj['documentName'] is String ? obj['documentName'] as String : '',
      source: 'meta',
    ),
    FieldRow(
      key: 'countryName',
      value: obj['countryName'] is String ? obj['countryName'] as String : '',
      source: 'meta',
    ),
    FieldRow(
      key: 'score',
      value: obj['score'] != null ? '${obj['score']}' : '—',
      source: 'meta',
    ),
    FieldRow(
      key: 'errorCode',
      value: obj['errorCode'] != null ? '${obj['errorCode']}' : '',
      source: 'meta',
    ),
  ];
  out.addAll(_rowsFromVerification(obj));
  out.addAll(_rowsFromImageQuality(obj['imageQuality']));
  out.addAll(_rowsFromMap(
    obj['ocr'] is Map ? Map<String, dynamic>.from(obj['ocr'] as Map) : null,
    'OCR',
  ));
  out.addAll(_rowsFromMap(
    obj['mrz'] is Map ? Map<String, dynamic>.from(obj['mrz'] as Map) : null,
    'MRZ',
  ));
  out.addAll(_rowsFromMap(
    obj['barcode'] is Map
        ? Map<String, dynamic>.from(obj['barcode'] as Map)
        : null,
    'Barcode',
  ));
  return out.where((r) => r.value.isNotEmpty && r.value != 'null').toList();
}

List<ResultImage> images(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null || obj['images'] is! List) return [];
  final out = <ResultImage>[];
  final seen = <String>{};
  for (final item in obj['images'] as List) {
    var b64 = '';
    var category = 'Image';
    var source = '';
    if (item is String) {
      b64 = item;
    } else if (item is Map) {
      final d = Map<String, dynamic>.from(item);
      b64 = (d['image'] is String && (d['image'] as String).isNotEmpty)
          ? d['image'] as String
          : (d['value'] is String && (d['value'] as String).isNotEmpty)
              ? d['value'] as String
              : (d['data'] is String && (d['data'] as String).isNotEmpty)
                  ? d['data'] as String
                  : '';
      final rawName = (d['name'] is String && (d['name'] as String).isNotEmpty)
          ? d['name'] as String
          : (d['fieldName'] is String && (d['fieldName'] as String).isNotEmpty)
              ? d['fieldName'] as String
              : (d['role'] is String && (d['role'] as String).isNotEmpty)
                  ? d['role'] as String
                  : '';
      category = rawName.isEmpty ? 'Image' : rawName;
      source = d['source'] is String ? d['source'] as String : '';
    }
    if (b64.length < 32) continue;
    final key = '${category.toLowerCase()}|${source.toLowerCase()}';
    if (seen.contains(key)) continue;
    seen.add(key);
    var payload = b64.contains('base64,')
        ? b64.substring(b64.indexOf('base64,') + 7)
        : b64;
    // SDK payloads may include whitespace / newlines.
    payload = payload.replaceAll(RegExp(r'\s'), '');
    try {
      final bytes = base64Decode(payload);
      if (bytes.isEmpty) continue;
      out.add(ResultImage(
        category: category,
        source: source,
        bytes: bytes,
      ));
    } catch (_) {
      // Skip undecodable entries.
    }
  }
  return out;
}

int documentPercent(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null || obj['score'] == null) return 0;
  final s = num.tryParse('${obj['score']}') ?? 0;
  final pct = s <= 1.0 ? s * 100.0 : s;
  return pct.clamp(0, 100).truncate();
}

({double width, double height})? locateImageSize(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return null;
  final w = num.tryParse('${obj['_locateImageWidth']}');
  final h = num.tryParse('${obj['_locateImageHeight']}');
  if (w == null || h == null || w <= 0 || h <= 0) return null;
  return (width: w.toDouble(), height: h.toDouble());
}

({double width, double height}) uprightSnapshotSize(
  double width,
  double height,
) {
  if (width > height) {
    return (width: height, height: width);
  }
  return (width: width, height: height);
}

List<Point>? mapUprightCornersToView(
  List<Point> corners,
  double imageW,
  double imageH,
  double viewW,
  double viewH,
) {
  if (corners.length < 4 ||
      imageW <= 1 ||
      imageH <= 1 ||
      viewW <= 1 ||
      viewH <= 1) {
    return null;
  }
  final scale = (viewW / imageW > viewH / imageH)
      ? viewW / imageW
      : viewH / imageH;
  final dx = (viewW - imageW * scale) / 2;
  final dy = (viewH - imageH * scale) / 2;
  return corners
      .map((c) => Point(c.x * scale + dx, (imageH - c.y) * scale + dy))
      .toList();
}

List<Point>? documentCorners(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null || obj['position'] is! Map) return null;
  final pos = Map<String, dynamic>.from(obj['position'] as Map);
  if (pos['corners'] is List && (pos['corners'] as List).length >= 4) {
    final out = <Point>[];
    final corners = pos['corners'] as List;
    for (var i = 0; i < 4; i++) {
      final p = corners[i];
      if (p is! Map) return null;
      final x = num.tryParse('${p['x']}');
      final y = num.tryParse('${p['y']}');
      if (x == null || y == null) return null;
      out.add(Point(x.toDouble(), y.toDouble()));
    }
    return out;
  }
  final l = num.tryParse('${pos['left']}');
  final t = num.tryParse('${pos['top']}');
  final r = num.tryParse('${pos['right']}');
  final b = num.tryParse('${pos['bottom']}');
  if (l == null || t == null || r == null || b == null || r <= l || b <= t) {
    return null;
  }
  return [
    Point(l.toDouble(), t.toDouble()),
    Point(r.toDouble(), t.toDouble()),
    Point(r.toDouble(), b.toDouble()),
    Point(l.toDouble(), b.toDouble()),
  ];
}

const _securityPageMeta = {
  'pageIndex',
  'overall',
  'label',
  'pages',
  'presentation',
};

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _nonemptyString(dynamic value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

String _pageSide(dynamic value) {
  final n = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  if (n == 0) return 'Front';
  if (n == 1) return 'Back';
  return 'Page $n';
}

String _humanizeKey(String key) {
  final spaced = StringBuffer();
  for (final ch in key.split('')) {
    if (ch.isNotEmpty &&
        ch.toUpperCase() == ch &&
        ch.toLowerCase() != ch &&
        spaced.isNotEmpty) {
      spaced.write(' ');
    }
    spaced.write(ch);
  }
  final s = spaced.toString().trim();
  if (s.isEmpty) return key;
  return '${s[0].toUpperCase()}${s.substring(1)}';
}

String _checkTitle(String key, dynamic raw) {
  final d = _asMap(raw);
  final title = d?['title'];
  if (title is String && title.trim().isNotEmpty) return title.trim();
  return _humanizeKey(key);
}

String _statusKind(dynamic value) {
  var v = value;
  final d = _asMap(v);
  if (d != null) {
    if (d['score'] != null && _asMap(d['score']) == null) return 'score';
    v = d['result'] ?? d['label'];
  }
  if (v is num) return 'score';
  final s = '$v'
      .trim()
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceAll('_', '');
  if (const {'success', 'pass', 'ok', 'authentic', '1'}.contains(s)) {
    return 'success';
  }
  if (const {'notchecked', 'wasnotdone', '2'}.contains(s)) {
    return 'notChecked';
  }
  if (const {'fail', 'failed', 'error', 'notauthentic', '0'}.contains(s)) {
    return 'fail';
  }
  return 'other';
}

String _formatScore(dynamic value) {
  final n = value is num ? value.toDouble() : double.tryParse('$value');
  if (n == null) return value == null ? '' : '$value';
  var s = n.toStringAsFixed(1);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return '${s.isEmpty ? '0' : s}%';
}

String _statusCell(dynamic value) {
  switch (_statusKind(value)) {
    case 'success':
      return 'Pass';
    case 'notChecked':
      return 'Not checked';
    case 'fail':
      return 'Fail';
    case 'score':
      final d = _asMap(value);
      return _formatScore(d != null ? d['score'] ?? d['result'] : value);
    default:
      final d = _asMap(value);
      final v = d != null ? d['result'] ?? d['label'] : value;
      return v == null ? '' : '$v';
  }
}

List<Map<String, dynamic>> _securityPages(Map<String, dynamic> sec) {
  final pages = sec['pages'];
  if (pages is List && pages.isNotEmpty) {
    return pages.map(_asMap).whereType<Map<String, dynamic>>().toList();
  }
  final flat = <String, dynamic>{};
  for (final e in sec.entries) {
    if (!_securityPageMeta.contains(e.key)) flat[e.key] = e.value;
  }
  if (flat.isEmpty) return [];
  if (sec['overall'] != null) flat['overall'] = sec['overall'];
  if (sec['label'] != null) flat['label'] = sec['label'];
  flat['pageIndex'] = 0;
  return [flat];
}

void _appendSecurityValue(
  List<SecurityRow> rows,
  String pageName,
  String key,
  dynamic raw,
) {
  final title = _checkTitle(key, raw);
  final dict = _asMap(raw);
  if (dict == null) {
    rows.add(SecurityRow(page: pageName, check: title, status: _statusCell(raw)));
    return;
  }
  if (dict['score'] != null && _asMap(dict['score']) == null) {
    rows.add(SecurityRow(page: pageName, check: title, status: _statusCell(raw)));
    return;
  }
  final kind = _statusKind(raw);
  rows.add(SecurityRow(
    page: pageName,
    check: title,
    status: _statusCell(dict['result']),
  ));
  final checks = _asMap(dict['checks']);
  if (checks == null) return;
  if (kind != 'fail' &&
      !checks.values.any((cv) => _statusKind(cv) == 'fail')) {
    return;
  }
  for (final e in checks.entries) {
    if (_statusKind(e.value) == 'notChecked' && kind != 'fail') continue;
    rows.add(SecurityRow(
      page: pageName,
      check: '  → ${_checkTitle(e.key, e.value)}',
      status: _statusCell(e.value),
    ));
  }
}

/// Document / page authenticity summary — same contract as native ResultParser.
String securitySummary(String raw) {
  final obj = _jsonObject(raw);
  final sec = obj == null ? null : _asMap(obj['security']);
  if (sec == null) {
    return 'No security checks in this response. If you expected checks, this license may not include liveness.';
  }
  final pages = _securityPages(sec);
  final docLabel = _nonemptyString(sec['label']) ?? _statusCell(sec['overall']);
  if (pages.isEmpty) {
    if (docLabel.isNotEmpty) {
      return 'Document: $docLabel\nNo per-page checks in this response.';
    }
    return 'No security checks in this response.';
  }
  final buf = StringBuffer('Document: ${docLabel.isEmpty ? '—' : docLabel}');
  for (final page in pages) {
    final name = _pageSide(page['pageIndex']);
    final pageLabel =
        _nonemptyString(page['label']) ?? _statusCell(page['overall']);
    buf.write('\n$name: ${pageLabel.isEmpty ? '—' : pageLabel}');
  }
  return buf.toString();
}

List<SecurityRow> securityRows(String raw) {
  final obj = _jsonObject(raw);
  final sec = obj == null ? null : _asMap(obj['security']);
  if (sec == null) return [];
  final pages = _securityPages(sec);
  if (pages.isEmpty) {
    final docLabel =
        _nonemptyString(sec['label']) ?? _statusCell(sec['overall']);
    if (docLabel.isEmpty) return [];
    return [SecurityRow(page: '—', check: 'Overall', status: docLabel)];
  }
  final out = <SecurityRow>[];
  for (final page in pages) {
    final name = _pageSide(page['pageIndex']);
    final pageLabel =
        _nonemptyString(page['label']) ?? _statusCell(page['overall']);
    out.add(SecurityRow(
      page: name,
      check: 'Overall',
      status: pageLabel.isEmpty ? '—' : pageLabel,
    ));
    for (final e in page.entries) {
      if (_securityPageMeta.contains(e.key)) continue;
      _appendSecurityValue(out, name, e.key, e.value);
    }
  }
  return out;
}
