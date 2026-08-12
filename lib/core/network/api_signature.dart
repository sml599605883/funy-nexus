import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/session/session_store.dart';

typedef TimestampProvider = int Function();
typedef RandomDigitsProvider = String Function(int length);

class ApiSignature {
  ApiSignature({
    required this.config,
    required this.sessionStore,
    required this.publicParamsProvider,
    TimestampProvider? timestampProvider,
    RandomDigitsProvider? randomDigitsProvider,
  }) : _timestampProvider = timestampProvider,
       _randomDigitsProvider = randomDigitsProvider;

  final AppConfig config;
  final SessionStore sessionStore;
  final ApiPublicParamsProvider publicParamsProvider;
  final TimestampProvider? _timestampProvider;
  final RandomDigitsProvider? _randomDigitsProvider;

  static const reservedQueryKeys = <String>{
    'pathbreaking',
    'nutlike',
    'cockatoos',
    'advocation',
    'semipious',
    'coccolith',
    'reformer',
    'antipoles',
    'begloom',
    'choppiest',
    'hoods',
  };

  Future<Map<String, Object?>> buildSignedQuery({
    required String path,
    Map<String, Object?> extraQuery = const {},
  }) async {
    if (config.signingSecret.isEmpty) {
      throw const ApiException(
        type: ApiFailureType.configuration,
        message: 'API signing secret is not configured',
      );
    }
    if (extraQuery.keys.any(reservedQueryKeys.contains)) {
      throw const ApiException(
        type: ApiFailureType.configuration,
        message: 'Business query contains a reserved API parameter',
      );
    }

    final platform = await publicParamsProvider.load();
    if (platform.appVersion.trim().isEmpty ||
        platform.deviceCode.trim().isEmpty ||
        platform.deviceName.trim().isEmpty ||
        platform.deviceId.trim().isEmpty ||
        platform.osVersion.trim().isEmpty ||
        platform.gpsAdId.trim().isEmpty) {
      throw const ApiException(
        type: ApiFailureType.configuration,
        message: 'Required device metadata is unavailable',
      );
    }
    final common = <String, Object?>{
      'pathbreaking': platform.appVersion,
      'nutlike': platform.deviceName,
      'cockatoos': platform.deviceId,
      'advocation': platform.osVersion,
      'semipious': config.appMarket,
      'coccolith': sessionStore.sessionId ?? '',
      'reformer': platform.gpsAdId,
      'antipoles':
          '${_timestampProvider?.call() ?? DateTime.now().millisecondsSinceEpoch}',
    };
    final signInput = <String, Object?>{...common, 'begloom': _clearPath(path)};

    return <String, Object?>{
      ...common,
      ...extraQuery,
      'choppiest': _randomDigitsProvider?.call(6) ?? randomDigits(6),
      'hoods': sign(signInput, config.signingSecret),
    };
  }

  static String sign(Map<String, Object?> params, String secret) {
    final keys = params.keys.toList()..sort();
    final source = keys.map((key) => '$key${params[key] ?? ''}').join();
    return Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(source)).toString();
  }

  static String randomDigits(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  static String _clearPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return uri.path;
    }
    return path.split('?').first;
  }
}
