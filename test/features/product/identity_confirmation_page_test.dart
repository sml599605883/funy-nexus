import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/certification/identity_confirmation_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

void main() {
  testWidgets('shows recognized identity data in the confirmation design', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: IdentityConfirmationPage(
          productId: 'product-1',
          identityType: 'PRC',
          recognizedInfo: _recognizedInfo(),
        ),
      ),
    );

    expect(find.text('ID Verification'), findsOneWidget);
    expect(
      find.text('Check your info once more to keep everything on track.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('identityConfirmationImage')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('identityConfirmationCard'))),
      const Size(343, 408),
    );
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('ID No.'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
  });

  testWidgets('saves editable identity data then continues the product flow', (
    tester,
  ) async {
    final gateway = _ConfirmationGateway();
    var continued = false;
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: EasyLoading.init(),
        home: IdentityConfirmationPage(
          productId: 'product-1',
          identityType: 'PRC',
          recognizedInfo: _recognizedInfo(),
          gateway: gateway,
          onSaved: () async => continued = true,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('identityConfirmationNameInput')),
      'JUAN DELA CRUZ',
    );
    await tester.enterText(
      find.byKey(const Key('identityConfirmationIdInput')),
      'ID-9988',
    );
    await tester.tap(find.byKey(const Key('identityConfirmationSubmit')));
    await tester.pumpAndSettle();

    expect(gateway.fullName, 'JUAN DELA CRUZ');
    expect(gateway.idNumber, 'ID-9988');
    expect(gateway.dateOfBirth, '31-05-1995');
    expect(gateway.identityType, 'PRC');
    expect(continued, isTrue);
  });

  testWidgets('uses cached product detail guidance and custom date picker', (
    tester,
  ) async {
    final gateway = _ConfirmationGateway();
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: IdentityConfirmationPage(
          productId: 'product-1',
          identityType: 'PRC',
          recognizedInfo: _recognizedInfo(),
          gateway: gateway,
          promptMessage:
              'Please confirm the information below before continuing.',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Please confirm the information below before continuing.'),
      findsOneWidget,
    );
    expect(gateway.productDetailRequests, 0);

    await tester.tap(
      find.byKey(const Key('identityConfirmationBirthdayInput')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('identityConfirmationDateDone')),
      findsOneWidget,
    );
    expect(find.text('1995'), findsOneWidget);
    await tester.tap(find.byKey(const Key('identityConfirmationDateDone')));
    await tester.pumpAndSettle();
    expect(find.text('31-05-1995'), findsOneWidget);
  });

  testWidgets('hides back navigation and blocks route popping', (tester) async {
    final gateway = _ConfirmationGateway();
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => IdentityConfirmationPage(
                  productId: 'product-1',
                  identityType: 'PRC',
                  recognizedInfo: _recognizedInfo(),
                  gateway: gateway,
                ),
              ),
            ),
            child: const Text('Open confirmation'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ID Verification'), findsOneWidget);
  });
}

IdentityRecognitionData _recognizedInfo() {
  return IdentityRecognitionData.fromJson({
    'emit': 'NAVEEN TOM VARGHESE',
    'outdueled': '623099344111',
    'matcher': 'Male',
    'palisades': '1995/05/31',
    'redepositing': '',
  });
}

class _ConfirmationGateway implements ProductGateway {
  int productDetailRequests = 0;
  String? fullName;
  String? idNumber;
  String? dateOfBirth;
  String? identityType;

  @override
  Future<CreditReviewData> fetchCreditReview() => throw UnimplementedError();

  @override
  Future<ProductDetailData> fetchProductDetail(String productId) {
    productDetailRequests += 1;
    throw UnimplementedError();
  }

  @override
  Future<ProductIdentityData> fetchIdentityOptions(String productId) =>
      throw UnimplementedError();

  @override
  Future<LoanDestinationData> fetchLoanDestination({
    required String orderNumber,
    required String amount,
    required String loanTerm,
    required String termType,
  }) => throw UnimplementedError();

  @override
  Future<ProductAdmissionData> requestAdmission(String productId) =>
      throw UnimplementedError();

  @override
  Future<void> saveIdentityDocument({
    required String fullName,
    required String idNumber,
    required String dateOfBirth,
    required String identityType,
  }) async {
    this.fullName = fullName;
    this.idNumber = idNumber;
    this.dateOfBirth = dateOfBirth;
    this.identityType = identityType;
  }

  @override
  Future<IdentityRecognitionData> uploadIdentityDocument({
    required String filePath,
    required String identityType,
    required bool wasCapturedWithCamera,
  }) => throw UnimplementedError();
}
