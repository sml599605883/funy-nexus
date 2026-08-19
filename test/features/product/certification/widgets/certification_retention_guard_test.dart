import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_guard.dart';

void main() {
  testWidgets('falls back to the original back action when no popup is shown', (
    tester,
  ) async {
    var backCount = 0;
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    await CertificationRetentionGuard.handleBack(
      context: context,
      type: ' 2 ',
      productId: ' product-1 ',
      onDefaultBack: () => backCount++,
      show:
          ({
            required context,
            required type,
            required productId,
            required onExit,
          }) async {
            expect(type, '2');
            expect(productId, 'product-1');
            return false;
          },
    );

    expect(backCount, 1);
  });

  testWidgets('keeps the page until Exit when the popup is shown', (
    tester,
  ) async {
    var backCount = 0;
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    await CertificationRetentionGuard.handleBack(
      context: context,
      type: '1',
      productId: 'product-1',
      onDefaultBack: () => backCount++,
      show:
          ({
            required context,
            required type,
            required productId,
            required onExit,
          }) async => true,
    );

    expect(backCount, 0);
  });

  testWidgets('skips the presenter when the product id is missing', (
    tester,
  ) async {
    var backCount = 0;
    var presentCount = 0;
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    await CertificationRetentionGuard.handleBack(
      context: context,
      type: '0',
      productId: ' ',
      onDefaultBack: () => backCount++,
      show:
          ({
            required context,
            required type,
            required productId,
            required onExit,
          }) async {
            presentCount++;
            return true;
          },
    );

    expect(backCount, 1);
    expect(presentCount, 0);
  });
}
