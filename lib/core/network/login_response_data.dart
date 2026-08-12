class LoginResponseData {
  const LoginResponseData({
    required this.commenting,
    required this.invital,
    required this.resite,
    required this.argots,
    required this.coccolith,
  });

  final int commenting;
  final int invital;
  final String resite;
  final String argots;
  final String coccolith;

  factory LoginResponseData.fromJson(Object? data) {
    if (data is! Map) {
      throw const FormatException('Login data must be a JSON object');
    }

    final json = <String, Object?>{
      for (final entry in data.entries) entry.key.toString(): entry.value,
    };
    return LoginResponseData(
      commenting: _requiredInt(json, 'commenting'),
      invital: _requiredInt(json, 'invital'),
      resite: _requiredString(json, 'resite'),
      argots: _requiredString(json, 'argots'),
      coccolith: _requiredString(json, 'coccolith'),
    );
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Login field $key must be an integer');
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('Login field $key must be a string');
  }
}
