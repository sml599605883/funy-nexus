import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/push/push_deep_link.dart';

void main() {
  test('Prismatic maps to home', () {
    const parser = PushDeepLinkParser();
    final link = parser.parse('ph://fund-nexus/ios/Prismatic');

    expect(link.kind, PushDeepLinkKind.home);
    expect(link.alias, 'Prismatic');
  });
}
