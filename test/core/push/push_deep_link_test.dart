import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/push/push_deep_link.dart';

void main() {
  const parser = PushDeepLinkParser();

  group('PushDeepLinkParser', () {
    test('parses app scheme URLs', () {
      final link = parser.parse('ph://fund-nexus/ios/Loan?productId=123');

      expect(link.kind, PushDeepLinkKind.productDetail);
      expect(link.alias, 'Loan');
      expect(link.productId, '123');
    });

    test('parses obfuscated names', () {
      final link = parser.parse('ph://fund-nexus/ios/Conifer?productId=456');

      expect(link.kind, PushDeepLinkKind.productDetail);
      expect(link.alias, 'Conifer');
      expect(link.productId, '456');
    });

    test('parses HTTP URLs as webView', () {
      final link = parser.parse('https://example.com/page');

      expect(link.kind, PushDeepLinkKind.webView);
      expect(link.uri?.toString(), 'https://example.com/page');
    });

    test('parses direct aliases', () {
      final homeLink = parser.parse('Home');
      expect(homeLink.kind, PushDeepLinkKind.home);

      final mineLink = parser.parse('Mine');
      expect(mineLink.kind, PushDeepLinkKind.mine);

      final loginLink = parser.parse('Login');
      expect(loginLink.kind, PushDeepLinkKind.login);
    });

    test('extracts product ID from query parameters', () {
      final link = parser.parse('ph://fund-nexus/ios/Loan?productId=789');

      expect(link.productId, '789');
    });

    test('extracts order status from query parameters', () {
      final link = parser.parse('ph://fund-nexus/ios/Order?status=4');

      expect(link.kind, PushDeepLinkKind.order);
      expect(link.orderStatus, '4');
    });

    test('extracts order number from query parameters', () {
      final link =
          parser.parse('ph://fund-nexus/ios/Order?orderNo=ORD123&status=2');

      expect(link.orderNumber, 'ORD123');
      expect(link.orderStatus, '2');
    });

    test('handles empty and invalid targets', () {
      final emptyLink = parser.parse('');
      expect(emptyLink.kind, PushDeepLinkKind.unsupported);

      final invalidLink = parser.parse('invalid://unknown');
      expect(invalidLink.kind, PushDeepLinkKind.unsupported);
    });

    test('ignores platform segment in path', () {
      final link = parser.parse('ph://fund-nexus/ios/Loan?productId=999');

      expect(link.kind, PushDeepLinkKind.productDetail);
      expect(link.alias, 'Loan');
    });

    test('extracts productId from arguments when not in query', () {
      final link = parser.parse(
        'ph://fund-nexus/ios/Loan',
        arguments: {'productId': '555'},
      );

      expect(link.productId, '555');
    });

    test('prefers query parameter over arguments', () {
      final link = parser.parse(
        'ph://fund-nexus/ios/Loan?productId=111',
        arguments: {'productId': '222'},
      );

      expect(link.productId, '111');
    });

    test('handles appPage query parameter', () {
      final link = parser.parse(
        'some-scheme://example.com?appPage=Loan&productId=333',
      );

      expect(link.kind, PushDeepLinkKind.productDetail);
      expect(link.alias, 'Loan');
      expect(link.productId, '333');
    });
  });
}
