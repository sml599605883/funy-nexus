import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_crypto.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/core/report/report_native_bridge.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/report_store.dart';
import 'package:fund_nexus/core/session/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'requests notification authorization before APNs registration',
    () async {
      final calls = <String>[];
      final notificationPermission = Completer<void>();
      final sessionStore = SessionStore(_MemorySessionPersistence());
      final client = _client(sessionStore, (_) => _successResponse());
      final store = ReportStore.memory();
      await store.markAppOpened();
      addTearDown(client.close);

      final channel = MethodChannel('test/notification_report_bridge');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'requestNotificationPermission') {
              await notificationPermission.future;
            }
            if (call.method == 'getTrackingStatus') return 'authorized';
            if (call.method == 'getDeviceSnapshot') return <String, Object?>{};
            if (call.method == 'getPushToken') return '';
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final service = ReportService(
        apiClient: client,
        sessionStore: sessionStore,
        apiCrypto: ApiCrypto(key: '0123456789abcdef', iv: 'abcdef9876543210'),
        store: store,
        native: ReportNativeBridge(channel: channel),
      );

      final started = service.start();
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['requestNotificationPermission']);

      notificationPermission.complete();
      await started;
      await Future<void>.delayed(Duration.zero);
      expect(calls, contains('registerForRemoteNotifications'));
      expect(
        calls.indexOf('requestNotificationPermission'),
        lessThan(calls.indexOf('registerForRemoteNotifications')),
      );
    },
  );

  test('reports scene 1 with the time captured when login opens', () async {
    final riskReported = Completer<RequestOptions>();
    final sessionStore = SessionStore(_MemorySessionPersistence());
    final client = _client(sessionStore, (request) {
      if (request.path == '/viler/bravenesses') {
        riskReported.complete(request);
      }
      return _successResponse();
    });
    addTearDown(client.close);

    final channel = MethodChannel('test/report_bridge');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getDeviceSnapshot') {
            return {'riskDeviceId': 'risk-device', 'idfa': 'idfa'};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final service = ReportService(
      apiClient: client,
      sessionStore: sessionStore,
      apiCrypto: ApiCrypto(key: '0123456789abcdef', iv: 'abcdef9876543210'),
      store: ReportStore.memory(),
      native: ReportNativeBridge(channel: channel),
      nowMillis: () => 1_720_000_222_000,
    );

    await service.loginSucceeded(riskStartedAtSeconds: 1_720_000_000);
    final request = await riskReported.future.timeout(
      const Duration(seconds: 1),
    );

    expect(request.data['pesters'], isEmpty);
    expect(request.data['verbifies'], '1');
    expect(request.data['dingbat'], '1720000000');
    expect(request.data['mammocks'], '1720000222');
  });
}

ApiClient _client(
  SessionStore sessionStore,
  ResponseBody Function(RequestOptions request) response,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _StubAdapter(response);
  final config = AppConfig(
    environment: AppEnvironment.development,
    baseUrl: Uri.parse('https://api.example.com'),
    webBaseUrl: Uri.parse('https://web.example.com'),
    signingSecret: 'test-secret',
    encryptionKey: '0123456789abcdef',
    encryptionIv: 'abcdef9876543210',
  );
  return ApiClient(
    dio: dio,
    signature: ApiSignature(
      config: config,
      sessionStore: sessionStore,
      publicParamsProvider: const StaticApiPublicParamsProvider(
        ApiPublicParams(
          appVersion: '2.4.1',
          deviceCode: 'iPhone17,1',
          deviceName: 'iPhone Test',
          deviceId: 'idfv-123',
          osVersion: '18.0',
          gpsAdId: 'idfv-123',
        ),
      ),
      timestampProvider: () => 1_700_000_000_000,
      randomDigitsProvider: (_) => '123456',
    ),
  );
}

ResponseBody _successResponse() => ResponseBody.fromString(
  jsonEncode({'fasciitis': 0, 'bravo': 'success', 'foresight': null}),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._response);

  final ResponseBody Function(RequestOptions request) _response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => _response(options);

  @override
  void close({bool force = false}) {}
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
