import 'package:fund_nexus/core/json/json.dart';

enum HomePopupType {
  none,
  appUpgrade,
  membershipUpgrade,
  marketing,
  unsupported,
}

class HomePopupData {
  const HomePopupData({
    required this.type,
    this.version = '',
    this.message = '',
    this.imageUrl = '',
    this.targetUrl = '',
  });

  final HomePopupType type;
  final String version;
  final String message;
  final String imageUrl;
  final String targetUrl;

  bool get shouldShow => switch (type) {
    HomePopupType.appUpgrade => true,
    HomePopupType.marketing => imageUrl.isNotEmpty,
    _ => false,
  };

  factory HomePopupData.fromResponse(Json data) {
    final popup = data['leapt'];
    return HomePopupData(
      type: switch (data['etherifying'].numValue.toInt()) {
        0 => HomePopupType.none,
        1 => HomePopupType.appUpgrade,
        2 => HomePopupType.membershipUpgrade,
        3 => HomePopupType.marketing,
        _ => HomePopupType.unsupported,
      },
      version: popup['stookers'].stringValue.trim(),
      message: popup['heliacally'].stringValue.trim(),
      imageUrl: popup['zymometer'].stringValue.trim(),
      targetUrl: popup['redepositing'].stringValue.trim(),
    );
  }

  String get displayVersion {
    final value = version.trim();
    if (value.isEmpty) return '';
    return value.toUpperCase().startsWith('V') ? value : 'V$value';
  }
}
