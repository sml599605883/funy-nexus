import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/identity_selection_page.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_page.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_image_service.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_method.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('uses cached product detail guidance without another request', (
    tester,
  ) async {
    final gateway = _UploadGateway();
    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: gateway,
        child: const MaterialApp(
          home: IdentityUploadPage(
            productId: 'product-1',
            identityType: 'PRC',
            promptMessage: 'Use a clear ID photo.',
          ),
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
    expect(gateway.productDetailRequests, 0);
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
            promptMessage: shortGuidance,
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
            promptMessage: longGuidance,
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

  testWidgets('opens the camera and album upload method panel', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _UploadGateway(),
        child: const MaterialApp(
          home: IdentityUploadPage(
            productId: 'product-1',
            identityType: 'PRC',
            promptMessage: 'Use a clear ID photo.',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('identityUploadButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('identityUploadMethodPanel')), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Album'), findsOneWidget);

    await tester.tap(find.byKey(const Key('identityUploadMethodPanelClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('identityUploadMethodPanel')), findsNothing);
  });

  testWidgets('does not request photo permission for album uploads', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _UploadGateway(),
        child: MaterialApp(
          builder: EasyLoading.init(),
          home: IdentityUploadPage(
            imagePicker: _NullImagePicker(),
            productId: 'product-1',
            identityType: 'PRC',
            promptMessage: 'Use a clear ID photo.',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('identityUploadButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('identityUploadAlbum')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('identityUploadMethodPanel')), findsNothing);
  });

  testWidgets('locks the upload button while the image picker is pending', (
    tester,
  ) async {
    final picker = _BlockingImagePicker();
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _UploadGateway(),
        child: RepositoryProvider<PermissionCoordinator>.value(
          value: PermissionCoordinator(
            requestCamera: () async => PermissionStatus.granted,
          ),
          child: MaterialApp(
            builder: EasyLoading.init(),
            home: IdentityUploadPage(
              imagePicker: picker,
              productId: 'product-1',
              identityType: 'PRC',
              promptMessage: 'Use a clear ID photo.',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('identityUploadButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('identityUploadAlbum')));
    await tester.pump();

    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('identityUploadButton')),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.onTap, isNull);

    picker.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('opens upload page with selected identity type', (tester) async {
    final sessionStore = SessionStore(_MemorySessionPersistence())
      ..cacheProductDetailIdentityGuidance('Use a clear ID photo.');
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ProductGateway>.value(value: _UploadGateway()),
          RepositoryProvider<SessionStore>.value(value: sessionStore),
        ],
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
  int productDetailRequests = 0;

  @override
  Future<ProductDetailData> fetchProductDetail(String productId) async {
    productDetailRequests += 1;
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

class _NullImagePicker implements IdentityUploadImagePicker {
  @override
  Future<String?> pick(IdentityUploadMethod method) async => null;
}

class _BlockingImagePicker implements IdentityUploadImagePicker {
  final _result = Completer<String?>();

  @override
  Future<String?> pick(IdentityUploadMethod method) => _result.future;

  void complete(String? path) => _result.complete(path);
}
