import 'package:fund_nexus/core/device/device_name_data.dart';
import 'package:fund_nexus/core/device/device_metadata_store.dart';
import 'package:fund_nexus/core/json/json.dart';
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
    final response = await apiClient.post<DeviceNameData>(
      '/viler/resite',
      data: {'emit': deviceCode, 'outpreen': ApiSignature.randomDigits(6)},
      decode: (data) => DeviceNameData.fromJson(Json(data)),
    );
    return response.data.deviceName;
  }
}
