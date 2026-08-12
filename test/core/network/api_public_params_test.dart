import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/device/device_metadata_store.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';

void main() {
  test('reloads platform metadata for every request', () async {
    final source = _ChangingPlatformSource();
    final store = DeviceMetadataStore(_MemoryDeviceMetadata());
    final provider = DeviceApiPublicParamsProvider(
      source: source,
      metadataStore: store,
    );

    final first = await provider.load();
    final second = await provider.load();

    expect(first.appVersion, '1.0.1');
    expect(second.appVersion, '1.0.2');
    expect(source.loadCount, 2);
    expect(first.deviceId, 'stable-idfv');
    expect(second.deviceId, 'stable-idfv');
  });

  test(
    'uses the cached server device name with the native model code',
    () async {
      final persistence = _MemoryDeviceMetadata(deviceName: 'iPhone 16 Pro');
      final provider = DeviceApiPublicParamsProvider(
        source: _ChangingPlatformSource(),
        metadataStore: DeviceMetadataStore(persistence),
      );

      final params = await provider.load();

      expect(params.deviceCode, 'iPhone17,1');
      expect(params.deviceName, 'iPhone 16 Pro');
    },
  );
}

class _ChangingPlatformSource implements IosPlatformMetadataSource {
  int loadCount = 0;

  @override
  Future<IosPlatformMetadata> load() async {
    loadCount++;
    return IosPlatformMetadata(
      appVersion: '1.0.$loadCount',
      modelCode: 'iPhone17,1',
      deviceId: loadCount == 1 ? 'stable-idfv' : 'changed-idfv',
      osVersion: '18.0',
    );
  }
}

class _MemoryDeviceMetadata implements DeviceMetadataPersistence {
  _MemoryDeviceMetadata({this.deviceName});

  String? deviceId;
  String? deviceName;

  @override
  Future<String?> readDeviceId() async => deviceId;

  @override
  Future<String?> readDeviceName() async => deviceName;

  @override
  Future<void> writeDeviceId(String value) async => deviceId = value;

  @override
  Future<void> writeDeviceName(String value) async => deviceName = value;
}
