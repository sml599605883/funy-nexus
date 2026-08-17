import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/session/session_store.dart';

void main() {
  test('uses Fund Nexus namespaced persistent keys', () {
    expect(PersistentSessionPersistence.phoneKey, 'fund_nexus.session.phone');
    expect(PersistentSessionPersistence.sessionIdKey, 'fund_nexus.session.id');
  });

  test('restores and normalizes persisted session', () async {
    final persistence = _MemorySessionPersistence(
      phone: ' 09171234567 ',
      sessionId: ' session-123 ',
    );
    final store = SessionStore(persistence);

    await store.restore();

    expect(store.phone, '09171234567');
    expect(store.sessionId, 'session-123');
    expect(store.isAuthenticated, isTrue);
  });

  test('saves both phone and session ID', () async {
    final persistence = _MemorySessionPersistence();
    final store = SessionStore(persistence);

    await store.save(phone: ' 09171234567 ', sessionId: ' token ');

    expect(persistence.phone, '09171234567');
    expect(persistence.sessionId, 'token');
    expect(store.isAuthenticated, isTrue);
  });

  test('refreshes only the persisted phone', () async {
    final persistence = _MemorySessionPersistence(
      phone: '09171234567',
      sessionId: 'token',
    );
    final store = SessionStore(persistence);
    await store.restore();
    persistence.phone = '09981234567';

    await store.refreshPhone();

    expect(store.phone, '09981234567');
    expect(store.sessionId, 'token');
  });

  test('clear removes credential but remembers phone by default', () async {
    final persistence = _MemorySessionPersistence();
    final store = SessionStore(persistence);
    await store.save(phone: '09171234567', sessionId: 'token');

    await store.clear();

    expect(store.phone, '09171234567');
    expect(store.sessionId, isNull);
    expect(persistence.phone, '09171234567');
    expect(persistence.sessionId, isNull);
    expect(store.isAuthenticated, isFalse);
  });

  test(
    'keeps product detail guidance in memory and clears it with session',
    () async {
      final store = SessionStore(_MemorySessionPersistence());
      store.cacheProductDetailIdentityGuidance('  Please confirm your ID.  ');

      expect(store.productDetailIdentityGuidance, 'Please confirm your ID.');

      await store.clear();

      expect(store.productDetailIdentityGuidance, isEmpty);
    },
  );

  test(
    'keeps face guidance and order context in memory for certification',
    () async {
      final store = SessionStore(_MemorySessionPersistence());
      store.cacheProductDetailCertification(
        identityGuidance: 'Upload your ID.',
        faceGuidance: 'Keep your face in the frame.',
        orderNumber: 'ORDER-42',
      );

      expect(store.productDetailFaceGuidance, 'Keep your face in the frame.');
      expect(store.productDetailOrderNumber, 'ORDER-42');

      await store.clear();
      expect(store.productDetailFaceGuidance, isEmpty);
      expect(store.productDetailOrderNumber, isEmpty);
    },
  );

  test('clear can remove all persisted session data', () async {
    final persistence = _MemorySessionPersistence();
    final store = SessionStore(persistence);
    await store.save(phone: '09171234567', sessionId: 'token');

    await store.clear(keepPhone: false);

    expect(store.phone, isNull);
    expect(persistence.phone, isNull);
  });

  test('rejects empty session values', () async {
    final store = SessionStore(_MemorySessionPersistence());

    expect(
      () => store.save(phone: '09171234567', sessionId: '  '),
      throwsArgumentError,
    );
  });
}

class _MemorySessionPersistence implements SessionPersistence {
  _MemorySessionPersistence({this.phone, this.sessionId});

  String? phone;
  String? sessionId;

  @override
  Future<String?> readPhone() async => phone;

  @override
  Future<String?> readSessionId() async => sessionId;

  @override
  Future<void> writePhone(String? value) async => phone = value;

  @override
  Future<void> writeSessionId(String? value) async => sessionId = value;
}
