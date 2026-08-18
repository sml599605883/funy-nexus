import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_models.dart';

class ReportStore {
  ReportStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync(),
      _memory = null;
  ReportStore.memory() : _preferences = null, _memory = <String, Object?>{};

  final SharedPreferencesAsync? _preferences;
  final Map<String, Object?>? _memory;
  static const _opened = 'fund_nexus.report.has_opened';
  static const _loginAt = 'fund_nexus.report.login_at';
  static const _adjust = 'fund_nexus.report.adjust_initialized';
  static const _location = 'fund_nexus.report.location';
  static const _market = 'fund_nexus.report.market_signature';
  static const _push = 'fund_nexus.report.push_token';

  Future<bool> markAppOpened() async {
    final first = !(await _bool(_opened));
    await _setBool(_opened, true);
    return first;
  }

  Future<void> saveLoginAt(int value) => _setInt(_loginAt, value);
  Future<int> loginAt() => _int(_loginAt);
  Future<bool> isAdjustInitialized() => _bool(_adjust);
  Future<void> markAdjustInitialized() => _setBool(_adjust, true);
  Future<String> marketSignature() => _string(_market);
  Future<void> saveMarketSignature(String value) => _setString(_market, value);
  Future<String> pushToken() => _string(_push);
  Future<void> savePushToken(String value) => _setString(_push, value);

  Future<void> saveLocation(ReportLocation location) =>
      _setString(_location, jsonEncode(location.toMap()));

  Future<ReportLocation?> cachedLocation() async {
    final raw = await _string(_location);
    if (raw.isEmpty) return null;
    try {
      final value = jsonDecode(raw);
      return value is Map ? ReportLocation.fromMap(value) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSessionReportState() => _remove(_location);

  Future<String> _string(String key) async {
    final memory = _memory;
    if (memory != null) return memory[key] as String? ?? '';
    return await _preferences!.getString(key) ?? '';
  }

  Future<int> _int(String key) async {
    final memory = _memory;
    if (memory != null) return memory[key] as int? ?? 0;
    return await _preferences!.getInt(key) ?? 0;
  }

  Future<bool> _bool(String key) async {
    final memory = _memory;
    if (memory != null) return memory[key] as bool? ?? false;
    return await _preferences!.getBool(key) ?? false;
  }

  Future<void> _setString(String key, String value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setString(key, value);
  }

  Future<void> _setInt(String key, int value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setInt(key, value);
  }

  Future<void> _setBool(String key, bool value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setBool(key, value);
  }

  Future<void> _remove(String key) async {
    final memory = _memory;
    if (memory != null) {
      memory.remove(key);
      return;
    }
    await _preferences!.remove(key);
  }
}
