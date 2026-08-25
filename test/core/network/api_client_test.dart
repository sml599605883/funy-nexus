import 'dart:convert';
import 'dart:io';
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
import 'package:fund_nexus/features/product/data/bind_card_data.dart';
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

  test('posts the documented Fund Nexus order-list contract', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse(const {'semihobos': <dynamic>[]});
    });
    addTearDown(client.close);

    final response = await client.fetchOrderList(status: '6');

    expect(response.data['semihobos'].listValue, isEmpty);
    expect(capturedRequest.path, endsWith('/viler/pharmacognosy'));
    expect(capturedRequest.data, {
      'narthex': '6',
      'eclipser': '1',
      'immolates': '50',
    });
  });

  test('gets the documented Home/Mine popup contract', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse({
        'etherifying': 3,
        'leapt': {'zymometer': 'https://cdn.example.test/popup.png'},
      });
    });
    addTearDown(client.close);

    final response = await client.fetchPopup(scene: 2);

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.path, '/viler/aurochses');
    expect(capturedRequest.queryParameters['unfriended'], 2);
    expect(response.data['etherifying'].numValue.toInt(), 3);
    expect(
      response.data['leapt']['zymometer'].stringValue,
      'https://cdn.example.test/popup.png',
    );
  });

  test('posts the documented progress retry contract', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse(const {
        'topical': 'https://web.example.com/retry',
      });
    });
    addTearDown(client.close);

    final response = await client.retryProgressOrder(orderNumber: ' ORDER-1 ');

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.path, '/viler/clipsheet');
    expect(capturedRequest.data, {'readjusts': 'ORDER-1'});
    expect(
      response.data['topical'].stringValue,
      'https://web.example.com/retry',
    );
  });

  test('posts the documented progress account-list contract', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse(const {
        'semihobos': [
          {'hoover': '5326'},
        ],
      });
    });
    addTearDown(client.close);

    final response = await client.fetchProgressAccounts(
      productId: ' product-1 ',
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.path, '/viler/ritualize');
    expect(capturedRequest.data, {
      'modernised': 'product-1',
      'occident': hasLength(6),
      'sloe': hasLength(6),
    });
    expect(response.data['semihobos'].listValue, hasLength(1));
  });

  test('posts the documented account-change contract', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse(const {
        'topical': 'https://web.example.com/changed',
      });
    });
    addTearDown(client.close);

    final response = await client.changeProgressAccount(
      orderNumber: ' ORDER-1 ',
      bindId: ' bind-42 ',
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.path, '/viler/typographies');
    expect(capturedRequest.data, {
      'clipsheet': 'ORDER-1',
      'overadvertises': 'bind-42',
      'ohing': hasLength(6),
    });
    expect(
      response.data['topical'].stringValue,
      'https://web.example.com/changed',
    );
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

  test(
    'builds H5 public parameters only for the configured API target',
    () async {
      final client = _client(sessionStore, (_) => _successResponse(null));
      addTearDown(client.close);

      final relative = await client.buildSignedQuery(path: '/viler/public');
      final sameApi = await client.buildSignedQuery(
        path: 'https://api.example.com/viler/public?source=h5',
      );

      expect(relative['hoods'], hasLength(64));
      expect(sameApi['hoods'], hasLength(64));
      await expectLater(
        client.buildSignedQuery(path: 'https://untrusted.example/viler/public'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiFailureType.configuration,
          ),
        ),
      );
      await expectLater(
        client.buildSignedQuery(path: '//untrusted.example/viler/public'),
        throwsA(isA<ApiException>()),
      );
    },
  );

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
            'etherifying': 'Nonsteroidal',
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

  test('uses the documented certification retention popup contract', () async {
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse({
        'leapt': {
          'redepositing': 'https://image.example.com/retention.png',
          'scall': 'Continue',
          'slipperinesses': 'Exit',
        },
      });
    });
    addTearDown(client.close);

    final response = await client.fetchCertificationRetention(
      type: ' 2 ',
      productId: ' product-1 ',
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.path, '/viler/soreness');
    expect(capturedRequest.data, {
      'bobberies': '2',
      'pesters': 'product-1',
      'brink': hasLength(6),
    });
    expect(
      Json(response.data)['leapt']['redepositing'].stringValue,
      'https://image.example.com/retention.png',
    );
  });

  test(
    'uses the documented Fund Nexus personal-information contracts',
    () async {
      final requests = <RequestOptions>[];
      final client = _client(sessionStore, (request) {
        requests.add(request);
        if (request.path == '/viler/chippered') {
          return _successResponse({
            'cornbraids': 'Complete your personal information.',
            'orographical': [
              {
                'culinarians': 'Education',
                'must': 'Please select education',
                'fasciitis': 'education',
                'presentableness': 'enum',
                'bobberies': 0,
                'rubicund': [
                  {'emit': 'College', 'etherifying': 2},
                ],
                'lambadas': 0,
                'steeplechases': 'College',
              },
            ],
          });
        }
        if (request.path == '/viler/closets') {
          return _successResponse({
            'semihobos': [
              {'fasciitis': '1', 'emit': 'Region', 'bedtimes': const []},
            ],
          });
        }
        return _successResponse({});
      });
      addTearDown(client.close);
      final repository = ProductRepository(apiClient: client);

      final data = await repository.fetchPersonalInformation('product-42');
      final addresses = await repository.fetchPersonalInformationAddresses();
      await repository.savePersonalInformation(
        productId: 'product-42',
        fields: const {'education': '2', 'complete_address': 'Manila'},
      );

      expect(data.fields.single.saveKey, 'education');
      expect(data.fields.single.initialSubmitValue, '2');
      expect(addresses.single.label, 'Region');
      expect(requests[0].path, '/viler/chippered');
      expect(requests[0].data, {
        'modernised': 'product-42',
        'movieola': hasLength(6),
      });
      expect(requests[1].method, 'GET');
      expect(requests[1].path, '/viler/closets');
      expect(requests[2].path, '/viler/requiems');
      expect(requests[2].data, {
        'education': '2',
        'complete_address': 'Manila',
        'modernised': 'product-42',
        'chapels': hasLength(6),
        'massiness': hasLength(6),
      });
    },
  );

  test('uses the documented Fund Nexus work-information contracts', () async {
    final requests = <RequestOptions>[];
    final client = _client(sessionStore, (request) {
      requests.add(request);
      if (request.path == '/viler/externalising') {
        return _successResponse({
          'cornbraids': 'Complete your work information.',
          'orographical': [
            {
              'culinarians': 'Company Name',
              'must': 'Please input company name',
              'fasciitis': 'freshly',
              'presentableness': 'onto',
              'bobberies': 0,
              'rubicund': const [],
              'lambadas': 0,
              'steeplechases': 'SPSS',
            },
          ],
        });
      }
      return _successResponse({});
    });
    addTearDown(client.close);
    final repository = ProductRepository(apiClient: client);

    final data = await repository.fetchWorkInformation('product-42');
    await repository.saveWorkInformation(
      productId: 'product-42',
      fields: const {'freshly': 'SPSS', 'opportunities': '11'},
    );

    expect(data.fields.single.saveKey, 'freshly');
    expect(requests[0].method, 'GET');
    expect(requests[0].path, '/viler/externalising');
    expect(requests[0].queryParameters['modernised'], 'product-42');
    expect(requests[0].queryParameters['movieola'], hasLength(6));
    expect(requests[1].method, 'POST');
    expect(requests[1].path, '/viler/semihobos');
    expect(requests[1].data, {
      'freshly': 'SPSS',
      'opportunities': '11',
      'modernised': 'product-42',
      'conducted': hasLength(6),
      'settlors': hasLength(6),
      'confusional': hasLength(6),
    });
  });

  test('uses bind-card contracts and handles its liveness challenge', () async {
    final requests = <RequestOptions>[];
    final client = _client(sessionStore, (request) {
      requests.add(request);
      if (request.path == '/viler/ecclesia') {
        return _successResponse({
          'cornbraids': 'Choose an account.',
          'zebroid': 'Check it carefully.',
          'orographical': [
            {
              'culinarians': 'Bank',
              'etherifying': 2,
              'orographical': [
                {
                  'culinarians': 'Bank Account',
                  'fasciitis': 'cardNo',
                  'must': 'Please enter your bank account',
                  'presentableness': 'txt',
                  'rubicund': const [],
                  'lambadas': 0,
                },
              ],
            },
          ],
        });
      }
      return _jsonResponse({
        'fasciitis': '20000',
        'bravo': '',
        'foresight': const {'overadvertises': '5'},
      });
    });
    addTearDown(client.close);
    final repository = ProductRepository(apiClient: client);

    final data = await repository.fetchBindCard('product-42');
    final result = await repository.submitBindCard(
      productId: 'product-42',
      cardType: '2',
      fields: const {
        'channelCode': 'BDO',
        'cardNo': '0123456789',
        'confirmCardNo': '0123456789',
      },
      liveness: const BindCardLivenessPayload(),
    );

    expect(data.groups.single.type, '2');
    expect(data.topPrompt, 'Choose an account.');
    expect(data.bottomPrompt, 'Check it carefully.');
    expect(result.code, '20000');
    expect(result.bindId, '5');
    expect(requests[0].method, 'GET');
    expect(requests[0].path, '/viler/ecclesia');
    expect(requests[0].queryParameters['modernised'], 'product-42');
    expect(requests[0].queryParameters['grandstanding'], hasLength(6));
    expect(requests[0].queryParameters['unequaled'], hasLength(6));
    expect(requests[1].path, '/viler/redepositing');
    expect(requests[1].data, {
      'modernised': 'product-42',
      'symptoms': '2',
      'channelCode': 'BDO',
      'cardNo': '0123456789',
      'confirmCardNo': '0123456789',
      'myxomatoses': hasLength(7),
      'wealthily': '',
      'gibbon': '',
      'mosque': '',
    });
  });

  test('uses every documented Fund Nexus identity upload field', () async {
    final directory = await Directory.systemTemp.createTemp(
      'fund_nexus_identity_upload',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = await File(
      '${directory.path}/identity.jpg',
    ).writeAsBytes([1, 2, 3]);
    late RequestOptions capturedRequest;
    final client = _client(sessionStore, (request) {
      capturedRequest = request;
      return _successResponse({
        'emit': 'NAVEEN TOM VARGHESE',
        'outdueled': '623099344111',
        'matcher': 'Male',
        'palisades': '23/11/1993',
        'redepositing': 'https://example.com/id.jpg',
      });
    });
    addTearDown(client.close);

    await ProductRepository(apiClient: client).uploadIdentityDocument(
      filePath: file.path,
      identityType: 'PRC',
      wasCapturedWithCamera: false,
    );

    expect(capturedRequest.path, '/viler/argots');
    expect(capturedRequest.method, 'POST');
    final formData = capturedRequest.data as FormData;
    final fields = <String, String>{
      for (final field in formData.fields) field.key: field.value,
    };
    expect(fields, {
      'etherifying': '11',
      'tanners': '1',
      'symptoms': 'PRC',
      'gibbon': '',
      'mosque': '',
      'wealthily': '',
      'piroplasma': '',
    });
    expect(formData.files.single.key, 'attach');
  });

  test('uses the documented face liveness token and upload fields', () async {
    final directory = await Directory.systemTemp.createTemp(
      'fund_nexus_face_upload',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = await File('${directory.path}/face.jpg').writeAsBytes([1, 2]);
    final requests = <RequestOptions>[];
    final client = _client(sessionStore, (request) {
      requests.add(request);
      return request.path == '/viler/irenically'
          ? _successResponse({
              'bootees': '200',
              'reimplants': 'liveness-license',
              'girandola': '',
              'wealthily': 7,
            })
          : _successResponse({'hogtieing': 99});
    });
    addTearDown(client.close);
    final repository = ProductRepository(apiClient: client);

    final token = await repository.fetchFaceLivenessToken(
      orderNumber: 'ORDER-42',
    );
    await repository.uploadFaceLiveness(
      filePath: file.path,
      token: token,
      livenessId: 'liveness-42',
    );

    expect(requests[0].path, '/viler/irenically');
    expect(requests[0].data, {
      'clipsheet': 'ORDER-42',
      'etherifying': '0',
      'colombard': hasLength(6),
      'libidinal': hasLength(6),
    });
    expect(requests[1].path, '/viler/argots');
    final formData = requests[1].data as FormData;
    expect(Map<String, String>.fromEntries(formData.fields), {
      'etherifying': '10',
      'tanners': '1',
      'symptoms': '',
      'gibbon': 'liveness-42',
      'mosque': 'liveness-license',
      'wealthily': '7',
    });
    expect(formData.files.single.key, 'attach');
  });

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
