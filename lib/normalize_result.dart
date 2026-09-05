import 'dart:convert';

/// Canonical DocumentReader result schema (iOS / demo-friendly shape).
/// Android may emit `status.detailsOptical` instead of `verification`;
/// this folds those into one object so apps never need Platform branches.

typedef JsonMap = Map<String, dynamic>;

class DocVerification {
  DocVerification({
    this.overall,
    this.docType,
    this.expiry,
    this.text,
    this.mrz,
    this.security,
    this.imageQA,
    this.portrait,
    this.reasons,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  num? overall;
  num? docType;
  num? expiry;
  num? text;
  num? mrz;
  num? security;
  num? imageQA;
  num? portrait;
  Map<String, List<String>>? reasons;
  Map<String, dynamic> extra;

  JsonMap toJson() {
    final out = <String, dynamic>{...extra};
    if (overall != null) out['overall'] = overall;
    if (docType != null) out['docType'] = docType;
    if (expiry != null) out['expiry'] = expiry;
    if (text != null) out['text'] = text;
    if (mrz != null) out['mrz'] = mrz;
    if (security != null) out['security'] = security;
    if (imageQA != null) out['imageQA'] = imageQA;
    if (portrait != null) out['portrait'] = portrait;
    if (reasons != null) out['reasons'] = reasons;
    return out;
  }

  factory DocVerification.fromJson(JsonMap raw) {
    final known = {
      'overall',
      'docType',
      'expiry',
      'text',
      'mrz',
      'security',
      'imageQA',
      'portrait',
      'reasons',
    };
    final extra = <String, dynamic>{};
    for (final e in raw.entries) {
      if (!known.contains(e.key)) extra[e.key] = e.value;
    }
    Map<String, List<String>>? reasons;
    final r = raw['reasons'];
    if (r is Map) {
      reasons = {};
      for (final e in r.entries) {
        final v = e.value;
        if (v is List) {
          reasons[e.key.toString()] =
              v.map((x) => '$x').where((s) => s.isNotEmpty).toList();
        } else if (v is String && v.isNotEmpty) {
          reasons[e.key.toString()] = [v];
        }
      }
    }
    return DocVerification(
      overall: _asNum(raw['overall']),
      docType: _asNum(raw['docType']),
      expiry: _asNum(raw['expiry']),
      text: _asNum(raw['text']),
      mrz: _asNum(raw['mrz']),
      security: _asNum(raw['security']),
      imageQA: _asNum(raw['imageQA']),
      portrait: _asNum(raw['portrait']),
      reasons: reasons,
      extra: extra,
    );
  }
}

class DocImage {
  DocImage({required this.name, required this.image, this.source});

  final String name;
  final String image;
  final String? source;

  JsonMap toJson() {
    final out = <String, dynamic>{'name': name, 'image': image};
    if (source != null) out['source'] = source;
    return out;
  }
}

class DocResult {
  DocResult({
    this.errorCode,
    this.documentName,
    this.countryName,
    this.score,
    this.msg,
    this.verification,
    this.status,
    this.imageQuality,
    this.ocr,
    this.mrz,
    this.barcode,
    this.authenticity,
    this.images,
    this.position,
    this.locateImageWidth,
    this.locateImageHeight,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  num? errorCode;
  String? documentName;
  String? countryName;
  num? score;
  String? msg;
  DocVerification? verification;
  dynamic status;
  Map<String, dynamic>? imageQuality;
  Map<String, dynamic>? ocr;
  Map<String, dynamic>? mrz;
  Map<String, dynamic>? barcode;
  dynamic authenticity;
  List<DocImage>? images;
  dynamic position;
  num? locateImageWidth;
  num? locateImageHeight;
  Map<String, dynamic> extra;

  JsonMap toJson() {
    final out = <String, dynamic>{...extra};
    if (errorCode != null) out['errorCode'] = errorCode;
    if (documentName != null) out['documentName'] = documentName;
    if (countryName != null) out['countryName'] = countryName;
    if (score != null) out['score'] = score;
    if (msg != null) out['msg'] = msg;
    if (verification != null) out['verification'] = verification!.toJson();
    if (status != null) out['status'] = status;
    if (imageQuality != null) out['imageQuality'] = imageQuality;
    if (ocr != null) out['ocr'] = ocr;
    if (mrz != null) out['mrz'] = mrz;
    if (barcode != null) out['barcode'] = barcode;
    if (authenticity != null) out['authenticity'] = authenticity;
    if (images != null) {
      out['images'] = images!.map((e) => e.toJson()).toList();
    }
    if (position != null) out['position'] = position;
    if (locateImageWidth != null) {
      out['_locateImageWidth'] = locateImageWidth;
    }
    if (locateImageHeight != null) {
      out['_locateImageHeight'] = locateImageHeight;
    }
    return out;
  }
}

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

const _verifyCheckKeys = [
  'docType',
  'expiry',
  'text',
  'mrz',
  'security',
  'imageQA',
  'portrait',
];

JsonMap? _asObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String && value.trim().isNotEmpty) {
    return num.tryParse(value);
  }
  return null;
}

JsonMap? _parseRoot(String raw) {
  try {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return _asObject(jsonDecode(trimmed));
  } catch (_) {
    return null;
  }
}

/// Flatten platform image-QA variants into a name→result map.
Map<String, dynamic> extractImageQualityChecks(dynamic value) {
  final asObj = _asObject(value);
  if (asObj != null) {
    final checks = _asObject(asObj['checks']);
    if (checks != null) return Map<String, dynamic>.from(checks);
    final known = _imageQaOrder.toSet();
    final named = <String, dynamic>{};
    for (final e in asObj.entries) {
      final v = e.value;
      if (known.contains(e.key) && v is! Map && v is! List) {
        named[e.key] = v;
      }
    }
    if (named.isNotEmpty) return named;
  }

  final out = <String, dynamic>{};
  List<dynamic> pages = [];
  if (value is List) {
    pages = value;
  } else if (asObj != null && asObj['list'] is List) {
    pages = [asObj['list']];
  }

  for (final page in pages) {
    List<dynamic> checks = [];
    final pageObj = _asObject(page);
    if (pageObj != null) {
      final nested = _asObject(pageObj['checks']);
      if (nested != null) {
        out.addAll(nested);
        continue;
      }
      checks = pageObj['list'] is List ? pageObj['list'] as List : [];
    } else if (page is List) {
      checks = page;
    }
    for (final item in checks) {
      final c = _asObject(item);
      if (c == null) continue;
      final result = c['result'] ?? c['Result'];
      final name = (c['id'] is String && (c['id'] as String).isNotEmpty)
          ? c['id'] as String
          : (c['name'] is String && (c['name'] as String).isNotEmpty)
              ? c['name'] as String
              : '';
      if (name.isNotEmpty) {
        out[name] = result;
        continue;
      }
      final type = _asNum(c['type'] ?? c['Type'])?.toInt();
      const idMap = {
        0: 'glares',
        1: 'focus',
        2: 'resolution',
        3: 'colorness',
        4: 'perspective',
        5: 'bounds',
        7: 'portrait',
        8: 'handwritten',
        9: 'brightness',
        10: 'occlusion',
      };
      if (type == null) continue;
      out[idMap[type] ?? '$type'] = result;
    }
  }
  return out;
}

num overallStatusToFacePlugin(num code) {
  if (code == 1) return 0;
  if (code == 0) return 1;
  return code;
}

num checkStatusToFacePlugin(num code) {
  if (code == 1) return 0;
  if (code == 0) return 1;
  return code;
}

DocVerification? _verificationFromStatus(JsonMap status) {
  final v = <String, dynamic>{};
  if (status['overallStatus'] != null) {
    final n = _asNum(status['overallStatus']);
    if (n != null) v['overall'] = overallStatusToFacePlugin(n);
  }
  final opt = _asObject(status['detailsOptical']);
  if (opt != null) {
    for (final key in _verifyCheckKeys) {
      if (key == 'portrait') continue;
      if (opt[key] != null) {
        final n = _asNum(opt[key]);
        v[key] = n != null ? checkStatusToFacePlugin(n) : opt[key];
      }
    }
  }
  if (status['portrait'] != null) {
    final n = _asNum(status['portrait']);
    v['portrait'] = n != null ? checkStatusToFacePlugin(n) : status['portrait'];
  } else if (opt != null && opt['portrait'] != null) {
    final n = _asNum(opt['portrait']);
    v['portrait'] = n != null ? checkStatusToFacePlugin(n) : opt['portrait'];
  }
  return v.isEmpty ? null : DocVerification.fromJson(v);
}

DocVerification? _canonicalizeVerification(JsonMap raw) {
  final checks = _asObject(raw['checks']);
  final looksNested = checks != null && checks.values.any((c) => c is Map);

  if (!looksNested) {
    final v = Map<String, dynamic>.from(raw);
    if (v['overall'] == null && raw['result'] != null) {
      final n = _asNum(raw['result']);
      if (n != null) v['overall'] = n;
    }
    v.remove('checks');
    v.remove('result');
    v.remove('label');
    return v.isEmpty ? null : DocVerification.fromJson(v);
  }

  final v = <String, dynamic>{};
  final overallRaw = _asNum(raw['result'] ?? raw['overall']);
  if (overallRaw != null) {
    v['overall'] = overallStatusToFacePlugin(overallRaw);
  }

  final reasons = <String, List<String>>{};
  final existingReasons = _asObject(raw['reasons']);
  if (existingReasons != null) {
    for (final e in existingReasons.entries) {
      final v = e.value;
      if (v is List) {
        final list = v.map((x) => '$x').where((s) => s.isNotEmpty).toList();
        if (list.isNotEmpty) reasons[e.key.toString()] = list;
      } else if (v is String && v.isNotEmpty) {
        reasons[e.key.toString()] = [v];
      }
    }
  }
  for (final key in _verifyCheckKeys) {
    final cell = checks[key];
    if (cell == null) continue;
    if (cell is Map) {
      final c = Map<String, dynamic>.from(cell);
      final n = _asNum(c['result'] ?? c['Result']);
      if (n != null) v[key] = checkStatusToFacePlugin(n);
      final reason =
          (c['reason'] is String && (c['reason'] as String).isNotEmpty)
              ? c['reason'] as String
              : (c['Reason'] is String && (c['Reason'] as String).isNotEmpty)
                  ? c['Reason'] as String
                  : '';
      if (reason.trim().isNotEmpty) reasons[key] = [reason.trim()];
    } else {
      final n = _asNum(cell);
      if (n != null) v[key] = checkStatusToFacePlugin(n);
    }
  }
  if (reasons.isNotEmpty) v['reasons'] = reasons;
  return v.isEmpty ? null : DocVerification.fromJson(v);
}

bool _hasFlatVerification(JsonMap obj) {
  final v = _asObject(obj['verification']);
  if (v == null || v.isEmpty) return false;
  if (v['overall'] != null || _verifyCheckKeys.any((k) => v[k] != null)) {
    final checks = _asObject(v['checks']);
    if (checks == null) return true;
    return !checks.values.any((c) => c is Map);
  }
  return false;
}

List<DocImage>? _normalizeImages(dynamic value) {
  if (value is! List) return null;
  final out = <DocImage>[];
  for (final item in value) {
    if (item is String) {
      if (item.length >= 32) out.add(DocImage(name: 'Image', image: item));
      continue;
    }
    final d = _asObject(item);
    if (d == null) continue;
    final image = (d['image'] is String && (d['image'] as String).isNotEmpty)
        ? d['image'] as String
        : (d['value'] is String && (d['value'] as String).isNotEmpty)
            ? d['value'] as String
            : (d['data'] is String && (d['data'] as String).isNotEmpty)
                ? d['data'] as String
                : '';
    if (image.length < 32) continue;
    final name = (d['name'] is String && (d['name'] as String).isNotEmpty)
        ? d['name'] as String
        : (d['fieldName'] is String && (d['fieldName'] as String).isNotEmpty)
            ? d['fieldName'] as String
            : (d['role'] is String && (d['role'] as String).isNotEmpty)
                ? d['role'] as String
                : 'Image';
    final source = d['source'] is String ? d['source'] as String : null;
    out.add(DocImage(name: name, image: image, source: source));
  }
  return out;
}

/// Parse + fold Android-oriented fields into the iOS/demo canonical schema.
DocResult normalizeResult(String raw) {
  final obj = _parseRoot(raw);
  if (obj == null) return DocResult();

  final out = Map<String, dynamic>.from(obj);

  final rawVerification = _asObject(out['verification']);
  if (rawVerification != null) {
    final flat = _canonicalizeVerification(rawVerification);
    if (flat != null) out['verification'] = flat.toJson();
  }

  if (!_hasFlatVerification(out) && _asObject(out['status']) != null) {
    final mapped = _verificationFromStatus(_asObject(out['status'])!);
    if (mapped != null) out['verification'] = mapped.toJson();
  }

  if (out['imageQuality'] != null) {
    final checks = extractImageQualityChecks(out['imageQuality']);
    if (checks.isNotEmpty) {
      out['imageQuality'] = {'checks': checks};
    }
  }

  if (out['images'] is List) {
    final images = _normalizeImages(out['images']);
    if (images != null) {
      out['images'] = images.map((e) => e.toJson()).toList();
    }
  }

  final known = {
    'errorCode',
    'documentName',
    'countryName',
    'score',
    'msg',
    'verification',
    'status',
    'imageQuality',
    'ocr',
    'mrz',
    'barcode',
    'authenticity',
    'images',
    'position',
    '_locateImageWidth',
    '_locateImageHeight',
  };
  final extra = <String, dynamic>{};
  for (final e in out.entries) {
    if (!known.contains(e.key)) extra[e.key] = e.value;
  }

  List<DocImage>? images;
  if (out['images'] is List) {
    images = _normalizeImages(out['images']);
  }

  return DocResult(
    errorCode: _asNum(out['errorCode']),
    documentName:
        out['documentName'] is String ? out['documentName'] as String : null,
    countryName:
        out['countryName'] is String ? out['countryName'] as String : null,
    score: _asNum(out['score']),
    msg: out['msg'] is String ? out['msg'] as String : null,
    verification: _asObject(out['verification']) != null
        ? DocVerification.fromJson(_asObject(out['verification'])!)
        : null,
    status: out['status'],
    imageQuality: _asObject(out['imageQuality']),
    ocr: _asObject(out['ocr']),
    mrz: _asObject(out['mrz']),
    barcode: _asObject(out['barcode']),
    authenticity: out['authenticity'],
    images: images,
    position: out['position'],
    locateImageWidth: _asNum(out['_locateImageWidth']),
    locateImageHeight: _asNum(out['_locateImageHeight']),
    extra: extra,
  );
}

/// Same as [normalizeResult], returned as a JSON string.
String normalizeResultJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  try {
    jsonDecode(trimmed);
  } catch (_) {
    return raw;
  }
  return jsonEncode(normalizeResult(trimmed).toJson());
}
