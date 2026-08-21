import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/data/bind_card_data.dart';

void main() {
  test('reads the bound account id from the response payload or envelope', () {
    expect(
      BindCardSubmitResult.fromJson(const {'overadvertises': '5'}, '00').bindId,
      '5',
    );
    expect(
      BindCardSubmitResult.fromJson(const {
        'foresight': {'overadvertises': '5'},
      }, '00').bindId,
      '5',
    );
  });

  test('parses dynamic bank fields and their channel values', () {
    final data = BindCardData.fromJson({
      'foresight': {
        'orographical': [
          {
            'culinarians': 'Bank',
            'etherifying': 2,
            'orographical': [
              {
                'culinarians': 'Select your recipient bank',
                'fasciitis': 'channelCode',
                'must': 'Please select',
                'presentableness': 'Coprince',
                'rubicund': [
                  {
                    'emit': 'Banco de Oro',
                    'etherifying': 'BDO',
                    'counterexamples': 'https://example.com/bdo.png',
                    'clavier': 1,
                    'joust': '',
                  },
                  {
                    'emit': 'GCash',
                    'etherifying': 'GCASH',
                    'counterexamples': 'https://example.com/gcash.png',
                    'clavier': 0,
                    'joust': 'Under maintenance.',
                  },
                ],
                'lambadas': 0,
              },
              {
                'culinarians': 'Bank Account',
                'fasciitis': 'cardNo',
                'must': 'Please enter your bank account',
                'presentableness': 'txt',
                'rubicund': [],
                'lambadas': 0,
                'pavilion': '0123456789',
              },
            ],
          },
        ],
        'cornbraids': 'Choose an account.',
        'zebroid': 'Check it carefully.',
      },
    });

    expect(data.topPrompt, 'Choose an account.');
    expect(data.bottomPrompt, 'Check it carefully.');
    expect(data.groups.single.type, '2');
    expect(data.groups.single.fields.first.control, BindCardControl.selection);
    expect(data.groups.single.fields.first.options.first.value, 'BDO');
    expect(
      data.groups.single.fields.first.options.first.maintenanceMessage,
      isEmpty,
    );
    expect(
      data.groups.single.fields.first.options.first.logoUrl,
      'https://example.com/bdo.png',
    );
    expect(
      data.groups.single.fields.first.options.last.maintenanceMessage,
      'Under maintenance.',
    );
    expect(data.groups.single.fields.first.options.first.available, isTrue);
    expect(data.groups.single.fields.first.options.last.available, isFalse);
    expect(data.groups.single.fields.last.suggestedValue, '0123456789');
  });
}
