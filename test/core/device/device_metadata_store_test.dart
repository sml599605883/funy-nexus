import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/device/device_metadata_store.dart';

void main() {
  test('uses Fund Nexus namespaced device metadata keys', () {
    expect(
      PersistentDeviceMetadata.deviceIdKey,
      'fund_nexus.device.stable_idfv',
    );
    expect(
      PersistentDeviceMetadata.deviceNameKey,
      'fund_nexus.device.server_name',
    );
  });

  test(
    'persists the first IDFV and reuses it after the native value changes',
    () async {
      final persistence = _MemoryDeviceMetadata();
      final store = DeviceMetadataStore(persistence);

      expect(await store.resolveStableDeviceId('first-idfv'), 'first-idfv');
      expect(await store.resolveStableDeviceId('new-idfv'), 'first-idfv');
      expect(persistence.deviceId, 'first-idfv');
    },
  );

  test('normalizes and persists a server-resolved device name', () async {
    final persistence = _MemoryDeviceMetadata();
    final store = DeviceMetadataStore(persistence);

    await store.saveDeviceName(' iPhone 16 Pro ');

    expect(await store.deviceName(), 'iPhone 16 Pro');
  });
}

class _MemoryDeviceMetadata implements DeviceMetadataPersistence {
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
