import 'package:fund_nexus/core/device/device_metadata_store.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/api_signature.dart';

typedef DeviceNameLookup = Future<String?> Function(String deviceCode);

class DeviceNameSync {
  DeviceNameSync({
    required ApiClient apiClient,
    required this.publicParamsProvider,
    required this.metadataStore,
  }) : _lookup = ((deviceCode) => _lookupWithApi(apiClient, deviceCode));

  const DeviceNameSync.withLookup({
    required this.publicParamsProvider,
    required this.metadataStore,
    required DeviceNameLookup lookup,
  }) : _lookup = lookup;

  final ApiPublicParamsProvider publicParamsProvider;
  final DeviceMetadataStore metadataStore;
  final DeviceNameLookup _lookup;

  Future<bool> sync() async {
    try {
      final params = await publicParamsProvider.load();
      final resolvedName = await _lookup(params.deviceCode) ?? '';
      if (resolvedName.trim().isEmpty) {
        return false;
      }
      await metadataStore.saveDeviceName(resolvedName);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _lookupWithApi(
    ApiClient apiClient,
    String deviceCode,
  ) async {
    final response = await apiClient.post<Map<String, Object?>>(
      '/viler/resite',
      data: {'emit': deviceCode, 'outpreen': ApiSignature.randomDigits(6)},
      decode: _decodeMap,
    );
    return response.data['nutlike']?.toString();
  }

  static Map<String, Object?> _decodeMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Device response data must be a JSON object');
    }
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
