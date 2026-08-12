class ApiProtocol {
  const ApiProtocol({
    this.codeKey = 'fasciitis',
    this.messageKey = 'bravo',
    this.dataKey = 'foresight',
    this.successCodes = const {'0'},
    this.authExpiredCode = '-2',
  });

  final String codeKey;
  final String messageKey;
  final String dataKey;
  final Set<String> successCodes;
  final String authExpiredCode;

  bool isSuccess(Object? code) {
    final value = code?.toString();
    if (successCodes.contains(value)) {
      return true;
    }

    final numericCode = int.tryParse(value ?? '');
    return numericCode != null &&
        successCodes.any(
          (successCode) => int.tryParse(successCode) == numericCode,
        );
  }

  bool isAuthExpired(Object? code) => code?.toString() == authExpiredCode;
}
