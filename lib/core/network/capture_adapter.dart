import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class CaptureAdapter {
  const CaptureAdapter._();

  static bool configure(
    Dio dio, {
    required String proxyHost,
    required int? proxyPort,
    required bool allowBadCertificates,
  }) {
    final host = proxyHost.trim();
    if (host.isEmpty ||
        proxyPort == null ||
        proxyPort < 1 ||
        proxyPort > 65535) {
      return false;
    }

    final adapter = dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      return false;
    }

    adapter.createHttpClient = () {
      final client = HttpClient()..findProxy = (_) => 'PROXY $host:$proxyPort;';
      if (allowBadCertificates) {
        client.badCertificateCallback = (_, _, _) => true;
      }
      return client;
    };
    return true;
  }
}
