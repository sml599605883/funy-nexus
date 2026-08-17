import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/features/product/certification/identity_confirmation_page.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_image_service.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_continuation.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_method.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/certification/widgets/identity_upload_method_panel.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:permission_handler/permission_handler.dart';

class IdentityUploadPage extends StatefulWidget {
  const IdentityUploadPage({
    required this.productId,
    required this.identityType,
    this.imagePicker,
    this.imageCompressor,
    this.permissions,
    this.gateway,
    this.promptMessage = '',
    super.key,
  });

  final String productId;
  final String identityType;
  final IdentityUploadImagePicker? imagePicker;
  final IdentityUploadImageCompressor? imageCompressor;
  final PermissionCoordinator? permissions;
  final ProductGateway? gateway;
  final String promptMessage;

  @override
  State<IdentityUploadPage> createState() => _IdentityUploadPageState();
}

class _IdentityUploadPageState extends State<IdentityUploadPage> {
  bool _isUploading = false;

  late final IdentityUploadImagePicker _imagePicker =
      widget.imagePicker ?? DefaultIdentityUploadImagePicker();
  late final IdentityUploadImageCompressor _imageCompressor =
      widget.imageCompressor ?? DefaultIdentityUploadImageCompressor();

  @override
  Widget build(BuildContext context) {
    final guidance = widget.promptMessage.trim();
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.identityUploadBackground, fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                CertificationPageHeader(
                  title: 'ID Verification',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: context.r(16)),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: context.r(16),
                            top: context.r(32),
                            right: context.r(172),
                          ),
                          child: CertificationGuidance(
                            key: const Key('identityUploadGuidance'),
                            text: guidance,
                          ),
                        ),
                        SizedBox(height: context.r(31)),
                        Image.asset(
                          AppAssets.identityUploadExamples,
                          key: const Key('identityUploadDemo'),
                          width: context.r(343),
                          height: context.r(420),
                          fit: BoxFit.fill,
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
          child: _UploadButton(
            enabled: !_isUploading,
            onPressed: _showUploadMethodSheet,
          ),
        ),
      ),
    );
  }

  Future<void> _continueAfterIdentity(String productId) async {
    if (!mounted) return;
    final flow = context.read<ProductApplicationFlow>();
    await Navigator.of(context).pushReplacement<void, bool>(
      MaterialPageRoute<void>(
        builder: (context) =>
            IdentityUploadContinuationPage(flow: flow, productId: productId),
      ),
    );
  }

  Future<void> _showUploadMethodSheet() async {
    if (_isUploading) return;
    final method = await showIdentityUploadMethodPanel(context);
    if (method == null || !mounted) return;

    if (method == IdentityUploadMethod.camera) {
      final permission =
          widget.permissions ?? context.read<PermissionCoordinator>();
      final status = await permission.requestCamera();
      if (!mounted) return;
      if (status != PermissionStatus.granted &&
          status != PermissionStatus.limited) {
        await _showPermissionDialog();
        return;
      }
    }

    setState(() => _isUploading = true);
    await EasyLoading.show(status: 'Loading...');
    final String? path;
    try {
      path = await _imagePicker.pick(method);
    } catch (_) {
      await EasyLoading.dismiss();
      if (mounted) {
        await EasyLoading.showError('Unable to select the identity image.');
        setState(() => _isUploading = false);
      }
      return;
    }
    if (path == null || path.isEmpty || !mounted) {
      await EasyLoading.dismiss();
      if (mounted) setState(() => _isUploading = false);
      return;
    }
    await _upload(path, method, loadingAlreadyShown: true);
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Allow Camera Access'),
        content: const Text(
          "We can't complete identity verification without camera access. "
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

  Future<void> _upload(
    String sourcePath,
    IdentityUploadMethod method, {
    bool loadingAlreadyShown = false,
  }) async {
    if (_isUploading && !loadingAlreadyShown) return;
    final gateway = widget.gateway ?? context.read<ProductGateway>();
    if (!loadingAlreadyShown) {
      setState(() => _isUploading = true);
      await EasyLoading.show(status: 'Loading...');
    }
    try {
      final compressedPath = await _imageCompressor.compressToLimit(sourcePath);
      if (compressedPath == null || compressedPath.isEmpty) {
        throw StateError('Image compression failed');
      }
      final result = await gateway.uploadIdentityDocument(
        filePath: compressedPath,
        identityType: widget.identityType,
        wasCapturedWithCamera: method == IdentityUploadMethod.camera,
      );
      await EasyLoading.dismiss();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => IdentityConfirmationPage(
            productId: widget.productId,
            identityType: widget.identityType,
            recognizedInfo: result,
            promptMessage: widget.promptMessage.trim(),
            onSaved: () => _continueAfterIdentity(widget.productId),
          ),
        ),
      );
    } catch (error) {
      await EasyLoading.showError(
        error is StateError ? error.message : 'Upload failed',
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.onPressed, required this.enabled});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('identityUploadButton'),
      width: double.infinity,
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
                    AppColors.homeApplyButtonStart,
                    AppColors.homeApplyButtonEnd,
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
