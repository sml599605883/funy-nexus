import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/certification/identity_selection_page.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

void main() {
  testWidgets('loads the upload guidance from product detail', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _UploadGateway(),
        child: const MaterialApp(
          home: IdentityUploadPage(productId: 'product-1', identityType: 'PRC'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Use a clear ID photo.'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));
    expect(
      tester.getSize(find.byKey(const Key('identityUploadGuidance'))).height,
      57,
    );
  });

  testWidgets('adapts upload guidance font size to the fixed prompt area', (
    tester,
  ) async {
    const shortGuidance = 'Please confirm';
    const longGuidance =
        'Please confirm that the ID photo is clear, complete, and readable.';
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _UploadGateway(guidance: shortGuidance),
        child: MaterialApp(
          home: IdentityUploadPage(
            key: ValueKey(shortGuidance),
            productId: 'product-1',
            identityType: 'PRC',
          ),
        ),
      ),
    );
    await tester.pump();
    final shortText = tester.widget<Text>(find.text(shortGuidance));

    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _UploadGateway(guidance: longGuidance),
        child: MaterialApp(
          home: IdentityUploadPage(
            key: ValueKey(longGuidance),
            productId: 'product-1',
            identityType: 'PRC',
          ),
        ),
      ),
    );
    await tester.pump();
    final longText = tester.widget<Text>(find.text(longGuidance));

    expect(shortText.style!.fontSize, greaterThan(longText.style!.fontSize!));
    expect(
      tester.getSize(find.byKey(const Key('identityUploadGuidance'))),
      const Size(187, 57),
    );
  });

  testWidgets('opens upload page with selected identity type', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _UploadGateway(),
        child: const MaterialApp(
          home: IdentitySelectionPage(productId: 'product-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('PRC'));
    await tester.pumpAndSettle();

    expect(find.byType(IdentityUploadPage), findsOneWidget);
  });
}

class _UploadGateway implements ProductGateway {
  _UploadGateway({this.guidance = 'Use a clear ID photo.'});

  final String guidance;

  @override
  Future<ProductDetailData> fetchProductDetail(String productId) async {
    return ProductDetailData.fromJson({
      'trokes': 200,
      'rubicund': {'qintar': guidance},
    });
  }

  @override
  Future<ProductIdentityData> fetchIdentityOptions(String productId) async {
    return ProductIdentityData.fromJson({
      'polycythemic': [
        ['PRC'],
      ],
    });
  }

  @override
  Future<ProductAdmissionData> requestAdmission(String productId) =>
      throw UnimplementedError();

  @override
  Future<CreditReviewData> fetchCreditReview() => throw UnimplementedError();

  @override
  Future<LoanDestinationData> fetchLoanDestination({
    required String orderNumber,
    required String amount,
    required String loanTerm,
    required String termType,
  }) => throw UnimplementedError();
}
