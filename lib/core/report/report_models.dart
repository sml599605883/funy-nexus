class ReportLocation {
  const ReportLocation({
    this.province = '',
    this.locality = '',
    this.fullAddress = '',
    this.countryCode = '',
    this.country = '',
    this.street = '',
    this.latitude = '',
    this.longitude = '',
    this.city = '',
    this.permissionStatus = '',
  });

  factory ReportLocation.fromMap(Map<Object?, Object?> map) => ReportLocation(
    province: _text(map['province']),
    locality: _text(map['locality'] ?? map['subAdminArea']),
    fullAddress: _text(map['fullAddress']),
    countryCode: _text(map['countryCode']),
    country: _text(map['country']),
    street: _text(map['street']),
    latitude: _text(map['latitude']),
    longitude: _text(map['longitude']),
    city: _text(map['city']),
    permissionStatus: _text(map['permissionStatus']),
  );

  final String province;
  final String locality;
  final String fullAddress;
  final String countryCode;
  final String country;
  final String street;
  final String latitude;
  final String longitude;
  final String city;
  final String permissionStatus;

  bool get isValid =>
      latitude.isNotEmpty ||
      longitude.isNotEmpty ||
      fullAddress.isNotEmpty ||
      street.isNotEmpty ||
      city.isNotEmpty ||
      country.isNotEmpty;

  Map<String, Object?> toMap() => {
    'province': province,
    'locality': locality,
    'fullAddress': fullAddress,
    'countryCode': countryCode,
    'country': country,
    'street': street,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'permissionStatus': permissionStatus,
  };
}

class ReportDeviceSnapshot {
  const ReportDeviceSnapshot({
    this.idfv = '',
    this.idfa = '',
    this.riskDeviceId = '',
    this.batteryLevel = 0,
    this.isCharging = 0,
    this.elapsedMillis = 0,
    this.uptimeMillis = '0',
    this.isUsingProxy = 0,
    this.isUsingVpn = 0,
    this.isJailbroken = 0,
    this.isEmulator = 0,
    this.language = '',
    this.carrier = '',
    this.networkType = '',
    this.timeZoneName = '',
    this.cpuCoreCount = 0,
    this.brand = '',
    this.deviceName = '',
    this.model = '',
    this.systemVersion = '',
    this.packageName = '',
    this.screenHeight = 0,
    this.screenWidth = 0,
    this.screenSize = '',
    this.innerIp = '',
    this.currentWifiName = '',
    this.currentWifiBssid = '',
    this.wifiCount = 0,
    this.availableStorage = '0',
    this.totalStorage = '0',
    this.totalMemory = '0',
    this.availableMemory = '0',
  });

  factory ReportDeviceSnapshot.fromMap(Map<Object?, Object?> map) =>
      ReportDeviceSnapshot(
        idfv: _text(map['idfv']),
        idfa: _text(map['idfa']),
        riskDeviceId: _text(map['riskDeviceId']),
        batteryLevel: _int(map['batteryLevel']),
        isCharging: _int(map['isCharging']),
        elapsedMillis: _int(map['elapsedMillis']),
        uptimeMillis: _text(map['uptimeMillis'], '0'),
        isUsingProxy: _int(map['isUsingProxy']),
        isUsingVpn: _int(map['isUsingVpn']),
        isJailbroken: _int(map['isJailbroken']),
        isEmulator: _int(map['isEmulator']),
        language: _text(map['language']),
        carrier: _text(map['carrier']),
        networkType: _text(map['networkType']),
        timeZoneName: _text(map['timeZoneName']),
        cpuCoreCount: _int(map['cpuCoreCount']),
        brand: _text(map['brand']),
        deviceName: _text(map['deviceName']),
        model: _text(map['model']),
        systemVersion: _text(map['systemVersion']),
        packageName: _text(map['packageName']),
        screenHeight: _int(map['screenHeight']),
        screenWidth: _int(map['screenWidth']),
        screenSize: _text(map['screenSize']),
        innerIp: _text(map['innerIp']),
        currentWifiName: _text(map['currentWifiName']),
        currentWifiBssid: _text(map['currentWifiBssid']),
        wifiCount: _int(map['wifiCount']),
        availableStorage: _text(map['availableStorage'], '0'),
        totalStorage: _text(map['totalStorage'], '0'),
        totalMemory: _text(map['totalMemory'], '0'),
        availableMemory: _text(map['availableMemory'], '0'),
      );

  final String idfv;
  final String idfa;
  final String riskDeviceId;
  final int batteryLevel;
  final int isCharging;
  final int elapsedMillis;
  final String uptimeMillis;
  final int isUsingProxy;
  final int isUsingVpn;
  final int isJailbroken;
  final int isEmulator;
  final String language;
  final String carrier;
  final String networkType;
  final String timeZoneName;
  final int cpuCoreCount;
  final String brand;
  final String deviceName;
  final String model;
  final String systemVersion;
  final String packageName;
  final int screenHeight;
  final int screenWidth;
  final String screenSize;
  final String innerIp;
  final String currentWifiName;
  final String currentWifiBssid;
  final int wifiCount;
  final String availableStorage;
  final String totalStorage;
  final String totalMemory;
  final String availableMemory;
}

String reportText(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text == 'null' ? fallback : (text.isEmpty ? fallback : text);
}

String _text(Object? value, [String fallback = '']) =>
    reportText(value, fallback);
int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse(reportText(value)) ?? 0;
