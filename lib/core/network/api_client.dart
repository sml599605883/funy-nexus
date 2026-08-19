import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/network/api_protocol.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/api_response.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/core/network/capture_adapter.dart';
import 'package:fund_nexus/core/network/login_response_data.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/session/session_expiry_coordinator.dart';
import 'package:fund_nexus/core/json/json.dart';

typedef ApiDataDecoder<T> = T Function(Object? data);

class ApiClient {
  ApiClient({
    required Dio dio,
    required ApiSignature signature,
    this.sessionExpiryCoordinator,
    this.protocol = const ApiProtocol(),
  }) : _dio = dio,
       _signature = signature;

  factory ApiClient.create({
    required AppConfig config,
    required SessionStore sessionStore,
    required ApiPublicParamsProvider publicParamsProvider,
    SessionExpiryCoordinator? sessionExpiryCoordinator,
    String? captureProxyHost,
    int? captureProxyPort,
    ApiProtocol protocol = const ApiProtocol(),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl.toString(),
        connectTimeout: config.connectTimeout,
        sendTimeout: config.sendTimeout,
        receiveTimeout: config.receiveTimeout,
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
      ),
    );
    final client = ApiClient(
      dio: dio,
      signature: ApiSignature(
        config: config,
        sessionStore: sessionStore,
        publicParamsProvider: publicParamsProvider,
      ),
      protocol: protocol,
      sessionExpiryCoordinator: sessionExpiryCoordinator,
    );
    final proxyHost = captureProxyHost ?? config.captureProxyHost;
    final proxyPort = captureProxyPort ?? config.captureProxyPort;
    if (proxyHost.trim().isNotEmpty && proxyPort != null) {
      CaptureAdapter.configure(
        dio,
        proxyHost: proxyHost,
        proxyPort: proxyPort,
        allowBadCertificates: config.captureAllowBadCertificates,
      );
    }
    return client;
  }

  final Dio _dio;
  final ApiSignature _signature;
  final SessionExpiryCoordinator? sessionExpiryCoordinator;
  final ApiProtocol protocol;

  /// Builds the same signed public parameters used by API requests.
  ///
  /// The H5 bridge uses this entry point so web requests cannot construct or
  /// override the app's signing parameters themselves.
  Future<Map<String, Object?>> buildSignedQuery({required String path}) async {
    final target = Uri.tryParse(path.trim());
    if (target == null || !_isAllowedSignedTarget(target)) {
      throw const ApiException(
        type: ApiFailureType.configuration,
        message: 'Signed path must target the configured API',
      );
    }
    return _signature.buildSignedQuery(path: path);
  }

  bool _isAllowedSignedTarget(Uri target) {
    if (!target.hasScheme && !target.hasAuthority) {
      return target.path.startsWith('/') && !target.path.startsWith('//');
    }
    final base = Uri.tryParse(_dio.options.baseUrl);
    if (base == null || !target.hasScheme || !target.hasAuthority) {
      return false;
    }
    return (target.scheme == 'http' || target.scheme == 'https') &&
        target.scheme == base.scheme &&
        target.host == base.host &&
        target.port == base.port;
  }

  Future<bool> probeTransport() async {
    try {
      final response = await _dio.getUri<String>(
        Uri.parse(_dio.options.baseUrl),
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );
      return response.statusCode != null;
    } on DioException catch (error) {
      return error.response?.statusCode != null;
    }
  }

  Future<ApiResponse<void>> sendLoginSmsCode({required String phone}) {
    return post<void>(
      '/viler/ethanols',
      data: {
        'ethanols': phone,
        'triazine': 'sms',
        'consular': ApiSignature.randomDigits(6),
      },
      decode: (_) {},
    );
  }

  Future<ApiResponse<LoginResponseData>> loginWithSmsCode({
    required String phone,
    required String code,
  }) {
    return post<LoginResponseData>(
      '/viler/triazine',
      data: {
        'resite': phone,
        'pelvis': code,
        'transistorizes': ApiSignature.randomDigits(6),
        'martlet': ApiSignature.randomDigits(6),
      },
      decode: LoginResponseData.fromJson,
    );
  }

  Future<ApiResponse<void>> logout() {
    return get<void>(
      '/viler/fasciitis',
      queryParameters: {
        'contrasts': ApiSignature.randomDigits(6),
        'irenically': ApiSignature.randomDigits(6),
      },
      decode: (_) {},
    );
  }

  Future<ApiResponse<void>> deleteAccount() {
    return get<void>(
      '/viler/bravo',
      queryParameters: {'cormous': ApiSignature.randomDigits(6)},
      decode: (_) {},
    );
  }

  Future<ApiResponse<Json>> fetchCertificationRetention({
    required String type,
    required String productId,
  }) {
    return post<Json>(
      '/viler/soreness',
      data: {
        'bobberies': type.trim(),
        'pesters': productId.trim(),
        'brink': ApiSignature.randomDigits(6),
      },
      decode: Json.new,
    );
  }

  Future<ApiResponse<Json>> reportLocation({
    String? province,
    required String countryCode,
    required String country,
    required String street,
    required String latitude,
    required String longitude,
    required String city,
  }) {
    return post<Json>(
      '/viler/hoblike',
      data: {
        'sustenances': province,
        'glabrate': countryCode,
        'kundalini': country,
        'unchangeable': street,
        'discolour': latitude,
        'bootstrap': longitude,
        'cherubic': city,
        'benzanthracene': ApiSignature.randomDigits(6),
        'pneumonitises': ApiSignature.randomDigits(6),
      },
      decode: (data) => Json(data),
    );
  }

  Future<ApiResponse<Json>> fetchOrderList({
    required String status,
    String page = '1',
    String pageSize = '50',
  }) {
    return post<Json>(
      '/viler/pharmacognosy',
      data: {'narthex': status, 'eclipser': page, 'immolates': pageSize},
      decode: (data) => Json(data),
    );
  }

  Future<ApiResponse<Json>> retryProgressOrder({required String orderNumber}) {
    return post<Json>(
      '/viler/clipsheet',
      data: {'readjusts': orderNumber.trim()},
      decode: (data) => Json(data),
    );
  }

  Future<ApiResponse<Json>> fetchProgressAccounts({required String productId}) {
    return post<Json>(
      '/viler/ritualize',
      data: {
        'modernised': productId.trim(),
        'occident': ApiSignature.randomDigits(6),
        'sloe': ApiSignature.randomDigits(6),
      },
      decode: (data) => Json(data),
    );
  }

  Future<ApiResponse<Json>> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) {
    return post<Json>(
      '/viler/filthier',
      data: {
        'quillwort': idfv,
        'supercontinent': ApiSignature.randomDigits(6),
        'carpers': idfa,
      },
      decode: (data) => Json(data),
    );
  }

  Future<ApiResponse<void>> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String riskDeviceId,
    required String idfa,
    required String longitude,
    required String latitude,
    required String startTime,
    required String endTime,
  }) {
    return post<void>(
      '/viler/bravenesses',
      data: {
        'pesters': productId,
        'verbifies': sceneType,
        'readjusts': orderNo,
        'vindicators': riskDeviceId,
        'mercantilisms': idfa,
        'bootstrap': longitude,
        'discolour': latitude,
        'dingbat': startTime,
        'mammocks': endTime,
        'grandstanding': latitude,
      },
      decode: (_) {},
    );
  }

  Future<ApiResponse<void>> reportDeviceInfo({
    required String encryptedPayload,
  }) {
    return post<void>(
      '/viler/uremia',
      data: {'foresight': encryptedPayload},
      decode: (_) {},
    );
  }

  Future<ApiResponse<void>> reportApplePushToken({required String token}) {
    return post<void>(
      '/viler/gossans',
      data: {'syncarps': token},
      decode: (_) {},
    );
  }

  Future<ApiResponse<void>> reportContacts({required String encryptedPayload}) {
    return post<void>(
      '/viler/crisscrossing',
      data: {
        'etherifying': '3',
        'interposers': ApiSignature.randomDigits(6),
        'multilateralism': ApiSignature.randomDigits(6),
        'foresight': encryptedPayload,
      },
      decode: (_) {},
    );
  }

  Future<ApiResponse<void>> reportTrustDecisionResult({
    required String livenessId,
    required String requestId,
    required String resultCode,
    required String result,
  }) {
    return post<void>(
      '/viler/apparentness',
      data: {
        'boors': livenessId,
        'speechwriter': requestId,
        'bootees': resultCode,
        'trokes': result,
      },
      decode: (_) {},
    );
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    String? contentType,
    CancelToken? cancelToken,
    required ApiDataDecoder<T> decode,
  }) {
    return request(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      contentType: contentType,
      cancelToken: cancelToken,
      decode: decode,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    String contentType = Headers.formUrlEncodedContentType,
    CancelToken? cancelToken,
    Set<String> additionalSuccessCodes = const {},
    required ApiDataDecoder<T> decode,
  }) {
    return request(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      contentType: contentType,
      cancelToken: cancelToken,
      additionalSuccessCodes: additionalSuccessCodes,
      decode: decode,
    );
  }

  Future<ApiResponse<T>> postMultipart<T>(
    String path, {
    required FormData data,
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
    required ApiDataDecoder<T> decode,
  }) {
    return request(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      contentType: Headers.multipartFormDataContentType,
      cancelToken: cancelToken,
      decode: decode,
    );
  }

  Future<ApiResponse<T>> request<T>(
    String path, {
    required String method,
    Object? data,
    Map<String, Object?>? queryParameters,
    String? contentType,
    CancelToken? cancelToken,
    Set<String> additionalSuccessCodes = const {},
    required ApiDataDecoder<T> decode,
  }) async {
    try {
      final signedQuery = await _signature.buildSignedQuery(
        path: path,
        extraQuery: queryParameters ?? const {},
      );
      final response = await _dio.request<Object?>(
        path,
        data: data,
        queryParameters: signedQuery,
        options: Options(method: method, contentType: contentType),
        cancelToken: cancelToken,
      );
      return _decode(
        response.data,
        decode,
        additionalSuccessCodes: additionalSuccessCodes,
      );
    } on ApiException catch (error) {
      if (error.type == ApiFailureType.authentication) {
        await sessionExpiryCoordinator?.handleExpiredSession();
      }
      rethrow;
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (error) {
      throw ApiException(
        type: ApiFailureType.unexpected,
        message: 'Unexpected request error',
        cause: error,
      );
    }
  }

  ApiResponse<T> _decode<T>(
    Object? body,
    ApiDataDecoder<T> decode, {
    Set<String> additionalSuccessCodes = const {},
  }) {
    if (body is! Map) {
      throw const ApiException(
        type: ApiFailureType.invalidResponse,
        message: 'Response body is not a JSON object',
      );
    }

    final codeValue = body[protocol.codeKey];
    if (codeValue == null) {
      throw ApiException(
        type: ApiFailureType.invalidResponse,
        message: 'Response is missing ${protocol.codeKey}',
      );
    }

    final code = codeValue.toString();
    final message = body[protocol.messageKey]?.toString() ?? '';
    final isAdditionalSuccess =
        additionalSuccessCodes.contains(code) ||
        additionalSuccessCodes.any(
          (successCode) => int.tryParse(successCode) == int.tryParse(code),
        );
    if (!protocol.isSuccess(codeValue) && !isAdditionalSuccess) {
      if (protocol.isAuthExpired(codeValue)) {
        throw ApiException(
          type: ApiFailureType.authentication,
          message: message.isEmpty ? 'Authentication has expired' : message,
          code: code,
        );
      }
      throw ApiException(
        type: ApiFailureType.business,
        message: message.isEmpty ? 'Request was rejected' : message,
        code: code,
      );
    }

    try {
      return ApiResponse<T>(
        code: code,
        message: message,
        data: decode(body[protocol.dataKey]),
      );
    } catch (error) {
      throw ApiException(
        type: ApiFailureType.invalidResponse,
        message: 'Response data has an unexpected format',
        cause: error,
      );
    }
  }

  ApiException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          type: ApiFailureType.timeout,
          message: 'Request timed out',
          cause: error,
        );
      case DioExceptionType.cancel:
        return ApiException(
          type: ApiFailureType.cancelled,
          message: 'Request was cancelled',
          cause: error,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          type: ApiFailureType.noConnection,
          message: 'Unable to connect to the server',
          cause: error,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          type: ApiFailureType.http,
          message: 'Server returned an HTTP error',
          statusCode: error.response?.statusCode,
          cause: error,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          type: ApiFailureType.noConnection,
          message: 'Server certificate validation failed',
          cause: error,
        );
      case DioExceptionType.unknown:
        final type = error.error is SocketException
            ? ApiFailureType.noConnection
            : ApiFailureType.unexpected;
        return ApiException(
          type: type,
          message: type == ApiFailureType.noConnection
              ? 'Unable to connect to the server'
              : 'Unexpected request error',
          cause: error,
        );
    }
  }

  void close() => _dio.close(force: true);
}
