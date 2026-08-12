enum ApiFailureType {
  business,
  authentication,
  configuration,
  timeout,
  noConnection,
  cancelled,
  http,
  invalidResponse,
  unexpected,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.cause,
  });

  final ApiFailureType type;
  final String message;
  final String? code;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'ApiException($type, $message)';
}
