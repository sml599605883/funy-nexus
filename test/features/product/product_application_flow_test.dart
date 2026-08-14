import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('uses login then location before requesting admission', () async {
    final session = _session(authenticated: false);
    final gateway = _Gateway(
      admission: const ProductAdmissionData(
        statusCode: 302,
        message: '',
        target: 'https://web.example.com/application',
      ),
    );
    final events = <String>[];
    final flow = ProductApplicationFlow(
      repository: gateway,
      sessionStore: session,
      permissions: PermissionCoordinator(
        requestLocation: () async {
          events.add('location');
          return PermissionStatus.granted;
        },
      ),
    );

    await flow.apply(
      productId: ' product-1 ',
      openLogin: (_) async {
        events.add('login');
        await session.save(phone: '09171234567', sessionId: 'session-1');
        session.authenticated = true;
        return true;
      },
      openTarget: (target) async => events.add('target:$target'),
      openCreditReview: (_) async => events.add('review'),
      openCertification: (step, productId) async =>
          events.add('certification:$step:$productId'),
      showLoading: () async => events.add('loading'),
      dismissLoading: () async => events.add('dismiss'),
      showMessage: (message) async => events.add('message:$message'),
    );

    expect(events, [
      'login',
      'location',
      'loading',
      'dismiss',
      'target:https://web.example.com/application',
    ]);
    expect(gateway.admissionRequests, ['product-1']);
  });

  test('does not submit admission when location is declined', () async {
    final gateway = _Gateway();
    final messages = <String>[];
    final flow = ProductApplicationFlow(
      repository: gateway,
      sessionStore: _session(authenticated: true),
      permissions: PermissionCoordinator(
        requestLocation: () async => PermissionStatus.denied,
      ),
    );

    await flow.apply(
      productId: 'product-1',
      openLogin: (_) async => false,
      openTarget: (_) async {},
      openCreditReview: (_) async {},
      openCertification: (step, productId) async {},
      showLoading: () async {},
      dismissLoading: () async {},
      showMessage: (message) async => messages.add(message),
    );

    expect(gateway.admissionRequests, isEmpty);
    expect(messages, ['Location access is required to continue.']);
  });

  test(
    'loads product details and opens the server-selected certification',
    () async {
      final gateway = _Gateway(
        admission: const ProductAdmissionData(
          statusCode: 200,
          message: '',
          target: '',
        ),
        detail: const ProductDetailData(
          statusCode: 200,
          product: ProductDetailProduct(
            productId: 'server-product',
            orderNumber: '',
            amount: '',
            loanTerm: '',
            termType: '',
          ),
          nextStep: ProductDetailNextStep(
            type: 'PygidiumAgmas',
            title: 'Personal',
          ),
        ),
      );
      final steps = <String>[];
      final flow = _authenticatedFlow(gateway);

      await flow.apply(
        productId: 'product-1',
        openLogin: (_) async => false,
        openTarget: (_) async {},
        openCreditReview: (_) async {},
        openCertification: (step, productId) async =>
            steps.add('$step:$productId'),
        showLoading: () async {},
        dismissLoading: () async {},
        showMessage: (_) async {},
      );

      expect(gateway.detailRequests, ['product-1']);
      expect(steps, ['personal:server-product']);
    },
  );

  test(
    'uses order continuation only after product detail has no next step',
    () async {
      final gateway = _Gateway(
        admission: const ProductAdmissionData(
          statusCode: 200,
          message: '',
          target: '',
        ),
        detail: const ProductDetailData(
          statusCode: 200,
          product: ProductDetailProduct(
            productId: 'product-1',
            orderNumber: 'ORDER-1',
            amount: '1000.00',
            loanTerm: '7',
            termType: '1',
          ),
          nextStep: ProductDetailNextStep(type: '', title: ''),
        ),
        destination: const LoanDestinationData(
          target: 'https://web.example.com/#/Antimanagement',
        ),
      );
      final targets = <String>[];
      final flow = _authenticatedFlow(gateway);

      await flow.apply(
        productId: 'product-1',
        openLogin: (_) async => false,
        openTarget: (target) async => targets.add(target),
        openCreditReview: (_) async {},
        openCertification: (step, productId) async {},
        showLoading: () async {},
        dismissLoading: () async {},
        showMessage: (_) async {},
      );

      expect(gateway.destinationRequests, ['ORDER-1:1000.00:7:1']);
      expect(targets, ['https://web.example.com/#/Antimanagement']);
    },
  );

  test('suppresses a second tap while admission is pending', () async {
    final admission = Completer<ProductAdmissionData>();
    final gateway = _Gateway()..pendingAdmission = admission;
    final flow = _authenticatedFlow(gateway);
    final first = flow.apply(
      productId: 'product-1',
      openLogin: (_) async => false,
      openTarget: (_) async {},
      openCreditReview: (_) async {},
      openCertification: (step, productId) async {},
      showLoading: () async {},
      dismissLoading: () async {},
      showMessage: (_) async {},
    );
    await Future<void>.delayed(Duration.zero);
    final second = flow.apply(
      productId: 'product-1',
      openLogin: (_) async => false,
      openTarget: (_) async {},
      openCreditReview: (_) async {},
      openCertification: (step, productId) async {},
      showLoading: () async {},
      dismissLoading: () async {},
      showMessage: (_) async {},
    );

    admission.complete(
      const ProductAdmissionData(statusCode: 302, message: '', target: ''),
    );
    await Future.wait([first, second]);

    expect(gateway.admissionRequests, ['product-1']);
  });

  test(
    'retries admission after credit approval without location prompt',
    () async {
      final gateway = _Gateway(
        admission: const ProductAdmissionData(
          statusCode: 302,
          message: '',
          target: 'https://web.example.com/application',
        ),
      );
      var locationRequests = 0;
      final flow = ProductApplicationFlow(
        repository: gateway,
        sessionStore: _session(authenticated: true),
        permissions: PermissionCoordinator(
          requestLocation: () async {
            locationRequests++;
            return PermissionStatus.denied;
          },
        ),
      );
      final targets = <String>[];

      await flow.resumeAfterCreditReview(
        productId: 'product-1',
        openTarget: (target) async => targets.add(target),
        openCreditReview: (_) async {},
        openCertification: (step, productId) async {},
        showLoading: () async {},
        dismissLoading: () async {},
        showMessage: (_) async {},
      );

      expect(locationRequests, 0);
      expect(gateway.admissionRequests, ['product-1']);
      expect(targets, ['https://web.example.com/application']);
    },
  );
}

ProductApplicationFlow _authenticatedFlow(_Gateway gateway) {
  return ProductApplicationFlow(
    repository: gateway,
    sessionStore: _session(authenticated: true),
    permissions: PermissionCoordinator(
      requestLocation: () async => PermissionStatus.granted,
    ),
  );
}

_TestSessionStore _session({required bool authenticated}) {
  return _TestSessionStore(
    _MemoryPersistence(
      phone: authenticated ? '09171234567' : null,
      sessionId: authenticated ? 'session-1' : null,
    ),
    authenticated: authenticated,
  );
}

class _Gateway implements ProductGateway {
  _Gateway({this.admission, this.detail, this.destination});

  ProductAdmissionData? admission;
  ProductDetailData? detail;
  LoanDestinationData? destination;
  Completer<ProductAdmissionData>? pendingAdmission;
  final admissionRequests = <String>[];
  final detailRequests = <String>[];
  final destinationRequests = <String>[];

  @override
  Future<ProductAdmissionData> requestAdmission(String productId) {
    admissionRequests.add(productId);
    return pendingAdmission?.future ??
        Future.value(
          admission ??
              const ProductAdmissionData(
                statusCode: 302,
                message: '',
                target: '',
              ),
        );
  }

  @override
  Future<ProductDetailData> fetchProductDetail(String productId) {
    detailRequests.add(productId);
    return Future.value(detail!);
  }

  @override
  Future<ProductIdentityData> fetchIdentityOptions(String productId) async =>
      const ProductIdentityData(groups: []);

  @override
  Future<CreditReviewData> fetchCreditReview() async =>
      const CreditReviewData(isApproved: false);

  @override
  Future<LoanDestinationData> fetchLoanDestination({
    required String orderNumber,
    required String amount,
    required String loanTerm,
    required String termType,
  }) {
    destinationRequests.add('$orderNumber:$amount:$loanTerm:$termType');
    return Future.value(destination!);
  }
}

class _TestSessionStore extends SessionStore {
  _TestSessionStore(super.persistence, {required this.authenticated});

  bool authenticated;

  @override
  bool get isAuthenticated => authenticated;
}

class _MemoryPersistence implements SessionPersistence {
  _MemoryPersistence({this.phone, this.sessionId});

  String? phone;
  String? sessionId;

  @override
  Future<String?> readPhone() async => phone;

  @override
  Future<String?> readSessionId() async => sessionId;

  @override
  Future<void> writePhone(String? value) async => phone = value;

  @override
  Future<void> writeSessionId(String? value) async => sessionId = value;
}
