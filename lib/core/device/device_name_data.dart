import 'package:fund_nexus/core/json/json.dart';

class DeviceNameData {
  const DeviceNameData({required this.deviceName, required this.screenSize});

  factory DeviceNameData.fromJson(Json json) {
    return DeviceNameData(
      deviceName: json['nutlike'].stringValue.trim(),
      screenSize: json['gumdrop'].doubleOrNull,
    );
  }

  final String deviceName;
  final double? screenSize;
}
