import 'package:fund_nexus/core/json/json.dart';

class DeviceNameData {
  const DeviceNameData({
    required this.deviceName,
    required this.screenSize,
    required this.platform,
  });

  factory DeviceNameData.fromJson(Json json) {
    return DeviceNameData(
      deviceName: json['nutlike'].stringValue.trim(),
      screenSize: json['gumdrop'].doubleOrNull,
      platform: json['V31enQ'].stringValue.trim(),
    );
  }

  final String deviceName;
  final double? screenSize;
  final String platform;
}
