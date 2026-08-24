import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/navigation/customer_service_navigation.dart';

void main() {
  test('builds the privacy policy URL from the web base URL', () {
    expect(
      privacyPolicyUrl(Uri.parse('https://web.example.com')),
      'https://web.example.com/#/BullyInfesters',
    );
  });
}
