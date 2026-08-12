import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fund_nexus/core/device/device_metadata_store.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract interface class ApiPublicParamsProvider {
  Future<ApiPublicParams> load();
}

abstract interface class IosPlatformMetadataSource {
  Future<IosPlatformMetadata> load();
}

class PluginIosPlatformMetadataSource implements IosPlatformMetadataSource {
  PluginIosPlatformMetadataSource({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<IosPlatformMetadata> load() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Fund Nexus API public params are iOS-specific');
    }

    final results = await Future.wait<Object>([
      _deviceInfo.iosInfo,
      PackageInfo.fromPlatform(),
    ]);
    final device = results[0] as IosDeviceInfo;
    final package = results[1] as PackageInfo;
    final modelCode = device.utsname.machine.trim().isNotEmpty
        ? device.utsname.machine.trim()
        : device.model.trim();

    return IosPlatformMetadata(
      appVersion: package.version.trim(),
      modelCode: modelCode,
      deviceId: device.identifierForVendor?.trim() ?? '',
      osVersion: device.systemVersion.trim(),
    );
  }
}

class DeviceApiPublicParamsProvider implements ApiPublicParamsProvider {
  DeviceApiPublicParamsProvider({
    required this.source,
    required this.metadataStore,
  });

  final IosPlatformMetadataSource source;
  final DeviceMetadataStore metadataStore;

  @override
  Future<ApiPublicParams> load() async {
    final metadata = await source.load();
    final deviceId = await metadataStore.resolveStableDeviceId(
      metadata.deviceId,
    );
    final deviceName = await metadataStore.deviceName() ?? metadata.modelCode;

    return ApiPublicParams(
      appVersion: metadata.appVersion,
      deviceCode: metadata.modelCode,
      deviceName: deviceName,
      deviceId: deviceId,
      osVersion: metadata.osVersion,
      gpsAdId: deviceId,
    );
  }
}

class IosPlatformMetadata {
  const IosPlatformMetadata({
    required this.appVersion,
    required this.modelCode,
    required this.deviceId,
    required this.osVersion,
  });

  final String appVersion;
  final String modelCode;
  final String deviceId;
  final String osVersion;
}

class ApiPublicParams {
  const ApiPublicParams({
    required this.appVersion,
    required this.deviceCode,
    required this.deviceName,
    required this.deviceId,
    required this.osVersion,
    required this.gpsAdId,
  });

  final String appVersion;
  final String deviceCode;
  final String deviceName;
  final String deviceId;
  final String osVersion;
  final String gpsAdId;
}

class StaticApiPublicParamsProvider implements ApiPublicParamsProvider {
  const StaticApiPublicParamsProvider(this.params);

  final ApiPublicParams params;

  @override
  Future<ApiPublicParams> load() async => params;
}
