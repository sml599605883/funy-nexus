import 'package:flutter/services.dart';

class CaptureProxySettings {
  const CaptureProxySettings({required this.host, required this.port});

  final String host;
  final int port;

  bool get isValid => host.trim().isNotEmpty && port > 0 && port <= 65535;
}

class CaptureProxyDiscovery {
  const CaptureProxyDiscovery._();

  static const _channel = MethodChannel('fund_nexus/capture_proxy');

  static Future<CaptureProxySettings?> systemSettings() async {
    try {
      final value = await _channel.invokeMethod<Object?>('getSystemProxy');
      if (value is! Map) return null;
      final host = value['host']?.toString() ?? '';
      final port = value['port'] is int
          ? value['port'] as int
          : int.tryParse(value['port']?.toString() ?? '');
      if (port == null) return null;
      final settings = CaptureProxySettings(host: host, port: port);
      return settings.isValid ? settings : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
