import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/face/face_liveness_bridge.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/risk_report_scene.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_continuation.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_guard.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:permission_handler/permission_handler.dart';

typedef FaceLivenessLauncher =
    Future<FaceLivenessResult> Function(String license);
typedef FaceImageFileWriter = Future<String> Function(String imageBase64);

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({
    required this.productId,
    this.orderNumber = '',
    this.promptMessage = '',
    this.gateway,
    this.permissions,
    this.launchLiveness,
    this.writeFaceImage,
    super.key,
  });

  static const defaultPromptMessage =
      'Verify your identity to help keep your account secure and complete the '
      'process faster.';

  final String productId;
  final String orderNumber;
  final String promptMessage;
  final FaceVerificationGateway? gateway;
  final PermissionCoordinator? permissions;
  final FaceLivenessLauncher? launchLiveness;
  final FaceImageFileWriter? writeFaceImage;

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final guidance = widget.promptMessage.trim().isEmpty
        ? FaceVerificationPage.defaultPromptMessage
        : widget.promptMessage.trim();
    final onBack = CertificationRetentionGuard.backHandler(
      context: context,
      type: '1',
      productId: widget.productId,
      onDefaultBack: () => Navigator.of(context).maybePop(),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSubmitting) onBack();
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppAssets.identityUploadBackground, fit: BoxFit.cover),
            SafeArea(
              child: Column(
                children: [
                  CertificationPageHeader(
                    title: 'Face verification',
                    onBack: onBack,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: context.r(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: context.r(16),
                              top: context.r(32),
                            ),
                            child: CertificationGuidance(
                              key: const Key('faceVerificationGuidance'),
                              width: 187,
                              text: guidance,
                            ),
                          ),
                          SizedBox(height: context.r(34)),
                          Center(
                            child: Image.asset(
                              AppAssets.identityFaceExamples,
                              key: const Key('faceVerificationExamples'),
                              width: context.r(343),
                              height: context.r(404),
                              fit: BoxFit.fill,
                              semanticLabel: 'Face verification examples',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.r(16),
              0,
              context.r(16),
              context.r(22),
            ),
            child: _FaceSubmitButton(
              enabled: !_isSubmitting,
              onPressed: _submit,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reportService = context.read<ReportService?>();
    if (_isSubmitting) return;
    final session = context.read<SessionStore>();
    final gateway = widget.gateway ?? context.read<FaceVerificationGateway>();
    final flow = context.read<ProductApplicationFlow>();
    final orderNumber = widget.orderNumber.trim().isEmpty
        ? session.productDetailOrderNumber
        : widget.orderNumber.trim();
    if (orderNumber.isEmpty) {
      await EasyLoading.showError('Order information is not ready yet.');
      return;
    }

    final permissions =
        widget.permissions ?? context.read<PermissionCoordinator>();
    final permission = await permissions.requestCamera();
    if (!mounted) return;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.limited) {
      await _showPermissionDialog();
      return;
    }

    setState(() => _isSubmitting = true);
    String? faceImagePath;
    try {
      await EasyLoading.show(status: 'Loading...');
      final token = await gateway.fetchFaceLivenessToken(
        orderNumber: orderNumber,
      );
      if (token.resultCode != '200') {
        await EasyLoading.dismiss();
        if (token.errorMessage.isNotEmpty) {
          await EasyLoading.showError(token.errorMessage);
        }
        return;
      }
      if (token.license.isEmpty || token.livenessType != 7) {
        throw const _FaceVerificationFailure(
          'This liveness verification method is unavailable.',
        );
      }

      final result = await (widget.launchLiveness ?? _launchLiveness)(
        token.license,
      );
      if (reportService != null) {
        unawaited(
          reportService.reportTrustDecisionResult(
            livenessId: result.livenessId,
            requestId: '',
            resultCode: result.code,
            result: jsonEncode({
              'liveness_id': result.livenessId,
              'result_code': result.code,
              'result_message': result.message,
            }),
          ),
        );
      }
      if (!result.success) {
        throw _FaceVerificationFailure(
          result.message.isEmpty
              ? 'Face verification was not completed.'
              : result.message,
        );
      }
      if (result.image.isEmpty || result.livenessId.isEmpty) {
        throw const _FaceVerificationFailure(
          'Face verification returned incomplete data.',
        );
      }
      faceImagePath = await (widget.writeFaceImage ?? _writeFaceImage)(
        result.image,
      );
      await gateway.uploadFaceLiveness(
        filePath: faceImagePath,
        token: token,
        livenessId: result.livenessId,
      );
      RiskReportScene.report(
        reportService,
        productId: widget.productId,
        sceneType: '4',
        orderNo: widget.orderNumber,
      );
      await EasyLoading.dismiss();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, bool>(
        MaterialPageRoute<void>(
          builder: (_) => IdentityUploadContinuationPage(
            flow: flow,
            productId: widget.productId,
          ),
        ),
      );
    } on _FaceVerificationFailure catch (error) {
      await EasyLoading.showError(error.message);
    } catch (_) {
      await EasyLoading.showError('Face verification failed.');
    } finally {
      if (faceImagePath != null) {
        try {
          await File(faceImagePath).delete();
        } on FileSystemException {
          // The temporary image is best-effort cleanup after the upload.
        }
      }
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showPermissionDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Allow Camera Access'),
        content: const Text(
          "We can't complete face verification without camera access. "
          'Enable the permission to continue your application securely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}

Future<FaceLivenessResult> _launchLiveness(String license) {
  return FaceLivenessBridge.instance.start(license);
}

class _FaceVerificationFailure implements Exception {
  const _FaceVerificationFailure(this.message);

  final String message;
}

class _FaceSubmitButton extends StatelessWidget {
  const _FaceSubmitButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('faceVerificationUploadButton'),
      height: context.r(52),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(24)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.identityUploadButtonShadow,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: enabled
                ? const [
                    AppColors.identityFaceButtonStart,
                    AppColors.identityFaceButtonEnd,
                  ]
                : const [Colors.grey, Colors.grey],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(context.r(24)),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: Text(
                'Upload',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: context.r(16),
                  fontWeight: FontWeight.w700,
                  height: 19 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String> _writeFaceImage(String imageBase64) async {
  final normalized = imageBase64.contains(',')
      ? imageBase64.split(',').last
      : imageBase64;
  final bytes = base64Decode(normalized);
  final file = File(
    '${Directory.systemTemp.path}/fund_nexus_face_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
