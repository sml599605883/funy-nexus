import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/face_verification_page.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_continuation.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('prunes completed certification pages before opening face', (
    tester,
  ) async {
    final session = _TestSessionStore(
      _MemorySessionPersistence(),
      authenticated: true,
    );
    final flow = ProductApplicationFlow(
      repository: _FaceStepGateway(),
      sessionStore: session,
      permissions: PermissionCoordinator(
        requestLocation: () async => PermissionStatus.granted,
      ),
    );

    await tester.pumpWidget(
      RepositoryProvider<SessionStore>.value(
        value: session,
        child: MaterialApp(
          builder: EasyLoading.init(),
          home: _HomePage(flow: flow),
        ),
      ),
    );

    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to face'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceVerificationPage), findsOneWidget);
    expect(find.text('Identity confirmation'), findsNothing);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Open confirmation'), findsOneWidget);
    expect(find.text('Identity confirmation'), findsNothing);
  });
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.flow});

  final ProductApplicationFlow flow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => _IdentityConfirmationStub(flow: flow),
              ),
            );
          },
          child: const Text('Open confirmation'),
        ),
      ),
    );
  }
}

class _IdentityConfirmationStub extends StatelessWidget {
  const _IdentityConfirmationStub({required this.flow});

  final ProductApplicationFlow flow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => IdentityUploadContinuationPage(
                  flow: flow,
                  productId: 'product-1',
                ),
              ),
            );
          },
          child: const Text('Continue to face'),
        ),
      ),
    );
  }
}

class _FaceStepGateway implements ProductGateway {
  @override
  Future<ProductDetailData> fetchProductDetail(String productId) async {
    return const ProductDetailData(
      statusCode: 200,
      product: ProductDetailProduct(
        productId: 'product-1',
        orderNumber: 'order-1',
        amount: '',
        loanTerm: '',
        termType: '',
      ),
      nextStep: ProductDetailNextStep(type: 'face', title: 'Face'),
    );
  }

  @override
  Future<CreditReviewData> fetchCreditReview() async =>
      const CreditReviewData(isApproved: false);

  @override
  Future<ProductIdentityData> fetchIdentityOptions(String productId) async =>
      const ProductIdentityData(groups: []);

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
  }) => throw UnimplementedError();

  @override
  Future<IdentityRecognitionData> uploadIdentityDocument({
    required String filePath,
    required String identityType,
    required bool wasCapturedWithCamera,
  }) => throw UnimplementedError();
}

class _TestSessionStore extends SessionStore {
  _TestSessionStore(super.persistence, {required this.authenticated});

  bool authenticated;

  @override
  bool get isAuthenticated => authenticated;
}

class _MemorySessionPersistence implements SessionPersistence {
  @override
  Future<String?> readPhone() async => null;

  @override
  Future<String?> readSessionId() async => null;

  @override
  Future<void> writePhone(String? phone) async {}

  @override
  Future<void> writeSessionId(String? sessionId) async {}
}
