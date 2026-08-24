import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../json/json.dart';
import 'report_models.dart';

class ReportNativeBridge {
  ReportNativeBridge._({MethodChannel? channel, EventChannel? eventChannel})
    : _channel = channel ?? const MethodChannel(channelName),
      _events = eventChannel ?? const EventChannel(eventChannelName);

  static final shared = ReportNativeBridge._();

  factory ReportNativeBridge({MethodChannel? channel, EventChannel? eventChannel}) {
    if (channel != null || eventChannel != null) {
      return ReportNativeBridge._(channel: channel, eventChannel: eventChannel);
    }
    return shared;
  }

  static const channelName = 'fund_nexus/report_bridge';
  static const eventChannelName = 'fund_nexus/report_events';
  final MethodChannel _channel;
  final EventChannel _events;

  Stream<Json>? _cachedEventStream;

  Stream<Json> events() {
    _cachedEventStream ??= _events.receiveBroadcastStream().map((event) {
      debugPrint('[ReportNativeBridge] Received event from native: $event');
      return Json(event);
    }).asBroadcastStream();
    debugPrint('[ReportNativeBridge] Returning cached broadcast stream (isBroadcast: ${_cachedEventStream!.isBroadcast})');
    return _cachedEventStream!;
  }

  Future<ReportLocation?> getLocation() async {
    final map = await _map('getLocation');
    if (map == null) return null;
    final location = ReportLocation.fromMap(map);
    return location.isValid ? location : null;
  }

  Future<ReportDeviceSnapshot> getDeviceSnapshot() async =>
      ReportDeviceSnapshot.fromMap(await _map('getDeviceSnapshot') ?? const {});
  Future<String> getPushToken() => _safeString('getPushToken');
  Future<String> getTrackingStatus() => _safeString('getTrackingStatus');
  Future<void> requestNotificationPermission() =>
      _safeInvoke('requestNotificationPermission');
  Future<void> requestTrackingPermission() =>
      _safeInvoke('requestTrackingPermission');
  Future<String> requestLocationPermission() =>
      _safeString('requestLocationPermission');
  Future<void> registerForRemoteNotifications() =>
      _safeInvoke('registerForRemoteNotifications');

  Future<Map<Object?, Object?>?> _map(String method) async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<String> _safeString(String method) async {
    try {
      return (await _channel.invokeMethod<Object?>(
            method,
          ))?.toString().trim() ??
          '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  Future<void> _safeInvoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
