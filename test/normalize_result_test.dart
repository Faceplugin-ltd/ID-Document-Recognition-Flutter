import 'package:document_reader_sdk/document_reader_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeResult', () {
    test('passes through flat FacePlugin verification unchanged', () {
      final raw = '''
      {"errorCode":0,"verification":{"overall":0,"docType":0,"expiry":1,"text":0,"mrz":2,"security":0,"imageQA":1,"portrait":2}}
      ''';
      final out = normalizeResult(raw);
      expect(out.verification?.overall, 0);
      expect(out.verification?.docType, 0);
      expect(out.verification?.expiry, 1);
      expect(out.verification?.text, 0);
      expect(out.verification?.security, 0);
      expect(out.verification?.imageQA, 1);
    });

    test('flattens nested Android verification.checks', () {
      final raw = '''
      {"verification":{"result":1,"checks":{"docType":{"result":1},"text":{"result":0,"reason":"comparison failed"},"imageQA":{"result":0,"reason":"focus; glares"}}}}
      ''';
      final out = normalizeResult(raw);
      expect(out.verification?.overall, 0);
      expect(out.verification?.docType, 0);
      expect(out.verification?.text, 1);
      expect(out.verification?.imageQA, 1);
      expect(out.verification?.reasons?['text'], ['comparison failed']);
      expect(out.verification?.reasons?['imageQA'], ['focus; glares']);
    });

    test('merges pre-existing verification.reasons with nested checks', () {
      final raw = '''
      {"verification":{"result":1,"reasons":{"expiry":["expired"]},"checks":{"docType":{"result":1},"expiry":{"result":0}}}}
      ''';
      final out = normalizeResult(raw);
      expect(out.verification?.expiry, 1);
      expect(out.verification?.reasons?['expiry'], ['expired']);
    });

    test('converts float QA scores to CheckResult ints', () {
      final raw = '''
      {"imageQuality":{"checks":{"focus":0.973,"glares":0.512,"bounds":2}}}
      ''';
      final out = normalizeResult(raw);
      final checks = extractImageQualityChecks(out.imageQuality);
      expect(checks['focus'], 0.973);
      expect(checks['glares'], 0.512);
      expect(checks['bounds'], 2);
    });

    test('golden: Android nested wire → FacePlugin verification', () {
      const raw = '''
      {"documentName":"CA DL","verification":{"result":1,"checks":{
        "docType":{"result":1},"text":{"result":0,"reason":"comparison failed"},
        "imageQA":{"result":0,"reason":"glares"}}},
       "imageQuality":{"checks":{"focus":0.97,"glares":0.4}}}
      ''';
      final out = normalizeResult(raw);
      expect(out.documentName, 'CA DL');
      expect(out.verification?.overall, 0);
      expect(out.verification?.docType, 0);
      expect(out.verification?.text, 1);
      expect(out.verification?.imageQA, 1);
      expect(out.verification?.reasons?['text'], ['comparison failed']);
    });

    test('golden: iOS flat FacePlugin wire is idempotent', () {
      const raw = '''
      {"verification":{"overall":0,"docType":0,"expiry":1,"text":0,"mrz":2,"imageQA":1},
       "imageQuality":{"checks":{"focus":1,"glares":0}}}
      ''';
      final out = normalizeResult(raw);
      expect(out.verification?.overall, 0);
      expect(out.verification?.docType, 0);
      expect(out.verification?.expiry, 1);
      expect(out.verification?.imageQA, 1);
      expect(extractImageQualityChecks(out.imageQuality)['focus'], 1);
    });
  });
}
