import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/device/device_name_data.dart';
import 'package:fund_nexus/core/device/device_metadata_store.dart';
import 'package:fund_nexus/core/device/device_name_sync.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';

void main() {
  test(
    'caches server-resolved device metadata for subsequent reports',
    () async {
      final persistence = _MemoryDeviceMetadata();
      final store = DeviceMetadataStore(persistence);
      final provider = StaticApiPublicParamsProvider(_params());
      final sync = DeviceNameSync.withLookup(
        publicParamsProvider: provider,
        metadataStore: store,
        lookup: (code) async {
          expect(code, 'iPhone17,1');
          return const DeviceNameData(
            deviceName: 'iPhone 16 Pro',
            screenSize: 6.7,
          );
        },
      );

      expect(await sync.sync(), isTrue);
      expect(await store.deviceName(), 'iPhone 16 Pro');
      expect(await store.physicalSize(), '6.7');
    },
  );

  test('does not replace cached metadata when lookup fails', () async {
    final persistence = _MemoryDeviceMetadata(deviceName: 'Existing Name');
    final store = DeviceMetadataStore(persistence);
    final sync = DeviceNameSync.withLookup(
      publicParamsProvider: StaticApiPublicParamsProvider(_params()),
      metadataStore: store,
      lookup: (_) async => throw StateError('offline'),
    );

    expect(await sync.sync(), isFalse);
    expect(await store.deviceName(), 'Existing Name');
  });
}

ApiPublicParams _params() {
  return const ApiPublicParams(
    appVersion: '1.0.0',
    deviceCode: 'iPhone17,1',
    deviceName: 'iPhone17,1',
    deviceId: 'stable-idfv',
    osVersion: '18.0',
    gpsAdId: 'stable-idfv',
  );
}

class _MemoryDeviceMetadata implements DeviceMetadataPersistence {
  _MemoryDeviceMetadata({this.deviceName});

  String? deviceId;
  String? deviceName;
  String? physicalSize;

  @override
  Future<String?> readDeviceId() async => deviceId;

  @override
  Future<String?> readDeviceName() async => deviceName;

  @override
  Future<String?> readPhysicalSize() async => physicalSize;

  @override
  Future<void> writeDeviceId(String value) async => deviceId = value;

  @override
  Future<void> writeDeviceName(String value) async => deviceName = value;

  @override
  Future<void> writePhysicalSize(String value) async => physicalSize = value;
}
