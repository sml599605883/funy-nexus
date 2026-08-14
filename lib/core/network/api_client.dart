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
    required ApiDataDecoder<T> decode,
  }) {
    return request(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      contentType: contentType,
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
      return _decode(response.data, decode);
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

  ApiResponse<T> _decode<T>(Object? body, ApiDataDecoder<T> decode) {
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
    if (!protocol.isSuccess(codeValue)) {
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
