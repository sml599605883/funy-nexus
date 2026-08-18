import 'dart:convert';
import '../network/api_crypto.dart';
import 'report_models.dart';

class ReportPayloadHelper {
  const ReportPayloadHelper._();

  static String normalize(Object? value) => reportText(value);

  static Map<String, Object?> buildRiskPayload({
    required String productId,
    required String sceneType,
    required String orderNo,
    required ReportDeviceSnapshot snapshot,
    required ReportLocation? location,
    required int startTimeSeconds,
    required int endTimeSeconds,
  }) => {
    'pesters': normalize(productId),
    'verbifies': normalize(sceneType),
    'readjusts': normalize(orderNo),
    'vindicators': normalize(snapshot.riskDeviceId),
    'mercantilisms': normalize(snapshot.idfa),
    'bootstrap': normalize(location?.longitude),
    'discolour': normalize(location?.latitude),
    'dingbat': '$startTimeSeconds',
    'mammocks': '$endTimeSeconds',
    'grandstanding': normalize(location?.latitude),
  };

  static String buildEncryptedDevicePayload({
    required ReportDeviceSnapshot snapshot,
    required ReportLocation? location,
    required String deviceName,
    required String physicalSize,
    required int lastLoginAtMillis,
    required int nowMillis,
    required ApiCrypto crypto,
  }) {
    final payload = <String, Object?>{
      'morphometric': normalize(snapshot.systemVersion),
      'czarevna': lastLoginAtMillis,
      'bedizen': normalize(snapshot.packageName),
      'missises': {
        'telegonic': snapshot.batteryLevel,
        'pleader': snapshot.isCharging,
      },
      'omnipotently': {
        'circularizes': normalize(location?.longitude),
        'usquebaugh': normalize(location?.latitude),
        'sinuousnesses': normalize(location?.fullAddress),
        'hexastichs': {
          'kundalini': normalize(location?.country),
          'glabrate': normalize(location?.countryCode),
          'sustenances': normalize(location?.province),
          'cherubic': normalize(location?.city),
          'wagoning': normalize(location?.locality),
          'unchangeable': normalize(location?.street),
        },
      },
      'lodes': {
        'quillwort': normalize(snapshot.idfv),
        'carpers': normalize(snapshot.idfa),
        'gauntry': normalize(snapshot.currentWifiBssid),
        'apprizer': nowMillis,
        'interpreting': normalize(snapshot.elapsedMillis),
        'imperiousnesses': snapshot.isUsingProxy,
        'expiratory': snapshot.isUsingVpn,
        'veinulet': snapshot.isJailbroken,
        'deixis': snapshot.isEmulator,
        'conclusively': normalize(snapshot.language),
        'gobshite': normalize(snapshot.carrier),
        'nondevelopments': normalize(snapshot.networkType),
        'crookedly': const <Map<String, Object?>>[],
        'bullnecks': normalize(snapshot.timeZoneName),
        'animadversions': normalize(snapshot.uptimeMillis),
      },
      'irritated': {
        'hamate': normalize(snapshot.model),
        'logan': normalize(snapshot.brand),
        'spacings': snapshot.cpuCoreCount,
        'chalice': snapshot.screenHeight,
        'sagaman': normalize(
          snapshot.deviceName.isEmpty ? deviceName : snapshot.deviceName,
        ),
        'blondining': snapshot.screenWidth,
        'miscomputation': normalize(snapshot.model),
        'gumdrop': normalize(physicalSize),
        'parfocalities': normalize(snapshot.systemVersion),
      },
      'columbic': {
        'rein': normalize(snapshot.innerIp),
        'landward': [
          {
            'emit': normalize(snapshot.currentWifiName),
            'hominizes': normalize(snapshot.currentWifiBssid),
            'gauntry': normalize(snapshot.currentWifiBssid),
            'parfocal': normalize(snapshot.currentWifiName),
          },
        ],
        'isomorphism': {
          'emit': normalize(snapshot.currentWifiName),
          'hominizes': normalize(snapshot.currentWifiBssid),
          'gauntry': normalize(snapshot.currentWifiBssid),
          'parfocal': normalize(snapshot.currentWifiName),
        },
        'breachers': snapshot.wifiCount,
      },
      'bathymetric': {
        'breads': normalize(snapshot.availableStorage),
        'opts': normalize(snapshot.totalStorage),
        'burs': normalize(snapshot.totalMemory),
        'intitling': normalize(snapshot.availableMemory),
      },
    };
    return crypto.encryptText(jsonEncode(payload));
  }
}
