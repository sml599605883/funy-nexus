import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/certification/face_token_handler.dart';
import 'package:fund_nexus/features/product/certification/identity_selection_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

void main() {
  testWidgets('treats a 200 token as ready to continue', (tester) async {
    bool? ready;
    await _pumpHandler(
      tester,
      resultCode: '200',
      onResult: (value) => ready = value,
    );

    expect(ready, isTrue);
    expect(find.text('Poor Image Quality'), findsNothing);
  });

  testWidgets('prompts for another ID upload when the token is 400', (
    tester,
  ) async {
    bool? ready;
    await _pumpHandler(
      tester,
      resultCode: '400',
      onResult: (value) => ready = value,
    );

    expect(find.text('Poor Image Quality'), findsOneWidget);
    expect(
      find.text(
        "The submitted ID photo didn't meet our quality standards. Please "
        'capture a new one with better focus and lighting, or upload an '
        'existing clear photo.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(ready, isFalse);
    expect(find.byType(IdentitySelectionPage), findsNothing);
  });

  testWidgets('opens identity selection when another upload is confirmed', (
    tester,
  ) async {
    await _pumpHandler(tester, resultCode: '400', onResult: (_) {});

    await tester.tap(find.text('Upload Another'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(IdentitySelectionPage), findsOneWidget);
  });

  testWidgets('surfaces the server message for a 500 token', (tester) async {
    bool? ready;
    await _pumpHandler(
      tester,
      resultCode: '500',
      errorMessage: 'Verification service unavailable',
      onResult: (value) => ready = value,
    );

    expect(ready, isFalse);
    expect(find.text('Verification service unavailable'), findsOneWidget);

    await _dismissToast(tester);
  });

  testWidgets('falls back when a failed token carries no message', (
    tester,
  ) async {
    bool? ready;
    await _pumpHandler(
      tester,
      resultCode: '500',
      onResult: (value) => ready = value,
    );

    expect(ready, isFalse);
    expect(find.text('Failed to get verification token'), findsOneWidget);

    await _dismissToast(tester);
  });
}

Future<void> _pumpHandler(
  WidgetTester tester, {
  required String resultCode,
  String errorMessage = '',
  required void Function(bool value) onResult,
}) async {
  await tester.pumpWidget(
    RepositoryProvider<ProductGateway>.value(
      value: _IdentityGateway(),
      child: MaterialApp(
        builder: (context, child) => EasyLoading.init()(context, child),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                onResult(
                  await handleFaceTokenResponse(
                    context,
                    token: FaceLivenessToken(
                      resultCode: resultCode,
                      license: 'license',
                      errorMessage: errorMessage,
                      livenessType: 7,
                    ),
                    productId: 'product-42',
                  ),
                );
              },
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Start'));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _dismissToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 400));
}

class _IdentityGateway implements ProductGateway {
  @override
  Future<ProductIdentityData> fetchIdentityOptions(String productId) async =>
      ProductIdentityData.fromJson({
        'polycythemic': [
          ['TIN'],
        ],
      });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
