import 'package:flutter/services.dart';

class AppReviewBridge {
  const AppReviewBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'fund_nexus/app_review';

  final MethodChannel _channel;

  Future<void> requestReview() async {
    try {
      await _channel.invokeMethod<void>('requestReview');
    } on MissingPluginException {
      // Review is optional on unsupported platforms/build configurations.
    } on PlatformException {
      // A system review prompt may be rate-limited or unavailable.
    }
  }
}
