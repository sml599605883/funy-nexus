import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_single_select_panel.dart';

void main() {
  testWidgets('fills the screen and centers the panel group', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        onPressed: (context) => showCertificationSingleSelectPanel<String>(
          context,
          options: const ['Female', 'Male'],
          labelBuilder: (option) => option,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('openSingleSelect')));
    await tester.pumpAndSettle();

    final dialog = tester.getRect(
      find.byKey(const Key('certificationSingleSelectPanel')),
    );
    final options = tester.getRect(
      find.byKey(const Key('certificationSingleSelectOptions')),
    );
    expect(dialog, const Rect.fromLTWH(0, 0, 375, 812));
    expect(options.left, closeTo(40, 0.01));
    expect(options.top, closeTo(335, 0.01));
  });

  testWidgets('keeps a 16 logical-pixel inset on wider screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(414, 896));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        onPressed: (context) => showCertificationSingleSelectPanel<String>(
          context,
          options: const ['Female', 'Male'],
          labelBuilder: (option) => option,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('openSingleSelect')));
    await tester.pumpAndSettle();

    final group = tester.getRect(
      find.byKey(const Key('greenActionPanelGroup')),
    );
    expect(group.left, closeTo(16, 0.01));
    expect(group.right, closeTo(398, 0.01));
  });

  testWidgets('selecting an option closes the panel without a check icon', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      _app(
        onPressed: (context) async {
          selected = await showCertificationSingleSelectPanel<String>(
            context,
            options: const ['Female', 'Male'],
            labelBuilder: (option) => option,
          );
        },
      ),
    );

    await tester.tap(find.byKey(const Key('openSingleSelect')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('certificationSingleSelectDialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('certificationSingleSelectPanelClose')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('certificationSingleSelectDialog')),
      findsNothing,
    );
    expect(selected, 'Male');
  });

  testWidgets('shows at most five rows and scrolls additional options', (
    tester,
  ) async {
    const options = [
      'Option 1',
      'Option 2',
      'Option 3',
      'Option 4',
      'Option 5',
      'Option 6',
      'Option 7',
    ];
    await tester.pumpWidget(
      _app(
        onPressed: (context) => showCertificationSingleSelectPanel<String>(
          context,
          options: options,
          labelBuilder: (option) => option,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('openSingleSelect')));
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('certificationSingleSelectOptions'));
    expect(tester.getSize(list).height, closeTo(5 * 48 + 4 * 12, 0.01));
    expect(find.text('Option 5'), findsOneWidget);
    expect(find.text('Option 6'), findsNothing);

    await tester.drag(list, const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(find.text('Option 6'), findsOneWidget);
  });
}

Widget _app({required Future<void> Function(BuildContext) onPressed}) {
  return MaterialApp(
    home: ResponsiveScope(
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('openSingleSelect'),
              onPressed: () => onPressed(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}
