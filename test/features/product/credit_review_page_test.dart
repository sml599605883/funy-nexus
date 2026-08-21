import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/features/product/credit_review/credit_review_page.dart';

void main() {
  testWidgets('matches the 375x812 waiting-credit layout', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(child: CreditReviewPage(productId: 'product-1')),
      ),
    );
    await tester.pump();

    final illustration = find.byKey(const Key('credit-review-illustration'));
    expect(illustration, findsOneWidget);
    expect(tester.getSize(illustration), const Size(120, 102));
    expect(tester.getTopLeft(illustration).dy, closeTo(290, 1));
    expect(
      find.text(
        'Calculating your credit limit, just 30 seconds',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Please wait patiently'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    final track = find.byKey(const Key('credit-review-progress-bar'));
    expect(tester.getSize(track), const Size(287, 12));

    final image = tester.widget<Image>(illustration);
    expect(
      (image.image as AssetImage).assetName,
      AppAssets.recreditIllustration,
    );
  });

  testWidgets('returns to the previous page from the back button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScope(
          child: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const CreditReviewPage(productId: 'product-1'),
                    ),
                  );
                },
                child: const Text('Open credit review'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open credit review'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('credit-review-back')));
    await tester.pumpAndSettle();

    expect(find.text('Open credit review'), findsOneWidget);
  });

  testWidgets('keeps the design anchor and scrolls on a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(child: CreditReviewPage(productId: 'product-1')),
      ),
    );
    await tester.pump();

    final illustration = find.byKey(const Key('credit-review-illustration'));
    expect(tester.getTopLeft(illustration).dy, closeTo(290, 1));
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('credit-review-scroll')),
      const Offset(0, -180),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('credit-review-progress-label')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(illustration).dy, lessThan(290));
    expect(tester.takeException(), isNull);
  });
}
