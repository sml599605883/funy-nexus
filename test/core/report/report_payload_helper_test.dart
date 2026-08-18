import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/network/api_crypto.dart';
import 'package:fund_nexus/core/report/report_models.dart';
import 'package:fund_nexus/core/report/report_payload_helper.dart';
import 'package:fund_nexus/core/report/report_store.dart';

void main() {
  test('builds the documented encrypted device payload', () {
    const key = '1234567890123456';
    const iv = '6543210987654321';
    final encrypted = ReportPayloadHelper.buildEncryptedDevicePayload(
      snapshot: const ReportDeviceSnapshot(
        idfv: 'idfv',
        idfa: 'idfa',
        batteryLevel: 80,
        isCharging: 1,
        elapsedMillis: 10,
        uptimeMillis: '20',
        systemVersion: '18.0',
        packageName: 'com.example',
        currentWifiName: 'wifi',
        currentWifiBssid: 'bssid',
      ),
      location: const ReportLocation(latitude: '1', longitude: '2'),
      deviceName: 'iPhone',
      physicalSize: '6.1',
      lastLoginAtMillis: 30,
      nowMillis: 40,
      crypto: ApiCrypto(key: key, iv: iv),
    );
    final payload =
        jsonDecode(ApiCrypto(key: key, iv: iv).decryptText(encrypted))
            as Map<String, dynamic>;
    expect(payload['morphometric'], '18.0');
    expect(payload['czarevna'], 30);
    expect(payload['lodes']['quillwort'], 'idfv');
    expect(payload['lodes']['interpreting'], '10');
    expect(payload['lodes']['animadversions'], '20');
    expect(payload['omnipotently']['circularizes'], '2');
  });

  test('memory report store persists and clears location state', () async {
    final store = ReportStore.memory();
    expect(await store.markAppOpened(), isTrue);
    expect(await store.markAppOpened(), isFalse);
    await store.saveLocation(const ReportLocation(city: 'Makati'));
    expect((await store.cachedLocation())?.city, 'Makati');
    await store.clearSessionReportState();
    expect(await store.cachedLocation(), isNull);
  });
}
