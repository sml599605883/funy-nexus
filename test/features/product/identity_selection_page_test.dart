import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/certification/identity_selection_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

void main() {
  testWidgets('shows identity options from the first and later groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _IdentityGateway(),
        child: const MaterialApp(
          home: IdentitySelectionPage(productId: 'product-1'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ID Verification'), findsOneWidget);
    expect(find.text('Recommended ID Type'), findsOneWidget);
    expect(find.text('DRIVINGLICENSE'), findsOneWidget);
    expect(find.text('Other Options'), findsOneWidget);
    expect(find.text('TIN'), findsOneWidget);
    expect(find.byKey(const Key('identityDashedDivider')), findsOneWidget);
  });
}

class _IdentityGateway implements ProductGateway {
  @override
  Future<ProductIdentityData> fetchIdentityOptions(String productId) async {
    return ProductIdentityData.fromJson({
      'polycythemic': [
        ['DRIVINGLICENSE', 'PRC'],
        ['TIN'],
      ],
    });
  }

  @override
  Future<ProductAdmissionData> requestAdmission(String productId) =>
      throw UnimplementedError();

  @override
  Future<ProductDetailData> fetchProductDetail(String productId) =>
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

  @override
  Future<IdentityRecognitionData> uploadIdentityDocument({
    required String filePath,
    required String identityType,
    required bool wasCapturedWithCamera,
  }) => throw UnimplementedError();

  @override
  Future<void> saveIdentityDocument({
    required String fullName,
    required String idNumber,
    required String dateOfBirth,
    required String identityType,
  }) => throw UnimplementedError();
}
