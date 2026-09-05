import 'dart:convert';

import 'license_status.dart';
import 'normalize_result.dart';
import 'src/document_reader_sdk_platform_interface.dart';

export 'capture/document_capture.dart';
export 'live/camera_frame_jpeg.dart';
export 'live/locate_session.dart';
export 'license_status.dart';
export 'normalize_result.dart';
export 'result/result_parser.dart';

const int sdkSuccess = 0;
const int sdkLicenseInvalid = 1;
const int sdkLicenseExpired = 2;
const int sdkNotActivated = 3;
const int sdkInitFailed = 4;

/// File path, content URI, or base64 (optionally `data:` URL).
typedef ImageInput = String;

/// FPMC1.… machine code for license requests.
Future<String> getMachineCode() {
  return DocumentReaderSdkPlatform.instance.getMachineCode();
}

/// Activate with FP1.… bound to applicationId / bundle id.
Future<int> setActivation(String license) {
  return DocumentReaderSdkPlatform.instance.setActivation(license);
}

/// Load engine + database. Returns SDK status code (0 = success).
Future<int> init() {
  return DocumentReaderSdkPlatform.instance.init();
}

Future<void> deinit() {
  return DocumentReaderSdkPlatform.instance.deinit();
}

/// Open a process session. Prefer FullProcess before recognize.
Future<String> startNewSession([
  String optionsJson = '{"scenario":"FullProcess","series":false}',
]) {
  return DocumentReaderSdkPlatform.instance.startNewSession(optionsJson);
}

/// Live locate — JSON with score + position.corners.
Future<String> locateDocument(ImageInput image) {
  return DocumentReaderSdkPlatform.instance.locateDocument(image);
}

String authenticityModeValue([Object? authenticity = true]) {
  if (authenticity == false || authenticity == 'none') return 'none';
  return 'normal';
}

/// Still OCR / MRZ / barcode. Returns canonical iOS-shaped JSON.
/// [authenticity] is `true`/`false` or `'none'` / `'normal'`.
Future<String> recognize(
  ImageInput front, [
  ImageInput? back,
  Object authenticity = true,
]) async {
  final json = await DocumentReaderSdkPlatform.instance.recognize(
    front,
    back,
    authenticityModeValue(authenticity),
  );
  return normalizeResultJson(json);
}

/// Typed recognize — same as [recognize] then [normalizeResult].
Future<DocResult> recognizeResult(
  ImageInput front, [
  ImageInput? back,
  Object authenticity = true,
]) async {
  final json = await recognize(front, back, authenticity);
  return normalizeResult(json);
}

Future<String> lastLicenseError() {
  return DocumentReaderSdkPlatform.instance.lastLicenseError();
}

/// Parsed license capabilities (`label` is what About / home status show).
Future<LicenseStatus> getLicenseStatus() async {
  final json = await DocumentReaderSdkPlatform.instance.getLicenseStatus();
  return LicenseStatus.fromJson(json);
}

/// Writes a JSON status blob for device debug.
Future<void> writeStatus(Map<String, dynamic> payload) {
  return DocumentReaderSdkPlatform.instance.writeStatus(jsonEncode(payload));
}
