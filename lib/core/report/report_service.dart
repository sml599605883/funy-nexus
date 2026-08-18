import 'dart:async';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:flutter/foundation.dart';
import '../json/json.dart';
import '../network/api_client.dart';
import '../network/api_crypto.dart';
import '../session/session_store.dart';
import 'report_models.dart';
import 'report_native_bridge.dart';
import 'report_payload_helper.dart';
import 'report_store.dart';

class ReportService {
  ReportService({
    required this.apiClient,
    required this.sessionStore,
    required this.apiCrypto,
    ReportStore? store,
    ReportNativeBridge? native,
    int Function()? nowMillis,
    Future<void> Function(String token)? initializeAdjust,
  }) : store = store ?? ReportStore(),
       native = native ?? ReportNativeBridge(),
       _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _initializeAdjust = initializeAdjust ?? _defaultAdjust;

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final ApiCrypto apiCrypto;
  final ReportStore store;
  final ReportNativeBridge native;
  final int Function() _nowMillis;
  final Future<void> Function(String token) _initializeAdjust;
  bool _started = false;
  bool _starting = false;
  bool _marketReporting = false;
  bool _startupMarketTriggered = false;
  bool _waitingTracking = false;
  bool _adjustInitializing = false;
  Future<ReportLocation?>? _pendingLocation;
  StreamSubscription<Json>? _events;
  final Set<String> _reportingPushTokens = <String>{};
  final Set<String> _reportedPushTokens = <String>{};

  static int nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Future<void> start() async {
    if (_started || _starting) return;
    _starting = true;
    try {
      await store.clearSessionReportState();
      final first = await store.markAppOpened();
      _waitingTracking = first;
      _started = true;
      _listenEvents();
      if (first) unawaited(native.requestTrackingPermission());
      unawaited(startupPermissionsResolved());
      if (!first) unawaited(_reportStartupGoogle());
      unawaited(reportLocationAndDevice());
    } catch (error) {
      _log(error);
    } finally {
      _starting = false;
    }
  }

  Future<void> resumed() async {
    if (!_started) return;
    unawaited(reportGoogleMarket());
  }

  Future<void> startupPermissionsResolved() async {
    _waitingTracking = false;
    await _reportStartupGoogle();
    await native.registerForRemoteNotifications();
    await reportPushToken();
  }

  Future<void> loginSucceeded({int? riskStartedAtSeconds}) async {
    await store.saveLoginAt(_nowMillis());
    unawaited(
      reportRisk(
        productId: '',
        sceneType: '1',
        startTimeSeconds: riskStartedAtSeconds ?? _nowMillis() ~/ 1000,
      ),
    );
    unawaited(reportGoogleMarket());
    unawaited(reportLocationAndDevice());
    unawaited(reportPushToken(force: true));
  }

  Future<ReportLocation?> currentLocation() {
    final pending = _pendingLocation;
    if (pending != null) return pending;
    final request = _loadLocation();
    _pendingLocation = request;
    return request.whenComplete(() => _pendingLocation = null);
  }

  Future<ReportLocation?> _loadLocation() async {
    try {
      final location = await native.getLocation();
      if (location != null && location.isValid) {
        await store.saveLocation(location);
      }
      return location;
    } catch (error) {
      _log(error);
      return null;
    }
  }

  Future<ReportLocation?> _locationWithFallback() async {
    try {
      final value = await currentLocation().timeout(const Duration(seconds: 3));
      if (value != null && value.isValid) return value;
    } catch (_) {}
    return store.cachedLocation();
  }

  Future<bool> _hasSession() async =>
      (sessionStore.sessionId ?? '').trim().isNotEmpty;

  Future<void> reportLocationAndDevice() async {
    if (!await _hasSession()) return;
    try {
      final location = await _locationWithFallback();
      if (location != null && location.isValid) {
        try {
          await apiClient.reportLocation(
            province: location.province,
            countryCode: location.countryCode,
            country: location.country,
            street: location.street,
            latitude: location.latitude,
            longitude: location.longitude,
            city: location.city,
          );
        } catch (error) {
          _log(error);
        }
      }
      await reportDeviceInfo(location: location);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportGoogleMarket() async {
    final trackingStatus = await native.getTrackingStatus();
    if (trackingStatus.isEmpty || trackingStatus == 'not_determined') return;
    final snapshot = await native.getDeviceSnapshot();
    final signature = '${snapshot.idfv}|${snapshot.idfa}';
    if (snapshot.idfv.isEmpty || _marketReporting) {
      return;
    }
    await _reportGoogleSnapshot(snapshot, signature);
  }

  Future<void> _reportStartupGoogle() async {
    if (_startupMarketTriggered) return;
    final status = await native.getTrackingStatus();
    if (status.isEmpty || status == 'not_determined') return;
    _waitingTracking = false;
    _startupMarketTriggered = true;
    await reportGoogleMarket();
  }

  Future<void> _reportGoogleSnapshot(
    ReportDeviceSnapshot snapshot,
    String signature,
  ) async {
    if (_marketReporting) return;
    _marketReporting = true;
    try {
      final response = await apiClient.reportGoogleMarket(
        idfv: snapshot.idfv,
        idfa: snapshot.idfa,
      );
      final token = response.data['purringly'].stringValue.trim();
      if (token.isNotEmpty &&
          !_adjustInitializing &&
          !await store.isAdjustInitialized()) {
        _adjustInitializing = true;
        try {
          await _initializeAdjust(token);
          await store.markAdjustInitialized();
        } finally {
          _adjustInitializing = false;
        }
      }
    } catch (error) {
      _log(error);
    } finally {
      _marketReporting = false;
    }
  }

  Future<void> reportDeviceInfo({ReportLocation? location}) async {
    if (!await _hasSession()) return;
    try {
      final snapshot = await native.getDeviceSnapshot();
      final encrypted = ReportPayloadHelper.buildEncryptedDevicePayload(
        snapshot: snapshot,
        location: location ?? await _locationWithFallback(),
        deviceName: snapshot.deviceName,
        physicalSize: snapshot.screenSize,
        lastLoginAtMillis: await store.loginAt(),
        nowMillis: _nowMillis(),
        crypto: apiCrypto,
      );
      await apiClient.reportDeviceInfo(encryptedPayload: encrypted);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportPushToken({bool force = false}) async {
    try {
      final token = (await native.getPushToken()).trim();
      if ((!force && _reportedPushTokens.contains(token)) ||
          !_reportingPushTokens.add(token)) {
        return;
      }
      try {
        await apiClient.reportApplePushToken(token: token);
        _reportedPushTokens.add(token);
        if (token.isNotEmpty) await store.savePushToken(token);
      } finally {
        _reportingPushTokens.remove(token);
      }
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportRisk({
    required String productId,
    required String sceneType,
    String orderNo = '',
    required int startTimeSeconds,
  }) async {
    try {
      final snapshot = await native.getDeviceSnapshot();
      final location = await _locationWithFallback();
      final resolvedOrderNo = orderNo.trim().isNotEmpty
          ? orderNo.trim()
          : sessionStore.productDetailOrderNumber.trim();
      await apiClient.reportRiskBehavior(
        productId: productId.trim(),
        sceneType: sceneType.trim(),
        orderNo: resolvedOrderNo,
        riskDeviceId: snapshot.riskDeviceId,
        idfa: snapshot.idfa,
        longitude: location?.longitude ?? '',
        latitude: location?.latitude ?? '',
        startTime: '$startTimeSeconds',
        endTime: '${_nowMillis() ~/ 1000}',
      );
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportTrustDecisionResult({
    required String livenessId,
    required String requestId,
    required int resultCode,
    required String result,
  }) async {
    try {
      await apiClient.reportTrustDecisionResult(
        livenessId: livenessId,
        requestId: requestId,
        resultCode: '$resultCode',
        result: result,
      );
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportContacts(String encryptedPayload) async {
    try {
      await apiClient.reportContacts(encryptedPayload: encryptedPayload);
    } catch (error) {
      _log(error);
    }
  }

  void _listenEvents() {
    _events ??= native.events().listen((event) {
      final type = event['type'].stringValue;
      if (type == 'push_token') unawaited(reportPushToken());
      if (type == 'tracking_status_changed' &&
          _waitingTracking &&
          event['status'].stringValue != 'not_determined') {
        unawaited(_reportStartupGoogle());
      }
    }, onError: _log);
  }

  Future<void> dispose() async {
    await _events?.cancel();
    _events = null;
  }

  static Future<void> _defaultAdjust(String token) async {
    Adjust.initSdk(AdjustConfig(token, AdjustEnvironment.production));
  }

  static void _log(Object error) =>
      debugPrint('[FundReport] ${error.runtimeType}: $error');
}
