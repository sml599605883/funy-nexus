import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/network/api_signature.dart';

void main() {
  test('sorts keys and signs the documented source with HMAC-SHA256', () {
    final signature = ApiSignature.sign(const {
      'pathbreaking': '1.0.0',
      'antipoles': '1700000000000',
      'begloom': '/viler/profile',
    }, 'test-secret');

    expect(
      signature,
      '6d7566115eba16ed4bfbeb635e012ad8d4f7acb2b82117a667bd1364080c9288',
    );
  });

  test('generates cryptographically secure decimal noise', () {
    final value = ApiSignature.randomDigits(6);

    expect(value, hasLength(6));
    expect(int.tryParse(value), isNotNull);
  });
}
