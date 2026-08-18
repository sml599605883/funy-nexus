import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/features/product/certification/bind_card_page.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_progress.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_form.dart';
import 'package:fund_nexus/features/product/data/bind_card_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

void main() {
  testWidgets('renders the dynamic bank form and preserves selection per tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = _Gateway();

    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ResponsiveScope(child: child!),
        home: BindCardPage(
          productId: 'product-1',
          orderNumber: 'order-1',
          gateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('E-wallet Account'), findsOneWidget);
    expect(
      tester
          .widget<CertificationProgress>(find.byType(CertificationProgress))
          .currentStep,
      4,
    );
    expect(find.text('Double-check your account details.'), findsOneWidget);
    expect(find.byKey(const Key('bindCardPicker-channelCode')), findsOneWidget);
    expect(find.byType(PersonalInformationFieldShell), findsNWidgets(2));
    expect(find.byType(PersonalInformationInputField), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset,
      isFalse,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                AppAssets.identityUploadBackground,
      ),
      findsOneWidget,
    );

    final bankTab = find.byKey(const Key('bindCardTab-2'));
    await Scrollable.ensureVisible(tester.element(bankTab), alignment: 0.25);
    await tester.tap(bankTab);
    await tester.pumpAndSettle();
    expect(find.text('Bank Account'), findsOneWidget);

    final accountInput = find.byKey(const Key('bindCardInput-cardNo'));
    await tester.ensureVisible(accountInput);
    await tester.tap(accountInput);
    await tester.pumpAndSettle();
    final suggestion = find.byKey(const Key('bindCardSuggestion-cardNo'));
    expect(suggestion, findsOneWidget);
    await tester.tap(suggestion);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(accountInput).controller!.text,
      '0123456789',
    );
    expect(suggestion, findsNothing);

    final picker = find.byKey(const Key('bindCardPicker-channelCode'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banco de Oro'));
    await tester.pumpAndSettle();
    expect(find.text('Banco de Oro'), findsOneWidget);

    final walletTab = find.byKey(const Key('bindCardTab-1'));
    await Scrollable.ensureVisible(tester.element(walletTab), alignment: 0.25);
    await tester.pumpAndSettle();
    await tester.tap(walletTab);
    await tester.pumpAndSettle();
    expect(find.text('E-wallet Account'), findsOneWidget);
    await Scrollable.ensureVisible(tester.element(bankTab), alignment: 0.25);
    await tester.pumpAndSettle();
    await tester.tap(bankTab);
    await tester.pumpAndSettle();
    expect(find.text('Banco de Oro'), findsOneWidget);
  });

  testWidgets('keeps a focused field above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ResponsiveScope(child: child!),
        home: BindCardPage(
          productId: 'product-1',
          orderNumber: 'order-1',
          gateway: _KeyboardGateway(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final input = find.byKey(const Key('bindCardInput-field5'));
    tester.widget<TextField>(input).focusNode!.requestFocus();
    await tester.pumpAndSettle();

    final media = MediaQuery.of(tester.element(input));
    expect(
      tester.getRect(input).bottom,
      lessThanOrEqualTo(media.size.height - 300),
    );
  });
}

class _Gateway implements BindCardGateway {
  @override
  Future<BindCardData> fetchBindCard(String productId) async => BindCardData(
    topPrompt: 'Choose a withdrawal method.',
    bottomPrompt: 'Double-check your account details.',
    groups: [
      _group('1', 'E-wallet', 'E-wallet Account'),
      _group('2', 'Bank', 'Bank Account'),
    ],
  );

  @override
  Future<BindCardSubmitResult> submitBindCard({
    required String productId,
    required String cardType,
    required Map<String, String> fields,
    required BindCardLivenessPayload liveness,
  }) async => const BindCardSubmitResult(code: '0', bindId: 'bind-1');
}

class _KeyboardGateway implements BindCardGateway {
  @override
  Future<BindCardData> fetchBindCard(String productId) async => BindCardData(
    topPrompt: 'Choose a withdrawal method.',
    bottomPrompt: 'Double-check your account details.',
    groups: [
      BindCardGroup(
        type: '2',
        label: 'Bank',
        fields: List.generate(
          6,
          (index) => BindCardField(
            title: 'Field $index',
            saveKey: 'field$index',
            placeholder: 'Please enter',
            control: BindCardControl.text,
            options: const [],
            required: true,
          ),
        ),
      ),
    ],
  );

  @override
  Future<BindCardSubmitResult> submitBindCard({
    required String productId,
    required String cardType,
    required Map<String, String> fields,
    required BindCardLivenessPayload liveness,
  }) async => const BindCardSubmitResult(code: '0', bindId: 'bind-1');
}

BindCardGroup _group(String type, String label, String accountLabel) =>
    BindCardGroup(
      type: type,
      label: label,
      fields: [
        const BindCardField(
          title: 'Select your recipient bank',
          saveKey: 'channelCode',
          placeholder: 'Please select',
          control: BindCardControl.selection,
          options: [
            BindCardOption(
              label: 'Banco de Oro',
              value: 'BDO',
              logoUrl: '',
              available: true,
            ),
          ],
          required: true,
        ),
        BindCardField(
          title: accountLabel,
          saveKey: 'cardNo',
          placeholder: 'Please enter your account',
          control: BindCardControl.text,
          options: const [],
          required: true,
          suggestedValue: '0123456789',
        ),
      ],
    );
