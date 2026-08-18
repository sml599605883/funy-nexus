import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

typedef ProductLoadingAction = Future<void> Function();
typedef ProductMessageAction = Future<void> Function(String message);
typedef ProductLoginAction = Future<bool> Function(String productId);
typedef ProductTargetAction = Future<void> Function(String target);
typedef ProductStepAction =
    Future<void> Function(String step, String productId);
typedef ProductLocationSettingsPrompt = Future<bool> Function(String message);

class ProductApplicationFlow {
  ProductApplicationFlow({
    required this.repository,
    required this.sessionStore,
    required this.permissions,
    this.reportService,
  });

  final ProductGateway repository;
  final SessionStore sessionStore;
  final PermissionCoordinator permissions;
  final ReportService? reportService;
  bool _requestInFlight = false;

  Future<void> apply({
    required String productId,
    required ProductLoginAction openLogin,
    required ProductTargetAction openTarget,
    required ProductTargetAction openCreditReview,
    required ProductStepAction openCertification,
    required ProductLoadingAction showLoading,
    required ProductLoadingAction dismissLoading,
    required ProductMessageAction showMessage,
    ProductLocationSettingsPrompt? showLocationSettingsPrompt,
  }) async {
    final normalizedId = productId.trim();
    if (normalizedId.isEmpty || _requestInFlight) return;

    _requestInFlight = true;
    try {
      if (!sessionStore.isAuthenticated && !await openLogin(normalizedId)) {
        return;
      }
      if (!sessionStore.isAuthenticated) return;

      final locationDecision = await permissions.requestLocationAccess();
      if (locationDecision != LocationAccessDecision.granted) {
        final continueWithoutLocation = await _handleLocationFailure(
          locationDecision,
          showMessage: showMessage,
          showLocationSettingsPrompt: showLocationSettingsPrompt,
        );
        if (!continueWithoutLocation) return;
      }

      await _runAdmission(
        productId: normalizedId,
        openTarget: openTarget,
        openCreditReview: openCreditReview,
        openCertification: openCertification,
        showLoading: showLoading,
        dismissLoading: dismissLoading,
        showMessage: showMessage,
      );
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> resumeAfterCreditReview({
    required String productId,
    required ProductTargetAction openTarget,
    required ProductTargetAction openCreditReview,
    required ProductStepAction openCertification,
    required ProductLoadingAction showLoading,
    required ProductLoadingAction dismissLoading,
    required ProductMessageAction showMessage,
  }) {
    if (!sessionStore.isAuthenticated || productId.trim().isEmpty) {
      return Future.value();
    }
    return _runAdmission(
      productId: productId.trim(),
      openTarget: openTarget,
      openCreditReview: openCreditReview,
      openCertification: openCertification,
      showLoading: showLoading,
      dismissLoading: dismissLoading,
      showMessage: showMessage,
    );
  }

  Future<bool> _handleLocationFailure(
    LocationAccessDecision decision, {
    required ProductMessageAction showMessage,
    required ProductLocationSettingsPrompt? showLocationSettingsPrompt,
  }) async {
    final requiresSettings =
        decision == LocationAccessDecision.settingsRequired ||
        decision == LocationAccessDecision.serviceDisabled;
    final message = decision == LocationAccessDecision.serviceDisabled
        ? 'Turn on Location Services to continue your application.'
        : 'Location access is required to continue.';
    if (!requiresSettings || showLocationSettingsPrompt == null) {
      await showMessage(message);
      return false;
    }
    if (await showLocationSettingsPrompt(message)) {
      await openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> _runAdmission({
    required String productId,
    required ProductTargetAction openTarget,
    required ProductTargetAction openCreditReview,
    required ProductStepAction openCertification,
    required ProductLoadingAction showLoading,
    required ProductLoadingAction dismissLoading,
    required ProductMessageAction showMessage,
  }) async {
    var loadingVisible = false;
    try {
      await showLoading();
      loadingVisible = true;
      unawaited(reportService?.reportLocationAndDevice());
      final admission = await repository.requestAdmission(productId);
      switch (admission.disposition) {
        case ProductAdmissionDisposition.web:
          await dismissLoading();
          loadingVisible = false;
          await openTarget(admission.target);
          return;
        case ProductAdmissionDisposition.creditReview:
          await dismissLoading();
          loadingVisible = false;
          await openCreditReview(admission.target);
          return;
        case ProductAdmissionDisposition.detail:
          final detail = await _fetchProductDetail(productId);
          await _continueFromDetail(
            requestedProductId: productId,
            detail: detail,
            openTarget: openTarget,
            openCertification: openCertification,
            showMessage: showMessage,
            beforeNavigate: () async {
              if (loadingVisible) {
                await dismissLoading();
                loadingVisible = false;
              }
            },
          );
        case ProductAdmissionDisposition.unavailable:
          await showMessage(
            admission.message.isEmpty
                ? 'This product is not available right now.'
                : admission.message,
          );
      }
    } catch (error) {
      await showMessage(_messageFor(error));
    } finally {
      if (loadingVisible) await dismissLoading();
    }
  }

  Future<void> resumeAfterCertification({
    required String productId,
    required ProductTargetAction openTarget,
    required ProductStepAction openCertification,
    required ProductLoadingAction showLoading,
    required ProductLoadingAction dismissLoading,
    required ProductMessageAction showMessage,
  }) async {
    var loadingVisible = false;
    try {
      await showLoading();
      loadingVisible = true;
      final detail = await _fetchProductDetail(productId);
      await _continueFromDetail(
        requestedProductId: productId,
        detail: detail,
        openTarget: openTarget,
        openCertification: openCertification,
        showMessage: showMessage,
        beforeNavigate: () async {
          if (!loadingVisible) return;
          await dismissLoading();
          loadingVisible = false;
        },
      );
    } catch (error) {
      await showMessage(_messageFor(error));
    } finally {
      if (loadingVisible) await dismissLoading();
    }
  }

  Future<ProductDetailData> _fetchProductDetail(String productId) async {
    final detail = await repository.fetchProductDetail(productId);
    sessionStore.cacheProductDetailCertification(
      identityGuidance: detail.certificationCopy.identityUploadGuidance,
      faceGuidance: detail.certificationCopy.faceVerificationGuidance,
      orderNumber: detail.product.orderNumber,
    );
    return detail;
  }

  Future<void> _continueFromDetail({
    required String requestedProductId,
    required ProductDetailData detail,
    required ProductTargetAction openTarget,
    required ProductStepAction openCertification,
    required ProductMessageAction showMessage,
    required ProductLoadingAction beforeNavigate,
  }) async {
    final productId = detail.product.productId.isEmpty
        ? requestedProductId
        : detail.product.productId;
    final nextStep = _certificationStepMap[detail.nextStep.type];
    if (nextStep != null) {
      await beforeNavigate();
      await openCertification(nextStep, productId);
      return;
    }
    if (detail.nextStep.type.isNotEmpty) {
      await showMessage('The next certification step is not supported yet.');
      return;
    }
    if (detail.statusCode != 200 || detail.product.orderNumber.isEmpty) {
      await showMessage('Product details are not ready yet.');
      return;
    }
    final reportStart = ReportService.nowSeconds();
    final destination = await repository.fetchLoanDestination(
      orderNumber: detail.product.orderNumber,
      amount: detail.product.amount,
      loanTerm: detail.product.loanTerm,
      termType: detail.product.termType,
    );
    final reporter = reportService;
    if (reporter != null) {
      unawaited(
        reporter.reportRisk(
          productId: productId,
          sceneType: '9',
          orderNo: detail.product.orderNumber,
          startTimeSeconds: reportStart,
        ),
      );
    }
    if (productWebUri(destination.target) == null) {
      await showMessage('Unable to open the loan confirmation page.');
      return;
    }
    await beforeNavigate();
    await openTarget(destination.target);
  }

  String _messageFor(Object error) =>
      error is ApiException ? error.message : 'Unable to continue application.';

  static const _certificationStepMap = {
    'public': 'public',
    'Inviolably': 'public',
    'face': 'face',
    'CrampingLushing': 'face',
    'personal': 'personal',
    'PygidiumAgmas': 'personal',
    'job': 'work',
    'work': 'work',
    'Peripheral': 'work',
    'ext': 'ext',
    'EsotericNimbler': 'ext',
    'bank': 'bank',
    'Rondo': 'bank',
  };
}
