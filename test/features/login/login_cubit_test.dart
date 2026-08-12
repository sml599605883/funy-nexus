import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/login/state/login_cubit.dart';

void main() {
  test('requires agreement before submitting and preserves the code', () async {
    var requestCount = 0;
    final messages = <String>[];
    final cubit = LoginCubit(
      apiClient: _client((_) {
        requestCount++;
        return _response({
          'commenting': 1,
          'invital': 0,
          'resite': '09171234567',
          'argots': '',
          'coccolith': 'session',
        });
      }),
      sessionStore: SessionStore(_MemoryPersistence()),
      showMessage: (message) async => messages.add(message),
      onLoginSuccess: () async {},
    );
    addTearDown(cubit.close);

    cubit.toggleAgreement();

    final submitted = await cubit.submitSmsCode(
      phone: '09171234567',
      code: '123456',
    );

    expect(submitted, isFalse);
    expect(requestCount, 0);
    expect(messages, [
      'Please agree to the Privacy Policy and Terms of Service',
    ]);
  });

  test('sends code, counts down, and persists coccolith after login', () async {
    final messages = <String>[];
    var loginSuccessCount = 0;
    final persistence = _MemoryPersistence();
    final client = _client((request) {
      if (request.path == '/viler/ethanols') return _response(null);
      return _response({
        'commenting': 1,
        'invital': 0,
        'resite': '09171234567',
        'argots': '',
        'coccolith': 'session-login',
      });
    });
    final cubit = LoginCubit(
      apiClient: client,
      sessionStore: SessionStore(persistence),
      showMessage: (message) async => messages.add(message),
      onLoginSuccess: () async => loginSuccessCount++,
      countdownInterval: const Duration(milliseconds: 10),
    );
    addTearDown(() async {
      await cubit.close();
      client.close();
    });
    expect(await cubit.requestSmsCode('09171234567'), isTrue);
    expect(cubit.state.countdownSeconds, 60);
    expect(
      await cubit.submitSmsCode(phone: '09171234567', code: '123456'),
      isTrue,
    );
    expect(persistence.sessionId, 'session-login');
    expect(persistence.phone, '09171234567');
    expect(loginSuccessCount, 1);
    expect(messages, ['success']);
  });
}

ApiClient _client(ResponseBody Function(RequestOptions) response) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter(response);
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
      sessionStore: SessionStore(_MemoryPersistence()),
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

ResponseBody _response(Object? data) => ResponseBody.fromString(
  jsonEncode({'fasciitis': 0, 'bravo': 'success', 'foresight': data}),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.response);
  final ResponseBody Function(RequestOptions) response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => response(options);

  @override
  void close({bool force = false}) {}
}

class _MemoryPersistence implements SessionPersistence {
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
