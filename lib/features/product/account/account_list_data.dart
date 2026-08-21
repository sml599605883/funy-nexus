import 'package:fund_nexus/core/json/json.dart';

class AccountListSection {
  AccountListSection({
    required this.type,
    required this.title,
    required this.accounts,
  });

  final String type;
  final String title;
  final List<AccountListItem> accounts;
}

class AccountListItem {
  const AccountListItem({
    required this.bindId,
    required this.logoUrl,
    required this.providerName,
    required this.accountValue,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.isMain,
    required this.isUnderMaintenance,
  });

  final String bindId;
  final String logoUrl;
  final String providerName;
  final String accountValue;
  final String firstName;
  final String middleName;
  final String lastName;
  final bool isMain;
  final bool isUnderMaintenance;
}

List<AccountListSection> parseAccountListSections(Json data) {
  final sections = <AccountListSection>[];
  for (final section in data['semihobos'].listValue) {
    final accounts = <AccountListItem>[];
    for (final account in section['mycetozoan'].listValue) {
      final bindId = account['overadvertises'].stringValue.trim();
      if (bindId.isEmpty) continue;
      final name = account['misadvises'];
      accounts.add(
        AccountListItem(
          bindId: bindId,
          logoUrl: account['counterexamples'].stringValue.trim(),
          providerName: account['distasted'].stringValue.trim(),
          accountValue: account['gossans'].stringValue.trim(),
          firstName: name['axised'].stringValue.trim(),
          middleName: name['pisiform'].stringValue.trim(),
          lastName: name['deferrable'].stringValue.trim(),
          isMain: _isOne(account['sokols']),
          isUnderMaintenance: _isZero(account['clavier']),
        ),
      );
    }
    if (accounts.isEmpty) continue;
    sections.add(
      AccountListSection(
        type: section['symptoms'].stringValue.trim(),
        title: section['unheralded'].stringValue.trim(),
        accounts: List.unmodifiable(accounts),
      ),
    );
  }
  return List.unmodifiable(sections);
}

bool _isOne(Json value) => value.numOrNull == 1 || value.stringValue == 'true';

bool _isZero(Json value) => value.numOrNull == 0;
