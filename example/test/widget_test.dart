import 'package:document_reader_sdk_example/core/utils/result_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rows returns empty for blank input', () {
    expect(rows(''), isEmpty);
  });
}
