import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  test('routes an HTTP request through the configured proxy', () async {
    final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(proxy.close);
    final requestLine = Completer<String>();
    proxy.listen((socket) {
      var text = '';
      socket.listen((data) {
        text += utf8.decode(data);
        if (!text.contains('\r\n\r\n')) return;
        if (!requestLine.isCompleted) {
          requestLine.complete(text.split('\r\n').first);
        }
        socket.write(
          'HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK',
        );
        socket.close();
      });
    });
    final dio = Dio();
    addTearDown(dio.close);
    CaptureAdapter.configure(
      dio,
      proxyHost: InternetAddress.loopbackIPv4.address,
      proxyPort: proxy.port,
      allowBadCertificates: false,
    );

    final response = await dio.get<String>('http://example.test/capture');

    expect(response.data, 'OK');
    expect(
      await requestLine.future,
      'GET http://example.test/capture HTTP/1.1',
    );
  });
}
