import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/json/json.dart';
import 'package:fund_nexus/features/main_shell/home_popup_data.dart';

void main() {
  test('parses the documented app upgrade popup', () {
    final data = HomePopupData.fromResponse(
      Json({
        'etherifying': 1,
        'leapt': {
          'stookers': '1.1.4',
          'heliacally': 'New version is now available',
          'redepositing': 'https://store.example.test/app',
        },
      }),
    );

    expect(data.type, HomePopupType.appUpgrade);
    expect(data.displayVersion, 'V1.1.4');
    expect(data.message, 'New version is now available');
    expect(data.targetUrl, 'https://store.example.test/app');
  });

  test('keeps membership and marketing types available for later UI work', () {
    expect(
      HomePopupData.fromResponse(Json({'etherifying': 2})).type,
      HomePopupType.membershipUpgrade,
    );
    expect(
      HomePopupData.fromResponse(Json({'etherifying': 3})).type,
      HomePopupType.marketing,
    );
  });

  test(
    'parses marketing image and target and only shows when image exists',
    () {
      final data = HomePopupData.fromResponse(
        Json({
          'etherifying': 3,
          'leapt': {
            'zymometer': ' https://cdn.example.test/promo.png ',
            'redepositing': 'https://example.test/promo',
          },
        }),
      );

      expect(data.imageUrl, 'https://cdn.example.test/promo.png');
      expect(data.targetUrl, 'https://example.test/promo');
      expect(data.shouldShow, isTrue);
      expect(
        HomePopupData.fromResponse(
          Json({
            'etherifying': 3,
            'leapt': {'zymometer': ''},
          }),
        ).shouldShow,
        isFalse,
      );
    },
  );
}
