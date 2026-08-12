import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/network/capture_adapter.dart';

void main() {
  test('rejects missing or invalid proxy settings', () {
    final dio = Dio();

    expect(
      CaptureAdapter.configure(
        dio,
        proxyHost: '',
        proxyPort: 8888,
        allowBadCertificates: false,
      ),
      isFalse,
    );
    expect(
      CaptureAdapter.configure(
        dio,
        proxyHost: '127.0.0.1',
        proxyPort: null,
        allowBadCertificates: false,
      ),
      isFalse,
    );
  });

  test('configures the IO client to use the explicit proxy', () {
    final dio = Dio();

    expect(
      CaptureAdapter.configure(
        dio,
        proxyHost: ' 127.0.0.1 ',
        proxyPort: 8888,
        allowBadCertificates: false,
      ),
      isTrue,
    );

    final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
    expect(adapter.createHttpClient, isNotNull);
  });

  test('only permits invalid certificates when explicitly requested', () {
    final dio = Dio();
    CaptureAdapter.configure(
      dio,
      proxyHost: '127.0.0.1',
      proxyPort: 8888,
      allowBadCertificates: true,
    );

    final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
    expect(adapter.createHttpClient, isNotNull);
  });
}
