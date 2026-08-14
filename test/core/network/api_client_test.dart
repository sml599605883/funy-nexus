import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/device/device_name_data.dart';
import 'package:fund_nexus/core/json/json.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/network/api_protocol.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/home/data/home_repository.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

void main() {
  late _MemorySessionPersistence persistence;
  late SessionStore sessionStore;

  setUp(() {
    persistence = _MemorySessionPersistence();
    sessionStore = SessionStore(persistence);
  });

  test('decodes Fund Nexus response and adds signed public params', () async {
    await sessionStore.save(phone: '09171234567', sessionId: 'session-123');
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _jsonResponse({
        'fasciitis': 0,
        'bravo': 'success',
        'foresight': {'name': 'Fund Nexus'},
      });
    });
    addTearDown(client.close);

    final response = await client.get<String>(
      '/viler/profile',
      queryParameters: const {'page': 1},
      decode: (data) => (data as Map<String, Object?>)['name']! as String,
    );

    expect(response.data, 'Fund Nexus');
    expect(response.message, 'success');
    expect(
      capturedRequest.queryParameters,
      containsPair('pathbreaking', '2.4.1'),
    );
    expect(capturedRequest.queryParameters['nutlike'], 'iPhone Test');
    expect(capturedRequest.queryParameters['cockatoos'], 'idfv-123');
    expect(capturedRequest.queryParameters['advocation'], '18.0');
    expect(
      capturedRequest.queryParameters['semipious'],
      'appstore-ph-fund-nexus-ios',
    );
    expect(capturedRequest.queryParameters['coccolith'], 'session-123');
    expect(capturedRequest.queryParameters['reformer'], 'idfv-123');
    expect(capturedRequest.queryParameters['antipoles'], '1700000000000');
    expect(capturedRequest.queryParameters['choppiest'], '123456');
    expect(capturedRequest.queryParameters['page'], 1);
    expect(capturedRequest.queryParameters['hoods'], hasLength(64));
  });

  test(
    'parses the documented device-name response code as an integer',
    () async {
      final client = _client(
        sessionStore,
        (_) => _jsonResponse({
          'fasciitis': '00',
          'bravo': 'success',
          'foresight': {'V31enQ': 'sN', 'nutlike': 'iPhoneXR', 'gumdrop': 6.1},
        }),
      );
      addTearDown(client.close);

      final response = await client.post<DeviceNameData>(
        '/viler/resite',
        data: const {'emit': 'iPhone11,8'},
        decode: (data) => DeviceNameData.fromJson(Json(data)),
      );

      expect(response.data.deviceName, 'iPhoneXR');
      expect(response.data.screenSize, 6.1);
    },
  );

  test('sends an empty coccolith while logged out', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse(null);
    });
    addTearDown(client.close);

    await client.get<void>('/viler/public', decode: (_) {});

    expect(capturedRequest.queryParameters['coccolith'], '');
  });

  test('uses form encoding for regular POST requests', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse(null);
    });
    addTearDown(client.close);

    await client.post<void>(
      '/viler/triazine',
      data: const {'resite': '855123456', 'pelvis': '123456'},
      decode: (_) {},
    );

    expect(capturedRequest.contentType, Headers.formUrlEncodedContentType);
  });

  test('uses the documented Fund Nexus home request contract', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse({
        'chippered': null,
        'semihobos': [
          {
            'etherifying': 'Majordomo',
            'mycetozoan': [
              {'apparentness': '₱60,000'},
            ],
          },
        ],
      });
    });
    addTearDown(client.close);

    final data = await HomeRepository(apiClient: client).fetchHome();

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.path, '/viler/foresight');
    expect(capturedRequest.queryParameters['ever'], hasLength(6));
    expect(capturedRequest.queryParameters['rarefiers'], hasLength(6));
    expect(data.primaryCard?.amount, '₱60,000');
  });

  test(
    'uses documented Fund Nexus product admission and detail contracts',
    () async {
      final requests = <RequestOptions>[];
      final client = _client(sessionStore, (request) {
        requests.add(request);
        return switch (request.path) {
          '/viler/pelvis' => _successResponse({
            'trokes': 200,
            'redepositing': '',
            'hygieists': '',
          }),
          '/viler/commenting' => _successResponse({
            'trokes': 200,
            'supramolecular': const {},
            'metheglins': const {},
          }),
          _ => _successResponse({'redepositing': 'https://web.example.com'}),
        };
      });
      addTearDown(client.close);
      final repository = ProductRepository(apiClient: client);

      await repository.requestAdmission('product-1');
      await repository.fetchProductDetail('product-1');
      await repository.fetchIdentityOptions('product-1');
      await repository.fetchCreditReview();
      await repository.fetchLoanDestination(
        orderNumber: 'ORDER-1',
        amount: '1000.00',
        loanTerm: '7',
        termType: '1',
      );

      expect(requests[0].path, '/viler/pelvis');
      expect(requests[0].data, {
        'metageneses': '1001',
        'servitude': '1000',
        'explantation': '1000',
        'modernised': 'product-1',
        'nonpermissive': '0',
        'disaggregate': hasLength(6),
        'coccyx': hasLength(6),
      });
      expect(requests[1].path, '/viler/commenting');
      expect(requests[1].data, {
        'modernised': 'product-1',
        'xerophily': hasLength(6),
        'tragedienne': hasLength(6),
        'impowering': hasLength(6),
      });
      expect(requests[2].method, 'GET');
      expect(requests[2].path, '/viler/invital');
      expect(requests[2].queryParameters['modernised'], 'product-1');
      expect(requests[2].queryParameters['pacification'], hasLength(6));
      expect(requests[3].method, 'GET');
      expect(requests[3].path, '/viler/pepperboxes');
      expect(requests[3].queryParameters['underheat'], hasLength(6));
      expect(requests[4].path, '/viler/remediation');
      expect(requests[4].data, {
        'clipsheet': 'ORDER-1',
        'breaststrokers': '1000.00',
        'germicides': '7',
        'nominees': '1',
        'substantive': hasLength(6),
        'inquiry': hasLength(6),
        'shocker': hasLength(6),
        'parbake': hasLength(6),
      });
    },
  );

  test('uses the documented Fund Nexus login request contracts', () async {
    final requests = <RequestOptions>[];
    final client = _client(sessionStore, (request) {
      requests.add(request);
      if (request.path == '/viler/triazine') {
        return _successResponse({
          'commenting': 1,
          'invital': 0,
          'resite': '09171234567',
          'argots': '',
          'coccolith': 'session-login',
        });
      }
      return _successResponse(null);
    });
    addTearDown(client.close);

    await client.sendLoginSmsCode(phone: '09171234567');
    final login = await client.loginWithSmsCode(
      phone: '09171234567',
      code: '123456',
    );

    expect(requests[0].path, '/viler/ethanols');
    expect(requests[0].data, containsPair('ethanols', '09171234567'));
    expect(requests[0].data, containsPair('triazine', 'sms'));
    expect(requests[0].data, containsPair('consular', isA<String>()));
    expect(requests[1].path, '/viler/triazine');
    expect(requests[1].data, containsPair('resite', '09171234567'));
    expect(requests[1].data, containsPair('pelvis', '123456'));
    expect(requests[1].data, containsPair('transistorizes', isA<String>()));
    expect(requests[1].data, containsPair('martlet', isA<String>()));
    expect(login.data.commenting, 1);
    expect(login.data.invital, 0);
    expect(login.data.resite, '09171234567');
    expect(login.data.argots, '');
    expect(login.data.coccolith, 'session-login');
  });

  test('uses the documented account exit request contracts', () async {
    final requests = <RequestOptions>[];
    final client = _client(sessionStore, (request) {
      requests.add(request);
      return _successResponse(const {});
    });
    addTearDown(client.close);

    await client.logout();
    await client.deleteAccount();

    expect(requests[0].method, 'GET');
    expect(requests[0].path, '/viler/fasciitis');
    expect(requests[0].queryParameters['contrasts'], hasLength(6));
    expect(requests[0].queryParameters['irenically'], hasLength(6));
    expect(requests[1].method, 'GET');
    expect(requests[1].path, '/viler/bravo');
    expect(requests[1].queryParameters['cormous'], hasLength(6));
  });

  test(
    'rejects login data that does not match the documented fields',
    () async {
      final client = _client(
        sessionStore,
        (_) => _successResponse({
          'commenting': 1,
          'invital': 0,
          'resite': '09171234567',
          'argots': '',
        }),
      );
      addTearDown(client.close);

      await expectLater(
        client.loginWithSmsCode(phone: '09171234567', code: '123456'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiFailureType.invalidResponse,
          ),
        ),
      );
    },
  );

  test('rejects login data with undocumented field types', () async {
    final client = _client(
      sessionStore,
      (_) => _successResponse({
        'commenting': '1',
        'invital': 0,
        'resite': '09171234567',
        'argots': '',
        'coccolith': 'session-login',
      }),
    );
    addTearDown(client.close);

    await expectLater(
      client.loginWithSmsCode(phone: '09171234567', code: '123456'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiFailureType.invalidResponse,
        ),
      ),
    );
  });

  test('converts Fund Nexus business rejection to a typed exception', () async {
    final client = _client(
      sessionStore,
      (_) => _jsonResponse({
        'fasciitis': 400,
        'bravo': 'Signature validation failed',
        'foresight': null,
      }),
    );
    addTearDown(client.close);

    await expectLater(
      client.get<void>('/viler/profile', decode: (_) {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.type, 'type', ApiFailureType.business)
            .having((error) => error.code, 'code', '400'),
      ),
    );
  });

  test('maps documented -2 response to authentication failure', () async {
    final client = _client(
      sessionStore,
      (_) => _jsonResponse({
        'fasciitis': -2,
        'bravo': 'Please log in again',
        'foresight': null,
      }),
    );
    addTearDown(client.close);

    await expectLater(
      client.get<void>('/viler/profile', decode: (_) {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiFailureType.authentication,
        ),
      ),
    );
  });

  test('supports an explicitly overridden response contract', () async {
    const protocol = ApiProtocol(
      codeKey: 'status',
      messageKey: 'detail',
      dataKey: 'payload',
      successCodes: {'OK'},
    );
    final client = _client(
      sessionStore,
      (_) =>
          _jsonResponse({'status': 'OK', 'detail': 'accepted', 'payload': 42}),
      protocol: protocol,
    );
    addTearDown(client.close);

    final response = await client.get<int>(
      '/viler/value',
      decode: (data) => data! as int,
    );

    expect(response.data, 42);
  });

  test('rejects malformed response envelopes', () async {
    final client = _client(
      sessionStore,
      (_) => _jsonResponse({'bravo': 'missing code', 'foresight': null}),
    );
    addTearDown(client.close);

    await expectLater(
      client.get<void>('/viler/profile', decode: (_) {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiFailureType.invalidResponse,
        ),
      ),
    );
  });

  test('does not send unsigned requests', () async {
    var requestCount = 0;
    final client = _client(sessionStore, (_) {
      requestCount++;
      return _successResponse(null);
    }, signingSecret: '');
    addTearDown(client.close);

    await expectLater(
      client.get<void>('/viler/profile', decode: (_) {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiFailureType.configuration,
        ),
      ),
    );
    expect(requestCount, 0);
  });

  test('does not allow business query to override public params', () async {
    var requestCount = 0;
    final client = _client(sessionStore, (_) {
      requestCount++;
      return _successResponse(null);
    });
    addTearDown(client.close);

    await expectLater(
      client.get<void>(
        '/viler/profile',
        queryParameters: const {'coccolith': 'override'},
        decode: (_) {},
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiFailureType.configuration,
        ),
      ),
    );
    expect(requestCount, 0);
  });

  test('maps timeout and connection failures', () async {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.transformTimeout,
      DioExceptionType.connectionError,
    ]) {
      final client = _client(
        sessionStore,
        (request) => throw DioException(requestOptions: request, type: type),
      );
      addTearDown(client.close);

      await expectLater(
        client.get<void>('/viler/profile', decode: (_) {}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            type == DioExceptionType.connectionTimeout ||
                    type == DioExceptionType.transformTimeout
                ? ApiFailureType.timeout
                : ApiFailureType.noConnection,
          ),
        ),
      );
    }
  });

  test('treats every HTTP response as reachable transport', () async {
    final client = _client(
      sessionStore,
      (_) => _jsonResponse('maintenance', statusCode: 503),
    );
    addTearDown(client.close);

    expect(await client.probeTransport(), isTrue);
  });

  test(
    'treats a transport error without an HTTP response as unavailable',
    () async {
      final client = _client(
        sessionStore,
        (request) => throw DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        ),
      );
      addTearDown(client.close);

      expect(await client.probeTransport(), isFalse);
    },
  );

  test('supports cancelling a request before transport', () async {
    final client = _client(sessionStore, (_) => _successResponse(null));
    addTearDown(client.close);
    final cancelToken = CancelToken()..cancel('page disposed');

    await expectLater(
      client.get<void>(
        '/viler/profile',
        cancelToken: cancelToken,
        decode: (_) {},
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiFailureType.cancelled,
        ),
      ),
    );
  });

  test('maps non-success HTTP status', () async {
    final client = _client(
      sessionStore,
      (_) => _jsonResponse({'bravo': 'unavailable'}, statusCode: 503),
    );
    addTearDown(client.close);

    await expectLater(
      client.get<void>('/viler/profile', decode: (_) {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.type, 'type', ApiFailureType.http)
            .having((error) => error.statusCode, 'statusCode', 503),
      ),
    );
  });
}

ApiClient _client(
  SessionStore sessionStore,
  ResponseBody Function(RequestOptions request) response, {
  ApiProtocol protocol = const ApiProtocol(),
  String signingSecret = 'test-secret',
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _StubAdapter(response);
  final config = AppConfig(
    environment: AppEnvironment.development,
    baseUrl: Uri.parse('https://api.example.com'),
    webBaseUrl: Uri.parse('https://web.example.com'),
    signingSecret: signingSecret,
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
      timestampProvider: () => 1700000000000,
      randomDigitsProvider: (_) => '123456',
    ),
    protocol: protocol,
  );
}

ResponseBody _successResponse(Object? data) {
  return _jsonResponse({'fasciitis': 0, 'bravo': 'success', 'foresight': data});
}

ResponseBody _jsonResponse(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._response);

  final ResponseBody Function(RequestOptions request) _response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _response(options);
  }

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
