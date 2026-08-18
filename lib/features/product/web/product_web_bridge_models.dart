import 'dart:convert';

import 'package:fund_nexus/core/json/json.dart';

class ProductWebBridgeRequest {
  const ProductWebBridgeRequest({
    required this.action,
    required this.callbackId,
    required this.data,
    required this.rawData,
  });

  factory ProductWebBridgeRequest.decode(Object? message) {
    Object? decoded = message;
    if (message is String) {
      try {
        decoded = jsonDecode(message);
      } catch (_) {
        decoded = null;
      }
    }
    final source = Json(decoded).mapValue;
    final rawData =
        source['data']?.value ??
        source['payload']?.value ??
        source['params']?.value;
    return ProductWebBridgeRequest(
      action: _string(source, const ['action', 'name', 'method']),
      callbackId: _string(source, const ['callbackId', 'callback', 'id']),
      data: _map(rawData),
      rawData: rawData,
    );
  }

  final String action;
  final String callbackId;
  final Map<String, dynamic> data;
  final Object? rawData;

  bool get expectsCallback => callbackId.isNotEmpty;

  String get rawDataString {
    if (rawData is String) return (rawData as String).trim();
    if (rawData == null) return '';
    try {
      return jsonEncode(rawData).trim();
    } catch (_) {
      return '';
    }
  }

  static String _string(Map<String, Json> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.stringValue.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static Map<String, dynamic> _map(Object? value) {
    final map = Json(value).mapOrNull;
    if (map == null) return <String, dynamic>{};
    return map.map((key, value) => MapEntry(key, value.value));
  }
}

class ProductWebBridgeResult {
  const ProductWebBridgeResult({
    required this.code,
    required this.message,
    this.data = const <String, dynamic>{},
  });

  const ProductWebBridgeResult.success([
    Map<String, dynamic> data = const <String, dynamic>{},
  ]) : this(code: 0, message: 'success', data: data);

  const ProductWebBridgeResult.failure(String message, {int code = -1})
    : this(code: code, message: message);

  final int code;
  final String message;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'message': message,
    'data': data,
  };
}
