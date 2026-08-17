import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';

void main() {
  testWidgets('shows an optional back control without shifting the title', (
    tester,
  ) async {
    var didGoBack = false;
    await tester.pumpWidget(
      _page(
        CertificationPageHeader(
          title: 'Verification',
          backButtonKey: const Key('back'),
          onBack: () => didGoBack = true,
        ),
      ),
    );

    expect(find.text('Verification'), findsOneWidget);
    await tester.tap(find.byKey(const Key('back')));
    expect(didGoBack, isTrue);
  });

  testWidgets('omits the back control when navigation is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(const CertificationPageHeader(title: 'Verification')),
    );

    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('keeps guidance in the 57px prompt area', (tester) async {
    await tester.pumpWidget(
      _page(
        const CertificationGuidance(
          key: Key('guidance'),
          text: 'Use the shared guidance component.',
          width: 187,
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('guidance'))).height,
      closeTo(800 * 57 / 375, 0.01),
    );
  });
}

Widget _page(Widget child) => MaterialApp(
  home: ResponsiveScope(child: Scaffold(body: child)),
);
