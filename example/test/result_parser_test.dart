import 'package:document_reader_sdk_example/core/utils/result_parser.dart';
import 'package:flutter_test/flutter_test.dart';

String? rowValue(String raw, String key) {
  for (final r in rows(raw)) {
    if (r.key == key) return r.value;
  }
  return null;
}

void main() {
  group('result_parser iOS parity', () {
    test('maps Android nested wire + float QA', () {
      const json = '''
      {"documentName":"CA DL","countryName":"United States","score":0.9,"errorCode":0,
       "verification":{"result":1,"label":"VERIFIED","checks":{
         "docType":{"result":1},"expiry":{"result":1},"text":{"result":1},
         "mrz":{"result":2},"security":{"result":2},
         "imageQA":{"result":0},"portrait":{"result":2}}},
       "imageQuality":{"checks":{"focus":0.973,"glares":0.512,"bounds":2,"custom":1.0}},
       "ocr":{"documentNumber":"X1","checkSums":"skip"},
       "mrz":{},
       "barcode":{"raw":"ABC"}}
      ''';
      expect(rowValue(json, 'overall'), 'Verified');
      expect(rowValue(json, 'imageQA'), 'Fail (glares)');
      expect(rowValue(json, 'focus'), 'Pass');
      expect(rowValue(json, 'glares'), 'Fail');
      expect(rowValue(json, 'bounds'), 'Not checked');
      expect(rowValue(json, 'custom'), 'Pass');
    });

    test('maps flat FacePlugin wire', () {
      const json = '''
      {"documentName":"CA DL","countryName":"United States","score":0.9,"errorCode":0,
       "verification":{"overall":0,"docType":0,"expiry":0,"text":0,"mrz":2,"security":2,"imageQA":1,"portrait":2},
       "imageQuality":{"checks":{"focus":1,"glares":0,"bounds":2,"custom":1}},
       "ocr":{"documentNumber":"X1","checkSums":"skip"},
       "mrz":{},
       "barcode":{"raw":"ABC"}}
      ''';
      final parsed = rows(json);
      expect(parsed.map((r) => r.source), [
        'meta',
        'meta',
        'meta',
        'meta',
        'Verify',
        'Verify',
        'Verify',
        'Verify',
        'Verify',
        'Verify',
        'Verify',
        'Verify',
        'Image QA',
        'Image QA',
        'Image QA',
        'Image QA',
        'OCR',
        'Barcode',
      ]);
      expect(rowValue(json, 'overall'), 'Verified');
      expect(rowValue(json, 'imageQA'), 'Fail (glares)');
      expect(summary(json), contains('Verification: Verified'));
    });

    test('derives imageQA Pass from CheckResult checks when all pass', () {
      const json = '''
      {"verification":{"overall":0,"imageQA":1,"reasons":{"imageQA":["focus","glares","resolution"]}},
       "imageQuality":{"checks":{"focus":1,"glares":1,"resolution":1}}}
      ''';
      expect(rowValue(json, 'imageQA'), 'Pass');
      expect(rowValue(json, 'focus'), 'Pass');
      expect(rowValue(json, 'glares'), 'Pass');
      expect(rowValue(json, 'resolution'), 'Pass');
    });
  });

  group('security tab mapping', () {
    test('maps per-page authenticity like native ResultParser', () {
      const json = '''
      {"security":{"overall":"authentic","label":"Authentic","pages":[{
        "pageIndex":0,"overall":"authentic","label":"Authentic",
        "photoOriginAnalysis":{"result":"success","title":"Photo origin analysis"},
        "securityPattern":{"score":94.2,"title":"Security pattern analysis"},
        "liveness":{"result":"fail","title":"Liveness","checks":{
          "print":{"result":"fail","title":"Print attack"},
          "screen":{"result":"notChecked","title":"Screen replay"}
        }}
      }]}}
      ''';
      expect(securitySummary(json), 'Document: Authentic\nFront: Authentic');
      final parsed = securityRows(json);
      expect(parsed.map((r) => [r.page, r.check, r.status]).toList(), [
        ['Front', 'Overall', 'Authentic'],
        ['Front', 'Photo origin analysis', 'Pass'],
        ['Front', 'Security pattern analysis', '94.2%'],
        ['Front', 'Liveness', 'Fail'],
        ['Front', '  → Print attack', 'Fail'],
        ['Front', '  → Screen replay', 'Not checked'],
      ]);
    });

    test('explains missing security when the payload has none', () {
      expect(
        securitySummary('{"errorCode":0}'),
        contains('this license may not include liveness'),
      );
      expect(securityRows('{"errorCode":0}'), isEmpty);
    });
  });
}
