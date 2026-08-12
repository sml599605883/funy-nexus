import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/session/session_expiry_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';

void main() {
  test('clears and notifies once for concurrent expiry responses', () async {
    final persistence = _DelayedSessionPersistence();
    final store = SessionStore(persistence);
    await store.save(phone: '09171234567', sessionId: 'session-123');
    final coordinator = SessionExpiryCoordinator(sessionStore: store);
    addTearDown(coordinator.close);
    var events = 0;
    final firstEvent = coordinator.events.first;
    final subscription = coordinator.events.listen((_) => events++);
    addTearDown(subscription.cancel);

    final first = coordinator.handleExpiredSession();
    final second = coordinator.handleExpiredSession();
    persistence.completeClear();
    await Future.wait([first, second]);
    await firstEvent;
    await Future<void>.delayed(Duration.zero);

    expect(store.isAuthenticated, isFalse);
    expect(store.phone, '09171234567');
    expect(persistence.clearCount, 1);
    expect(events, 1);
  });

  test('does nothing when there is no authenticated session', () async {
    final persistence = _DelayedSessionPersistence();
    final coordinator = SessionExpiryCoordinator(
      sessionStore: SessionStore(persistence),
    );
    addTearDown(coordinator.close);
    var events = 0;
    final subscription = coordinator.events.listen((_) => events++);
    addTearDown(subscription.cancel);

    await coordinator.handleExpiredSession();

    expect(persistence.clearCount, 0);
    expect(events, 0);
  });
}

class _DelayedSessionPersistence implements SessionPersistence {
  String? phone;
  String? sessionId;
  int clearCount = 0;
  Completer<void>? _clearCompleter;

  @override
  Future<String?> readPhone() async => phone;

  @override
  Future<String?> readSessionId() async => sessionId;

  @override
  Future<void> writePhone(String? value) async => phone = value;

  @override
  Future<void> writeSessionId(String? value) async {
    if (value != null) {
      sessionId = value;
      return;
    }
    clearCount++;
    _clearCompleter = Completer<void>();
    await _clearCompleter!.future;
    sessionId = null;
  }

  void completeClear() => _clearCompleter?.complete();
}
