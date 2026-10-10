import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/face/face_liveness_bridge.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/certification/face_verification_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../support/product_gateway_fakes.dart';

void main() {
  testWidgets('uses cached product face guidance in the face handoff', (
    tester,
  ) async {
    final session = SessionStore(_MemorySessionPersistence())
      ..cacheProductDetailCertification(
        identityGuidance: 'Upload your ID.',
        faceGuidance: 'Keep your face clearly within the frame.',
        orderNumber: 'ORDER-42',
      );
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<SessionStore>.value(
        value: session,
        child: const MaterialApp(
          home: CertificationHandoffPage(productId: 'product-1', step: 'face'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FaceVerificationPage), findsOneWidget);
    expect(
      find.text('Keep your face clearly within the frame.'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('faceVerificationGuidance'))),
      const Size(187, 57),
    );
    expect(find.byKey(const Key('faceVerificationExamples')), findsOneWidget);
  });

  testWidgets('uploads face image when liveness data is present', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = SessionStore(_MemorySessionPersistence())
      ..cacheProductDetailCertification(
        identityGuidance: '',
        faceGuidance: '',
        orderNumber: 'ORDER-42',
      );
    final gateway = _FakeFaceGateway();

    await tester.pumpWidget(
      RepositoryProvider<SessionStore>.value(
        value: session,
        child: RepositoryProvider<ProductApplicationFlow>.value(
          value: _SilentFlow(session),
          child: MaterialApp(
            builder: EasyLoading.init(),
            home: FaceVerificationPage(
              productId: 'product-1',
              gateway: gateway,
              permissions: PermissionCoordinator(
                requestCamera: () async => PermissionStatus.granted,
              ),
              launchLiveness: (_) async => const FaceLivenessResult(
                success: false,
                code: 3001,
                message: 'completed',
                image: 'base64-image',
                livenessId: 'liveness-42',
              ),
              writeFaceImage: (_) async => '/tmp/fund_nexus_face_test.jpg',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('faceVerificationUploadButton')));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(gateway.uploads, ['liveness-42']);
  });
}

class _FakeFaceGateway implements FaceVerificationGateway {
  final List<String> uploads = <String>[];

  @override
  Future<FaceLivenessToken> fetchFaceLivenessToken({
    required String orderNumber,
    String type = '0',
  }) async => const FaceLivenessToken(
    resultCode: '200',
    license: 'license-42',
    errorMessage: '',
    livenessType: 7,
  );

  @override
  Future<void> uploadFaceLiveness({
    required String filePath,
    required FaceLivenessToken token,
    required String livenessId,
  }) async {
    uploads.add(livenessId);
  }
}

class _SilentFlow extends ProductApplicationFlow {
  _SilentFlow(SessionStore session)
    : super(
        repository: StubProductGateway(),
        sessionStore: session,
        permissions: PermissionCoordinator(
          requestCamera: () async => PermissionStatus.granted,
        ),
      );

  @override
  Future<void> resumeAfterCertification({
    required String productId,
    required ProductTargetAction openTarget,
    required ProductStepAction openCertification,
    required ProductLoadingAction showLoading,
    required ProductLoadingAction dismissLoading,
    required ProductMessageAction showMessage,
  }) async {}
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
