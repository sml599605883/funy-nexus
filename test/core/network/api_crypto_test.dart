import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/network/api_crypto.dart';

void main() {
  final crypto = ApiCrypto(key: '0123456789abcdef', iv: 'abcdef9876543210');

  test('encrypts with AES-CBC PKCS7 and Base64 output', () {
    expect(
      crypto.encryptText('{"hello":"Fund Nexus"}'),
      'NWGrTMZYt8L0Wez0xK2chFmSU6NwH4J5O/4wGNXwJJw=',
    );
  });

  test('decrypts an encrypted payload', () {
    const encrypted = 'NWGrTMZYt8L0Wez0xK2chFmSU6NwH4J5O/4wGNXwJJw=';

    expect(crypto.decryptText(encrypted), '{"hello":"Fund Nexus"}');
  });

  test('serializes JSON before encryption', () {
    expect(
      crypto.encryptJson(const {'hello': 'Fund Nexus'}),
      'NWGrTMZYt8L0Wez0xK2chFmSU6NwH4J5O/4wGNXwJJw=',
    );
  });
}
