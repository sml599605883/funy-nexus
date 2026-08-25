import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class DeviceMetadataPersistence {
  Future<String?> readDeviceId();

  Future<String?> readDeviceName();

  Future<String?> readPhysicalSize();

  Future<void> writeDeviceId(String value);

  Future<void> writeDeviceName(String value);

  Future<void> writePhysicalSize(String value);
}

class PersistentDeviceMetadata implements DeviceMetadataPersistence {
  PersistentDeviceMetadata({
    SharedPreferencesAsync? preferences,
    FlutterSecureStorage? secureStorage,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  static const deviceIdKey = 'fund_nexus.device.stable_idfv';
  static const deviceNameKey = 'fund_nexus.device.server_name';
  static const physicalSizeKey = 'fund_nexus.device.physical_size';

  final SharedPreferencesAsync _preferences;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readDeviceId() => _secureStorage.read(key: deviceIdKey);

  @override
  Future<String?> readDeviceName() => _preferences.getString(deviceNameKey);

  @override
  Future<String?> readPhysicalSize() => _preferences.getString(physicalSizeKey);

  @override
  Future<void> writeDeviceId(String value) {
    return _secureStorage.write(key: deviceIdKey, value: value);
  }

  @override
  Future<void> writeDeviceName(String value) {
    return _preferences.setString(deviceNameKey, value);
  }

  @override
  Future<void> writePhysicalSize(String value) {
    return _preferences.setString(physicalSizeKey, value);
  }
}

class DeviceMetadataStore {
  DeviceMetadataStore(this._persistence);

  factory DeviceMetadataStore.persistent() {
    return DeviceMetadataStore(PersistentDeviceMetadata());
  }

  final DeviceMetadataPersistence _persistence;

  Future<String> resolveStableDeviceId(String currentIdfv) async {
    final stored = _normalize(await _persistence.readDeviceId());
    if (stored != null) {
      return stored;
    }

    final current = _normalize(currentIdfv);
    if (current == null) {
      return '';
    }
    await _persistence.writeDeviceId(current);
    return current;
  }

  Future<String?> deviceName() async {
    return _normalize(await _persistence.readDeviceName());
  }

  Future<void> saveDeviceName(String value) async {
    final normalized = _normalize(value);
    if (normalized == null) {
      return;
    }
    await _persistence.writeDeviceName(normalized);
  }

  Future<String?> physicalSize() async {
    return _normalize(await _persistence.readPhysicalSize());
  }

  Future<void> savePhysicalSize(num? value) async {
    if (value == null || !value.isFinite || value <= 0) {
      return;
    }
    await _persistence.writePhysicalSize(value.toString());
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
