import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/certification/face_verification_page.dart';

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
