import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_crypto.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/report_store.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/identity_selection_page.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_guard.dart';
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

  testWidgets('reports scene 2 from the time the selection page opens', (
    tester,
  ) async {
    final sessionStore = SessionStore(_MemorySessionPersistence());
    final reporter = _RecordingReportService(sessionStore);
    final pageOpenedAt = ReportService.nowSeconds();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ProductGateway>.value(value: _IdentityGateway()),
          RepositoryProvider<SessionStore>.value(value: sessionStore),
          RepositoryProvider<ReportService>.value(value: reporter),
        ],
        child: const MaterialApp(
          home: IdentitySelectionPage(productId: 'product-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    final selectedAt = ReportService.nowSeconds();

    await tester.tap(find.text('DRIVINGLICENSE'));

    expect(reporter.productId, 'product-1');
    expect(reporter.sceneType, '2');
    expect(reporter.startedAtSeconds, greaterThanOrEqualTo(pageOpenedAt));
    expect(reporter.startedAtSeconds, lessThan(selectedAt));
  });

  testWidgets('leaves after one retention request when no popup is returned', (
    tester,
  ) async {
    var retentionRequestCount = 0;
    CertificationRetentionGuard.presenter =
        ({
          required context,
          required type,
          required productId,
          required onExit,
        }) async {
          retentionRequestCount += 1;
          return false;
        };
    addTearDown(CertificationRetentionGuard.resetPresenter);

    await tester.pumpWidget(
      RepositoryProvider<ProductGateway>.value(
        value: _IdentityGateway(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const IdentitySelectionPage(productId: 'product-1'),
                  ),
                );
              },
              child: const Text('Open identity selection'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open identity selection'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(retentionRequestCount, 1);
    expect(find.text('Open identity selection'), findsOneWidget);
  });
}

class _RecordingReportService extends ReportService {
  _RecordingReportService(SessionStore sessionStore)
    : super(
        apiClient: _apiClient(sessionStore),
        sessionStore: sessionStore,
        apiCrypto: ApiCrypto(key: '0123456789abcdef', iv: 'abcdef9876543210'),
        store: ReportStore.memory(),
      );

  String? productId;
  String? sceneType;
  int? startedAtSeconds;

  @override
  Future<void> reportRisk({
    required String productId,
    required String sceneType,
    String orderNo = '',
    required int startTimeSeconds,
  }) async {
    this.productId = productId;
    this.sceneType = sceneType;
    startedAtSeconds = startTimeSeconds;
  }
}

ApiClient _apiClient(SessionStore sessionStore) {
  final config = AppConfig(
    environment: AppEnvironment.development,
    baseUrl: Uri.parse('https://api.example.com'),
    webBaseUrl: Uri.parse('https://web.example.com'),
    signingSecret: 'test-secret',
    encryptionKey: '0123456789abcdef',
    encryptionIv: 'abcdef9876543210',
  );
  return ApiClient(
    dio: Dio(),
    signature: ApiSignature(
      config: config,
      sessionStore: sessionStore,
      publicParamsProvider: const StaticApiPublicParamsProvider(
        ApiPublicParams(
          appVersion: '2.4.1',
          deviceCode: 'iPhone17,1',
          deviceName: 'iPhone Test',
          deviceId: 'idfv-test',
          osVersion: '18.0',
          gpsAdId: 'idfv-test',
        ),
      ),
    ),
  );
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

class _MemorySessionPersistence implements SessionPersistence {
  @override
  Future<String?> readPhone() async => null;

  @override
  Future<String?> readSessionId() async => null;

  @override
  Future<void> writePhone(String? value) async {}

  @override
  Future<void> writeSessionId(String? value) async {}
}
