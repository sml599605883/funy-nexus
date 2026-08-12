import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SessionPersistence {
  Future<String?> readPhone();

  Future<String?> readSessionId();

  Future<void> writePhone(String? phone);

  Future<void> writeSessionId(String? sessionId);
}

class PersistentSessionPersistence implements SessionPersistence {
  PersistentSessionPersistence({
    SharedPreferencesAsync? preferences,
    FlutterSecureStorage? secureStorage,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const phoneKey = 'fund_nexus.session.phone';
  static const sessionIdKey = 'fund_nexus.session.id';

  final SharedPreferencesAsync _preferences;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readPhone() => _preferences.getString(phoneKey);

  @override
  Future<String?> readSessionId() => _secureStorage.read(key: sessionIdKey);

  @override
  Future<void> writePhone(String? phone) async {
    if (phone == null) {
      await _preferences.remove(phoneKey);
      return;
    }
    await _preferences.setString(phoneKey, phone);
  }

  @override
  Future<void> writeSessionId(String? sessionId) async {
    if (sessionId == null) {
      await _secureStorage.delete(key: sessionIdKey);
      return;
    }
    await _secureStorage.write(key: sessionIdKey, value: sessionId);
  }
}

class SessionStore {
  SessionStore(this._persistence);

  factory SessionStore.persistent() {
    return SessionStore(PersistentSessionPersistence());
  }

  final SessionPersistence _persistence;

  String? _phone;
  String? _sessionId;

  String? get phone => _phone;
  String? get sessionId => _sessionId;
  bool get isAuthenticated => _sessionId?.isNotEmpty ?? false;

  Future<void> restore() async {
    final values = await Future.wait([
      _persistence.readPhone(),
      _persistence.readSessionId(),
    ]);
    _phone = _normalize(values[0]);
    _sessionId = _normalize(values[1]);
  }

  Future<void> refreshPhone() async {
    _phone = _normalize(await _persistence.readPhone());
  }

  Future<void> save({required String phone, required String sessionId}) async {
    final normalizedPhone = _normalize(phone);
    final normalizedSessionId = _normalize(sessionId);
    if (normalizedPhone == null || normalizedSessionId == null) {
      throw ArgumentError('Phone and session ID must not be empty');
    }

    await Future.wait([
      _persistence.writePhone(normalizedPhone),
      _persistence.writeSessionId(normalizedSessionId),
    ]);
    _phone = normalizedPhone;
    _sessionId = normalizedSessionId;
  }

  Future<void> clear({bool keepPhone = true}) async {
    await Future.wait([
      if (!keepPhone) _persistence.writePhone(null),
      _persistence.writeSessionId(null),
    ]);
    if (!keepPhone) {
      _phone = null;
    }
    _sessionId = null;
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
