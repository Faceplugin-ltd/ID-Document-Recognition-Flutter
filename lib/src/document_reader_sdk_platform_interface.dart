import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'document_reader_sdk_method_channel.dart';

abstract class DocumentReaderSdkPlatform extends PlatformInterface {
  DocumentReaderSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static DocumentReaderSdkPlatform _instance = MethodChannelDocumentReaderSdk();

  static DocumentReaderSdkPlatform get instance => _instance;

  static set instance(DocumentReaderSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> getMachineCode() {
    throw UnimplementedError('getMachineCode() has not been implemented.');
  }

  Future<int> setActivation(String license) {
    throw UnimplementedError('setActivation() has not been implemented.');
  }

  Future<int> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<void> deinit() {
    throw UnimplementedError('deinit() has not been implemented.');
  }

  Future<String> startNewSession(String optionsJson) {
    throw UnimplementedError('startNewSession() has not been implemented.');
  }

  Future<String> locateDocument(String image) {
    throw UnimplementedError('locateDocument() has not been implemented.');
  }

  Future<String> recognize(String front, String? back, String authenticityMode) {
    throw UnimplementedError('recognize() has not been implemented.');
  }

  Future<String> lastLicenseError() {
    throw UnimplementedError('lastLicenseError() has not been implemented.');
  }

  Future<String> getLicenseStatus() {
    throw UnimplementedError('getLicenseStatus() has not been implemented.');
  }

  Future<void> writeStatus(String json) {
    throw UnimplementedError('writeStatus() has not been implemented.');
  }
}
