import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/personal_information_page.dart';

void main() {
  testWidgets('renders all fields from the personal-information design', (
    tester,
  ) async {
    await tester.pumpWidget(_page());

    expect(find.text('Basic identity information'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Marriage Status'), findsOneWidget);
    expect(find.text('Type of Residence'), findsOneWidget);
    expect(find.text('Home Phone Number'), findsOneWidget);
    expect(find.text('Address Input'), findsOneWidget);
    expect(find.text('Complete Address'), findsOneWidget);
    expect(find.text('Reason for Loan'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
  });

  testWidgets('updates a selected value from the choice panel', (tester) async {
    await tester.pumpWidget(_page());

    final education = find.byKey(const Key('personalInformation-Education'));
    await tester.ensureVisible(education);
    await tester.tap(education);
    await tester.pumpAndSettle();
    await tester.tap(find.text('College'));
    await tester.pumpAndSettle();

    expect(find.text('College'), findsOneWidget);
  });

  testWidgets('uses the cached product guidance in the prompt area', (
    tester,
  ) async {
    await tester.pumpWidget(_page(guidance: 'Use the product guidance.'));

    expect(find.text('Use the product guidance.'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('personalInformationGuidance')))
          .height,
      closeTo(800 * 57 / 375, 0.01),
    );
  });

  testWidgets('overlaps the form card with the centered progress panel', (
    tester,
  ) async {
    await tester.pumpWidget(_page());

    final progress = tester.getRect(
      find.byKey(const Key('personalInformationProgress')),
    );
    final formCard = tester.getRect(
      find.byKey(const Key('personalInformationFormCard')),
    );
    final scale = 800 / 375;

    expect(progress.left, closeTo(16 * scale, 0.01));
    expect(formCard.left, closeTo(16 * scale, 0.01));
    expect(formCard.top, closeTo(progress.bottom - 27 * scale, 0.01));
  });
}

Widget _page({String guidance = ''}) {
  final sessionStore = SessionStore(_TestSessionPersistence())
    ..cacheProductDetailIdentityGuidance(guidance);
  return MaterialApp(
    home: RepositoryProvider<SessionStore>.value(
      value: sessionStore,
      child: const ResponsiveScope(
        child: PersonalInformationPage(productId: 'product'),
      ),
    ),
  );
}

class _TestSessionPersistence implements SessionPersistence {
  @override
  Future<String?> readPhone() async => null;

  @override
  Future<String?> readSessionId() async => null;

  @override
  Future<void> writePhone(String? phone) async {}

  @override
  Future<void> writeSessionId(String? sessionId) async {}
}
