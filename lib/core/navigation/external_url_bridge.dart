import 'package:flutter/services.dart';

class ExternalUrlBridge {
  const ExternalUrlBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'fund_nexus/external_url';

  final MethodChannel _channel;

  Future<bool> openHttpUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    return openUri(uri);
  }

  Future<bool> openUri(Uri uri) async {
    if (uri.scheme.isEmpty ||
        ((uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isEmpty)) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('openHttpUrl', uri.toString()) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
