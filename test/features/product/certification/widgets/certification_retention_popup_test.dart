import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_popup.dart';

void main() {
  testWidgets('matches the design button positions and styles', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPopup(tester, onExit: () {});

    final card = tester.getRect(
      find.byKey(CertificationRetentionPopup.cardKey),
    );
    final continueButton = tester.getRect(
      find.byKey(CertificationRetentionPopup.continueButtonKey),
    );
    final exitButton = tester.getRect(
      find.byKey(CertificationRetentionPopup.exitButtonKey),
    );

    expect(card.size, const Size(375, 500));
    expect(continueButton.left - card.left, 24);
    expect(continueButton.top - card.top, closeTo(307.69, 0.01));
    expect(continueButton.width, 327.0);
    expect(continueButton.height, 40.0);
    expect(exitButton.top - card.top, closeTo(407.69, 0.01));
    expect(exitButton.height, 18.0);

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(
                      CertificationRetentionPopup.continueButtonKey,
                    ),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors, const [
      AppColors.mineRetentionContinueStart,
      AppColors.mineRetentionContinueEnd,
    ]);
    expect(decoration.borderRadius, BorderRadius.circular(20));
  });

  testWidgets('Continue dismisses and Exit invokes its callback once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var exitCount = 0;
    await _pumpPopup(tester, onExit: () => exitCount++);

    await tester.tap(find.byKey(CertificationRetentionPopup.continueButtonKey));
    await tester.pumpAndSettle();
    expect(exitCount, 0);

    await _pumpPopup(tester, onExit: () => exitCount++);
    await tester.tap(find.byKey(CertificationRetentionPopup.exitButtonKey));
    await tester.pumpAndSettle();
    expect(exitCount, 1);
  });
}

Future<void> _pumpPopup(
  WidgetTester tester, {
  required VoidCallback onExit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => CertificationRetentionPopup(
                imageUrl: 'https://example.test/retention.png',
                continueText: 'Continue',
                exitText: 'Exit',
                onExit: onExit,
                imageProvider: const AssetImage(
                  'assets/identity_upload_background.png',
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
}
