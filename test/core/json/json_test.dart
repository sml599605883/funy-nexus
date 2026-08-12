import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/json/json.dart';

void main() {
  test('reads typed values from map and list data', () {
    final json = Json({
      'name': 'iPhoneXR',
      'screen': '6.1',
      'items': [1],
    });

    expect(json['name'].stringValue, 'iPhoneXR');
    expect(json['screen'].doubleValue, 6.1);
    expect(json['items'][0].numValue, 1);
  });
}
