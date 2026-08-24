import 'dart:async';

import 'package:flutter/widgets.dart';

import '../json/json.dart';
import '../report/report_native_bridge.dart';

typedef NativeNotificationEvents = Stream<Json> Function();
typedef NotificationNavigationReady = bool Function();
typedef NotificationRouteOpener = Future<void> Function(String route);
typedef NotificationRouteDeferrer = void Function(VoidCallback callback);

class IosNotificationRouteCoordinator {
  IosNotificationRouteCoordinator({
    NativeNotificationEvents? events,
    NotificationNavigationReady? navigationReady,
    NotificationRouteOpener? openRoute,
    NotificationRouteDeferrer? defer,
  })  : _events = events ?? _defaultEvents,
        _navigationReady = navigationReady ?? _isNavigationReady,
        _openRoute = openRoute ?? _defaultOpenRoute,
        _defer = defer ?? _deferUntilNextFrame;

  static IosNotificationRouteCoordinator? _instance;

  static IosNotificationRouteCoordinator get instance {
    return _instance ?? IosNotificationRouteCoordinator();
  }

  static void configure({
    NotificationRouteOpener? openRoute,
  }) {
    _instance = IosNotificationRouteCoordinator(
      openRoute: openRoute,
    );
  }

  final NativeNotificationEvents _events;
  final NotificationNavigationReady _navigationReady;
  final NotificationRouteOpener _openRoute;
  final NotificationRouteDeferrer _defer;

  StreamSubscription<Json>? _subscription;
  Future<void> _deliveryChain = Future<void>.value();
  int _lifecycle = 0;

  void start() {
    if (_subscription != null) return;
    debugPrint('[IosNotificationRouteCoordinator] Starting coordinator');
    final lifecycle = ++_lifecycle;
    _subscription = _events().listen((event) {
      debugPrint('[IosNotificationRouteCoordinator] Received event: ${event.value}');
      _accept(event, lifecycle);
    }, onError: (error) {
      debugPrint('[IosNotificationRouteCoordinator] Event stream error: $error');
    });
    debugPrint('[IosNotificationRouteCoordinator] Listening to event stream');
  }

  Future<void> stop() async {
    _lifecycle++;
    await _subscription?.cancel();
    _subscription = null;
    _deliveryChain = Future<void>.value();
  }

  void _accept(Json event, int lifecycle) {
    final type = event['type'].stringValue;
    debugPrint('[IosNotificationRouteCoordinator] Event type: $type');
    if (type != 'push_route') return;
    final route = event['url'].stringValue.trim();
    debugPrint('[IosNotificationRouteCoordinator] Push route: $route');
    if (route.isEmpty) return;
    _deliveryChain = _deliveryChain.then((_) => _deliver(route, lifecycle));
  }

  Future<void> _deliver(String route, int lifecycle) async {
    try {
      debugPrint('[IosNotificationRouteCoordinator] Delivering route: $route');
      debugPrint('[IosNotificationRouteCoordinator] _openRoute handler: ${_openRoute.runtimeType}');
      while (lifecycle == _lifecycle && !_navigationReady()) {
        debugPrint('[IosNotificationRouteCoordinator] Waiting for navigation to be ready...');
        await _nextFrame();
      }
      if (lifecycle == _lifecycle) {
        debugPrint('[IosNotificationRouteCoordinator] Navigation ready, opening route: $route');
        debugPrint('[IosNotificationRouteCoordinator] About to call _openRoute...');
        await _openRoute(route);
        debugPrint('[IosNotificationRouteCoordinator] Route opened successfully');
      } else {
        debugPrint('[IosNotificationRouteCoordinator] Lifecycle mismatch, skipping route');
      }
    } catch (error, stackTrace) {
      debugPrint('[IosNotificationRouteCoordinator] Error delivering route: $error');
      debugPrint('[IosNotificationRouteCoordinator] Stack trace: $stackTrace');
    }
  }

  static Stream<Json> _defaultEvents() {
    debugPrint('[IosNotificationRouteCoordinator] Using ReportNativeBridge.shared for events');
    return ReportNativeBridge.shared.events();
  }

  static bool _isNavigationReady() {
    return _navigatorKey.currentContext?.mounted ?? false;
  }

  static Future<void> _defaultOpenRoute(String route) async {
    // Default implementation: just log the route
    // Applications should provide their own route opener
    debugPrint('[IosNotificationRouteCoordinator] Received route: $route');
  }

  Future<void> _nextFrame() {
    final frame = Completer<void>();
    _defer(frame.complete);
    return frame.future;
  }

  static void _deferUntilNextFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }

  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}

