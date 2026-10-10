import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/theme/app_theme.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/credit_review/credit_review_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/credit_review_polling_coordinator.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets(
    'continues to the product detail when admission still reports recredit '
    'after approval',
    (tester) async {
      final gateway = _ReviewGateway();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<SessionStore>.value(value: _Session()),
            RepositoryProvider<ProductGateway>.value(value: gateway),
            RepositoryProvider<PermissionCoordinator>.value(
              value: PermissionCoordinator(
                requestLocation: () async => PermissionStatus.granted,
              ),
            ),
            RepositoryProvider<ProductApplicationFlow>(
              create: (context) => ProductApplicationFlow(
                repository: gateway,
                sessionStore: context.read<SessionStore>(),
                permissions: context.read<PermissionCoordinator>(),
              ),
            ),
            RepositoryProvider<CreditReviewPollingCoordinator>(
              create: (_) => CreditReviewPollingCoordinator(
                gateway: gateway,
                interval: const Duration(milliseconds: 5),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) =>
                EasyLoading.init()(context, child ?? const SizedBox.shrink()),
            home: const CreditReviewPage(productId: 'product-1'),
          ),
        ),
      );

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      // The pushed product web page needs the inappwebview platform, which is
      // not registered in widget tests; drop that build error and assert the
      // navigation itself.
      tester.takeException();

      expect(gateway.reviewCalls, 1);
      expect(gateway.admissionRequests, ['product-1']);
      expect(gateway.detailRequests, ['product-1']);
      expect(gateway.destinationRequests, ['order-1']);
      expect(find.byType(ProductWebPage), findsOneWidget);
    },
  );
}

class _Session extends SessionStore {
  _Session() : super(_Persistence());

  @override
  bool get isAuthenticated => true;
}

class _Persistence implements SessionPersistence {
  @override
  Future<String?> readPhone() async => '09171234567';

  @override
  Future<String?> readSessionId() async => 'session-1';

  @override
  Future<void> writePhone(String? phone) async {}

  @override
  Future<void> writeSessionId(String? sessionId) async {}
}

class _ReviewGateway implements ProductGateway {
  int reviewCalls = 0;
  final admissionRequests = <String>[];
  final detailRequests = <String>[];
  final destinationRequests = <String>[];

  @override
  Future<CreditReviewData> fetchCreditReview() async {
    reviewCalls++;
    return const CreditReviewData(isApproved: true);
  }

  @override
  Future<ProductAdmissionData> requestAdmission(String productId) async {
    admissionRequests.add(productId);
    return const ProductAdmissionData(
      statusCode: 302,
      message: '',
      target: 'ph://fund-nexus/ios/MagnetiseRewrap?modernised=product-1',
    );
  }

  @override
  Future<ProductDetailData> fetchProductDetail(String productId) async {
    detailRequests.add(productId);
    return const ProductDetailData(
      statusCode: 200,
      product: ProductDetailProduct(
        productId: 'product-1',
        orderNumber: 'order-1',
        amount: '1000',
        loanTerm: '7',
        termType: 'day',
      ),
      nextStep: ProductDetailNextStep(type: '', title: ''),
    );
  }

  @override
  Future<LoanDestinationData> fetchLoanDestination({
    required String orderNumber,
    required String amount,
    required String loanTerm,
    required String termType,
  }) async {
    destinationRequests.add(orderNumber);
    return const LoanDestinationData(target: 'https://web.example.com/loan');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
