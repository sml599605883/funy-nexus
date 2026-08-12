class Json {
  Json(Object? value) : _value = _normalize(value);

  Json._raw(this._value);

  final Object? _value;

  Object? get value => _value;

  Map<String, Json> get mapValue => mapOrNull ?? const <String, Json>{};

  Map<String, Json>? get mapOrNull {
    final value = _value;
    if (value is! Map) {
      return null;
    }
    return {
      for (final entry in value.entries)
        entry.key.toString(): Json(entry.value),
    };
  }

  List<Json> get listValue => listOrNull ?? const <Json>[];

  List<Json>? get listOrNull {
    final value = _value;
    if (value is! List) {
      return null;
    }
    return value.map(Json.new).toList(growable: false);
  }

  String get stringValue => stringOrNull ?? '';

  String? get stringOrNull {
    final value = _value;
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  num get numValue => numOrNull ?? 0;

  num? get numOrNull {
    final value = _value;
    if (value is num) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? double.tryParse(value.trim());
    }
    return null;
  }

  double get doubleValue => numValue.toDouble();

  double? get doubleOrNull => numOrNull?.toDouble();

  Json operator [](Object key) {
    final value = _value;
    if (key is int && value is List && key >= 0 && key < value.length) {
      return Json._raw(value[key]);
    }
    if (value is Map) {
      return Json._raw(value[key] ?? value[key.toString()]);
    }
    return Json(null);
  }

  static Object? _normalize(Object? value) {
    if (value is Json) {
      return value.value;
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _normalize(entry.value),
      };
    }
    if (value is List) {
      return value.map(_normalize).toList(growable: false);
    }
    return value;
  }
}
