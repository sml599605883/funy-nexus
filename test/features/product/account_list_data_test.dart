import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/json/json.dart';
import 'package:fund_nexus/features/product/account/account_list_data.dart';

void main() {
  test(
    'parses account types, main selection, names, and maintenance state',
    () {
      final sections = parseAccountListSections(
        Json({
          'semihobos': [
            {
              'symptoms': 1,
              'unheralded': 'Bank',
              'mycetozoan': [
                {
                  'overadvertises': 42,
                  'counterexamples': 'https://cdn.test/bdo.png',
                  'clavier': 0,
                  'distasted': 'BDO',
                  'gossans': '5490',
                  'misadvises': {'axised': 'Anna'},
                  'sokols': 1,
                },
              ],
            },
          ],
        }),
      );

      expect(sections.single.title, 'Bank');
      final account = sections.single.accounts.single;
      expect(account.bindId, '42');
      expect(account.providerName, 'BDO');
      expect(account.accountValue, '5490');
      expect(account.firstName, 'Anna');
      expect(account.isMain, isTrue);
      expect(account.isUnderMaintenance, isTrue);
    },
  );
}
