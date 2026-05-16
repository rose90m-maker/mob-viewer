import 'package:flutter_test/flutter_test.dart';
import 'package:mob_viewer/config.dart';

void main() {
  test('ApiConfig has a default base URL', () {
    expect(ApiConfig.baseUrl, isNotEmpty);
  });
}
