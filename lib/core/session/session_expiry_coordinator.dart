import 'dart:async';

import 'package:fund_nexus/core/session/session_store.dart';

class SessionExpiryCoordinator {
  SessionExpiryCoordinator({required this.sessionStore});

  final SessionStore sessionStore;
  final StreamController<void> _events = StreamController<void>.broadcast();
  Future<void>? _handling;

  Stream<void> get events => _events.stream;

  Future<void> handleExpiredSession() {
    final active = _handling;
    if (active != null) return active;
    if (!sessionStore.isAuthenticated) return Future.value();

    final operation = _clearAndNotify();
    _handling = operation;
    return operation.whenComplete(() {
      if (identical(_handling, operation)) _handling = null;
    });
  }

  Future<void> _clearAndNotify() async {
    await sessionStore.clear();
    _events.add(null);
  }

  Future<void> close() => _events.close();
}
