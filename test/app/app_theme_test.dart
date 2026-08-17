import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/theme/app_theme.dart';

void main() {
  testWidgets('disables the iOS edge swipe back gesture app-wide', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Second page')),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsOneWidget);

    await tester.dragFrom(const Offset(1, 300), const Offset(340, 0));
    await tester.pumpAndSettle();

    expect(find.text('Second page'), findsOneWidget);
  });
}
