class HomeData {
  const HomeData({
    required this.hasSections,
    this.customerService,
    this.banners = const [],
    this.banner,
    this.primaryCard,
  });

  final bool hasSections;
  final HomeCustomerService? customerService;
  final List<HomeBannerData> banners;

  /// Retained for existing callers that need the first server banner.
  final HomeBannerData? banner;

  List<HomeBannerData> get promoBanners =>
      banners.isEmpty && banner != null ? [banner!] : banners;
  final HomeCardData? primaryCard;

  bool get isEmpty => !hasSections;

  factory HomeData.fromJson(Object? data) {
    if (data is! Map) {
      throw const FormatException('Home data must be a JSON object');
    }
    final json = _stringKeyedMap(data);
    final sectionsValue = json['semihobos'];
    if (sectionsValue is! List) {
      throw const FormatException('Home sections must be a JSON array');
    }

    List<HomeBannerData> banners = const [];
    HomeCardData? primaryCard;
    for (final sectionValue in sectionsValue) {
      if (sectionValue is! Map) continue;
      final section = _stringKeyedMap(sectionValue);
      final type = _stringValue(section['etherifying']);
      final items = section['mycetozoan'];
      if (items is! List || items.isEmpty) continue;

      if (banners.isEmpty && _bannerTypes.contains(type)) {
        banners = items
            .map(HomeBannerData.fromJson)
            .whereType<HomeBannerData>()
            .toList(growable: false);
      }
      if (primaryCard == null && _largeCardTypes.contains(type)) {
        primaryCard = HomeCardData.fromJson(items.first);
      }
    }

    return HomeData(
      hasSections: sectionsValue.isNotEmpty,
      customerService: HomeCustomerService.fromJson(json['chippered']),
      banners: banners,
      banner: banners.isEmpty ? null : banners.first,
      primaryCard: primaryCard,
    );
  }

  static const _bannerTypes = {'BANNER', 'DonkeyCatch'};
  static const _largeCardTypes = {'LARGE_CARD', 'Majordomo'};
}

class HomeCustomerService {
  const HomeCustomerService({required this.iconUrl, required this.target});

  final String iconUrl;
  final String target;

  static HomeCustomerService? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    return HomeCustomerService(
      iconUrl: _stringValue(json['requiems']),
      target: _stringValue(json['externalising']),
    );
  }
}

class HomeBannerData {
  const HomeBannerData({
    required this.id,
    required this.target,
    required this.imageUrl,
  });

  final String id;
  final String target;
  final String imageUrl;

  static HomeBannerData? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    return HomeBannerData(
      id: _stringValue(json['ecclesia']),
      target: _stringValue(json['redepositing']),
      imageUrl: _stringValue(json['closets']),
    );
  }
}

class HomeCardData {
  const HomeCardData({
    required this.productId,
    required this.productName,
    this.productLogo = '',
    required this.amount,
    required this.amountLabel,
    required this.loanTerm,
    required this.loanTermLabel,
    required this.interestRate,
    required this.interestRateLabel,
    required this.description,
    required this.actionText,
    this.certificationCompleted = 0,
    this.receiptAccount = '',
    this.receiptAccountLabel = '',
    this.certificationProgress = const [],
    this.loanTermRows = const [],
    this.loanTermIcon = '',
    this.interestRateIcon = '',
  });

  final String productId;
  final String productName;
  final String productLogo;
  final String amount;
  final String amountLabel;
  final String loanTerm;
  final String loanTermLabel;
  final String interestRate;
  final String interestRateLabel;
  final String description;
  final String actionText;
  final int certificationCompleted;
  final String receiptAccount;
  final String receiptAccountLabel;
  final List<HomeCardProgressItem> certificationProgress;
  final List<HomeCardLoanTermRow> loanTermRows;
  final String loanTermIcon;
  final String interestRateIcon;

  static HomeCardData? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    return HomeCardData(
      productId: _stringValue(json['ecclesia']),
      productName: _stringValue(json['ritualize']),
      productLogo: _stringValue(json['typographies']),
      amount: _stringValue(json['apparentness']),
      amountLabel: _stringValue(json['remediation']),
      loanTerm: _stringValue(json['pharmacognosy']),
      loanTermLabel: _stringValue(json['hoblike']),
      interestRate: _stringValue(json['filthier']),
      interestRateLabel: _stringValue(json['bravenesses']),
      description: _stringValue(json['uremia']),
      actionText: _stringValue(json['soreness']),
      certificationCompleted: _intValue(json['crisscrossing']),
      receiptAccount: _stringValue(json['gossans']),
      receiptAccountLabel: _stringValue(json['painters']),
      certificationProgress: _progressItems(json['vicarious']),
      loanTermRows: _loanTermRows(json['chubbily']),
      loanTermIcon: _stringValue(json['waul']),
      interestRateIcon: _stringValue(json['shades']),
    );
  }
}

class HomeCardProgressItem {
  const HomeCardProgressItem({
    required this.title,
    required this.amount,
    required this.selected,
  });

  final String title;
  final String amount;
  final int selected;

  static HomeCardProgressItem? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    return HomeCardProgressItem(
      title: _stringValue(json['culinarians']),
      amount: _stringValue(json['geometers']),
      selected: _intValue(json['myasthenias']),
    );
  }
}

class HomeCardLoanTermRow {
  const HomeCardLoanTermRow({
    required this.period,
    required this.label,
    required this.interestRate,
  });

  final String period;
  final String label;
  final String interestRate;

  static HomeCardLoanTermRow? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    return HomeCardLoanTermRow(
      period: _stringValue(json['astrict']),
      label: _stringValue(json['pigeonwing']),
      interestRate: _stringValue(json['filthier']),
    );
  }
}

List<HomeCardProgressItem> _progressItems(Object? data) {
  if (data is! List) return const [];
  return data
      .map(HomeCardProgressItem.fromJson)
      .whereType<HomeCardProgressItem>()
      .toList(growable: false);
}

List<HomeCardLoanTermRow> _loanTermRows(Object? data) {
  if (data is! List) return const [];
  return data
      .map(HomeCardLoanTermRow.fromJson)
      .whereType<HomeCardLoanTermRow>()
      .toList(growable: false);
}

Map<String, Object?> _stringKeyedMap(Map<Object?, Object?> data) {
  return <String, Object?>{
    for (final entry in data.entries) entry.key.toString(): entry.value,
  };
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';

int _intValue(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
