import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/mine/account_session_coordinator.dart';

void main() {
  test('clears the session only after logout succeeds', () async {
    final persistence = _MemorySessionPersistence();
    final sessionStore = SessionStore(persistence);
    await sessionStore.save(phone: '09171234567', sessionId: 'session-token');
    late RequestOptions request;
    final client = _client((options) {
      request = options;
      return _response(0);
    }, sessionStore);
    addTearDown(client.close);

    await AccountSessionCoordinator(
      apiClient: client,
      sessionStore: sessionStore,
    ).execute(AccountExitAction.logOut);

    expect(request.path, '/viler/fasciitis');
    expect(sessionStore.sessionId, isNull);
    expect(sessionStore.phone, '09171234567');
  });

  test('retains the session when account deletion is rejected', () async {
    final persistence = _MemorySessionPersistence();
    final sessionStore = SessionStore(persistence);
    await sessionStore.save(phone: '09171234567', sessionId: 'session-token');
    final client = _client((_) => _response(400), sessionStore);
    addTearDown(client.close);

    await expectLater(
      AccountSessionCoordinator(
        apiClient: client,
        sessionStore: sessionStore,
      ).execute(AccountExitAction.deleteAccount),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiFailureType.business,
        ),
      ),
    );

    expect(sessionStore.sessionId, 'session-token');
    expect(sessionStore.phone, '09171234567');
  });
}

ApiClient _client(
  ResponseBody Function(RequestOptions request) response,
  SessionStore sessionStore,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _StubAdapter(response);
  return ApiClient(
    dio: dio,
    signature: ApiSignature(
      config: AppConfig(
        environment: AppEnvironment.development,
        baseUrl: Uri.parse('https://api.example.com'),
        webBaseUrl: Uri.parse('https://web.example.com'),
        signingSecret: 'test-secret',
        encryptionKey: '0123456789abcdef',
        encryptionIv: 'abcdef9876543210',
      ),
      sessionStore: sessionStore,
      publicParamsProvider: const StaticApiPublicParamsProvider(
        ApiPublicParams(
          appVersion: '1.0.0',
          deviceCode: 'iPhone17,1',
          deviceName: 'iPhone Test',
          deviceId: 'device-id',
          osVersion: '18.0',
          gpsAdId: 'device-id',
        ),
      ),
    ),
  );
}

ResponseBody _response(int code) {
  return ResponseBody.fromString(
    jsonEncode({
      'fasciitis': code,
      'bravo': code == 0 ? 'success' : 'rejected',
      'foresight': const {},
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.response);

  final ResponseBody Function(RequestOptions request) response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => response(options);

  @override
  void close({bool force = false}) {}
}

class _MemorySessionPersistence implements SessionPersistence {
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
