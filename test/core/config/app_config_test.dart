import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/config/app_config.dart';

void main() {
  test('accepts HTTPS production configuration', () {
    final config = AppConfig(
      environment: AppEnvironment.production,
      baseUrl: Uri.parse('https://api.example.com'),
      webBaseUrl: Uri.parse('https://web.example.com'),
      signingSecret: 'secret',
      encryptionKey: '0123456789abcdef',
      encryptionIv: 'abcdef9876543210',
    );

    expect(config.baseUrl.host, 'api.example.com');
  });

  test('rejects non-HTTPS production configuration', () {
    expect(
      () => AppConfig(
        environment: AppEnvironment.production,
        baseUrl: Uri.parse('http://api.example.com'),
        webBaseUrl: Uri.parse('https://web.example.com'),
        signingSecret: 'secret',
        encryptionKey: '0123456789abcdef',
        encryptionIv: 'abcdef9876543210',
      ),
      throwsArgumentError,
    );
  });

  test('rejects relative API URLs', () {
    expect(
      () => AppConfig(
        environment: AppEnvironment.development,
        baseUrl: Uri.parse('/api'),
        webBaseUrl: Uri.parse('https://web.example.com'),
        signingSecret: 'secret',
        encryptionKey: '0123456789abcdef',
        encryptionIv: 'abcdef9876543210',
      ),
      throwsArgumentError,
    );
  });

  test('rejects a missing production signing secret', () {
    expect(
      () => AppConfig(
        environment: AppEnvironment.production,
        baseUrl: Uri.parse('https://api.example.com'),
        webBaseUrl: Uri.parse('https://web.example.com'),
        signingSecret: '',
        encryptionKey: '0123456789abcdef',
        encryptionIv: 'abcdef9876543210',
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid AES key or IV lengths', () {
    expect(
      () => AppConfig(
        environment: AppEnvironment.development,
        baseUrl: Uri.parse('https://api.example.com'),
        webBaseUrl: Uri.parse('https://web.example.com'),
        signingSecret: 'secret',
        encryptionKey: 'short',
        encryptionIv: 'abcdef9876543210',
      ),
      throwsArgumentError,
    );
    expect(
      () => AppConfig(
        environment: AppEnvironment.development,
        baseUrl: Uri.parse('https://api.example.com'),
        webBaseUrl: Uri.parse('https://web.example.com'),
        signingSecret: 'secret',
        encryptionKey: '0123456789abcdef',
        encryptionIv: 'short',
      ),
      throwsArgumentError,
    );
  });

  test('uses the documented development API and H5 endpoints', () {
    final config = AppConfig.fromEnvironment();

    expect(config.baseUrl.toString(), 'http://8.220.188.106/rebottled');
    expect(config.webBaseUrl.toString(), 'http://8.220.188.106');
  });

  test('accepts an explicit development capture proxy', () {
    final config = AppConfig(
      environment: AppEnvironment.development,
      baseUrl: Uri.parse('http://api.example.com'),
      webBaseUrl: Uri.parse('http://web.example.com'),
      signingSecret: 'secret',
      encryptionKey: '0123456789abcdef',
      encryptionIv: 'abcdef9876543210',
      captureProxyHost: '  192.168.1.10 ',
      captureProxyPort: 8888,
    );

    expect(config.captureProxyPort, 8888);
  });

  test('rejects a capture proxy without a valid port', () {
    expect(
      () => AppConfig(
        environment: AppEnvironment.development,
        baseUrl: Uri.parse('http://api.example.com'),
        webBaseUrl: Uri.parse('http://web.example.com'),
        signingSecret: 'secret',
        encryptionKey: '0123456789abcdef',
        encryptionIv: 'abcdef9876543210',
        captureProxyHost: '192.168.1.10',
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid capture certificates in production', () {
    expect(
      () => AppConfig(
        environment: AppEnvironment.production,
        baseUrl: Uri.parse('https://api.example.com'),
        webBaseUrl: Uri.parse('https://web.example.com'),
        signingSecret: 'secret',
        encryptionKey: '0123456789abcdef',
        encryptionIv: 'abcdef9876543210',
        captureProxyHost: '192.168.1.10',
        captureProxyPort: 8888,
        captureAllowBadCertificates: true,
      ),
      throwsArgumentError,
    );
  });
}
