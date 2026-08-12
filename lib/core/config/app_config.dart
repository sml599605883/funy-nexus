enum AppEnvironment { development, staging, production }

class AppConfig {
  AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.webBaseUrl,
    required this.signingSecret,
    required this.encryptionKey,
    required this.encryptionIv,
    this.appMarket = 'appstore-ph-fund-nexus-ios',
    this.captureProxyHost = '',
    this.captureProxyPort,
    this.captureAllowBadCertificates = false,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
  }) {
    _validateAbsoluteUrl(baseUrl, 'baseUrl');
    _validateAbsoluteUrl(webBaseUrl, 'webBaseUrl');
    if (environment == AppEnvironment.production &&
        (baseUrl.scheme != 'https' || webBaseUrl.scheme != 'https')) {
      throw ArgumentError.value(
        '$baseUrl, $webBaseUrl',
        'baseUrl/webBaseUrl',
        'Production endpoints must use HTTPS',
      );
    }
    if (signingSecret.trim().isEmpty) {
      throw ArgumentError('API signing secret must not be empty');
    }
    if (![16, 24, 32].contains(encryptionKey.length)) {
      throw ArgumentError('AES key must contain 16, 24, or 32 UTF-8 bytes');
    }
    if (encryptionIv.length != 16) {
      throw ArgumentError('AES-CBC IV must contain 16 UTF-8 bytes');
    }
    if (captureProxyHost.trim().isNotEmpty &&
        (captureProxyPort == null ||
            captureProxyPort! < 1 ||
            captureProxyPort! > 65535)) {
      throw ArgumentError('Capture proxy port must be between 1 and 65535');
    }
    if (environment == AppEnvironment.production &&
        captureAllowBadCertificates) {
      throw ArgumentError(
        'Production must not allow invalid proxy certificates',
      );
    }
  }

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://8.220.188.106/rebottled',
    );
    const webBaseUrl = String.fromEnvironment(
      'WEB_BASE_URL',
      defaultValue: 'http://8.220.188.106',
    );
    const signingSecret = String.fromEnvironment(
      'API_SIGNING_SECRET',
      defaultValue: '',
    );
    const encryptionKey = String.fromEnvironment(
      'API_AES_KEY',
      defaultValue: '',
    );
    const encryptionIv = String.fromEnvironment('API_AES_IV', defaultValue: '');
    const captureProxyHost = String.fromEnvironment(
      'CAPTURE_PROXY_HOST',
      defaultValue: '',
    );
    const captureProxyPortValue = String.fromEnvironment(
      'CAPTURE_PROXY_PORT',
      defaultValue: '',
    );
    const captureAllowBadCertificates = bool.fromEnvironment(
      'CAPTURE_ALLOW_BAD_CERTIFICATES',
      defaultValue: false,
    );
    return AppConfig(
      environment: AppEnvironment.values.firstWhere(
        (value) => value.name == environmentName,
        orElse: () => throw ArgumentError.value(
          environmentName,
          'APP_ENV',
          'Expected development, staging, or production',
        ),
      ),
      baseUrl: Uri.parse(baseUrl),
      webBaseUrl: Uri.parse(webBaseUrl),
      signingSecret: signingSecret,
      encryptionKey: encryptionKey,
      encryptionIv: encryptionIv,
      captureProxyHost: captureProxyHost,
      captureProxyPort: int.tryParse(captureProxyPortValue),
      captureAllowBadCertificates: captureAllowBadCertificates,
    );
  }

  final AppEnvironment environment;
  final Uri baseUrl;
  final Uri webBaseUrl;
  final String signingSecret;
  final String encryptionKey;
  final String encryptionIv;
  final String appMarket;
  final String captureProxyHost;
  final int? captureProxyPort;
  final bool captureAllowBadCertificates;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;

  static void _validateAbsoluteUrl(Uri value, String name) {
    if (!value.hasScheme || !value.hasAuthority) {
      throw ArgumentError.value(value, name, 'Must be an absolute URL');
    }
  }
}
