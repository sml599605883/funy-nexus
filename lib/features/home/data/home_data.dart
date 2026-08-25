class HomeData {
  const HomeData({
    required this.hasSections,
    this.customerService,
    this.banners = const [],
    this.banner,
    this.primaryCard,
    this.progressItems = const [],
    this.recommendations = const [],
  });

  final bool hasSections;
  final HomeCustomerService? customerService;
  final List<HomeBannerData> banners;

  /// Retained for existing callers that need the first server banner.
  final HomeBannerData? banner;

  List<HomeBannerData> get promoBanners =>
      banners.isEmpty && banner != null ? [banner!] : banners;
  final HomeCardData? primaryCard;
  final List<HomeProgressItem> progressItems;
  final List<HomeRecommendationData> recommendations;

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
    final progressItems = <HomeProgressItem>[];
    final recommendations = <HomeRecommendationData>[];
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
      if (_progressTypes.contains(type)) {
        progressItems.addAll(
          items.map(HomeProgressItem.fromJson).whereType<HomeProgressItem>(),
        );
      }
      if (_productListTypes.contains(type)) {
        recommendations.addAll(
          items
              .map(HomeRecommendationData.fromJson)
              .whereType<HomeRecommendationData>(),
        );
      }
    }

    return HomeData(
      hasSections: sectionsValue.isNotEmpty,
      customerService: HomeCustomerService.fromJson(json['chippered']),
      banners: banners,
      banner: banners.isEmpty ? null : banners.first,
      primaryCard: primaryCard,
      progressItems: List.unmodifiable(progressItems),
      recommendations: List.unmodifiable(recommendations),
    );
  }

  static const _bannerTypes = {'BANNER', 'DonkeyCatch'};
  static const _largeCardTypes = {'Majordomo', 'Nonsteroidal'};
  static const _progressTypes = {'PROCESS_LIST', 'Acidulations'};
  static const _productListTypes = {'PRODUCT_LIST', 'Toolings'};
}

class HomeRecommendationData {
  const HomeRecommendationData({
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.amount,
    required this.amountLabel,
    required this.interestRate,
    required this.interestRateLabel,
    required this.loanTerm,
    required this.loanTermLabel,
    required this.highlights,
    required this.actionText,
    required this.buttonState,
  });

  final String productId;
  final String productName;
  final String productLogo;
  final String amount;
  final String amountLabel;
  final String interestRate;
  final String interestRateLabel;
  final String loanTerm;
  final String loanTermLabel;
  final List<String> highlights;
  final String actionText;
  final int buttonState;

  static HomeRecommendationData? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    final productId = _stringValue(json['ecclesia']);
    final productName = _stringValue(json['ritualize']);
    if (productId.isEmpty && productName.isEmpty) return null;

    return HomeRecommendationData(
      productId: productId,
      productName: productName,
      productLogo: _stringValue(json['typographies']),
      amount: _stringValue(json['apparentness']),
      amountLabel: _stringValue(json['remediation']),
      interestRate: _stringValue(json['bodied']),
      interestRateLabel: _stringValue(json['bravenesses']),
      loanTerm: _stringValue(json['pharmacognosy']),
      loanTermLabel: _stringValue(json['jordan']),
      highlights: List.unmodifiable(_stringList(json['wincer'])),
      actionText: _stringValue(json['soreness']),
      buttonState: _buttonState(json),
    );
  }
}

abstract final class HomeProgressState {
  static const unknown = 0;
  static const inReview = 1;
  static const activeLoan = 2;
  static const overdue = 3;
  static const disbursing = 4;
  static const disbursementFailed = 5;
  static const disbursementFailedAlternative = 6;
}

class HomeProgressItem {
  const HomeProgressItem({
    required this.orderNumber,
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.title,
    required this.amount,
    required this.amountLabel,
    required this.date,
    required this.dateLabel,
    required this.status,
    required this.statusLabel,
    required this.detailTarget,
    required this.actions,
  });

  final String orderNumber;
  final String productId;
  final String productName;
  final String productLogo;
  final String title;
  final String amount;
  final String amountLabel;
  final String date;
  final String dateLabel;
  final int status;
  final String statusLabel;
  final String detailTarget;
  final List<HomeProgressAction> actions;

  static HomeProgressItem? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    final productName = _stringValue(json['briarwoods']);
    final orderNumber = _stringValue(json['clipsheet']);
    if (productName.isEmpty && orderNumber.isEmpty) return null;

    final formattedAmount = _stringValue(json['endurances']);
    return HomeProgressItem(
      orderNumber: orderNumber,
      productId: _stringValue(json['modernised']),
      productName: productName,
      productLogo: _stringValue(json['soonest']),
      title: _stringValue(json['culinarians']),
      amount: formattedAmount.isEmpty
          ? _stringValue(json['breaststrokers'])
          : formattedAmount,
      amountLabel: _stringValue(json['apodoses']),
      date: _stringValue(json['psittacosis']),
      dateLabel: _stringValue(json['callboys']),
      status: _intValue(json['nightside']),
      statusLabel: _stringValue(json['bettor']),
      detailTarget: _stringValue(json['redepositing']),
      actions: List.unmodifiable(
        (json['suffocated'] is List ? json['suffocated'] as List : const [])
            .map(HomeProgressAction.fromJson)
            .whereType<HomeProgressAction>()
            .where((action) => action.visible),
      ),
    );
  }
}

class HomeProgressAction {
  const HomeProgressAction({
    required this.type,
    required this.visible,
    required this.label,
    required this.badge,
    required this.target,
  });

  final String type;
  final bool visible;
  final String label;
  final String badge;
  final String target;

  static HomeProgressAction? fromJson(Object? data) {
    if (data is! Map) return null;
    final json = _stringKeyedMap(data);
    return HomeProgressAction(
      type: _stringValue(json['etherifying']),
      visible: _intValue(json['mammoth']) == 1,
      label: _stringValue(json['exarchies']),
      badge: _stringValue(json['excludible']),
      target: _stringValue(json['toyish']),
    );
  }
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

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map(_stringValue)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

int _buttonState(Map<String, Object?> json) {
  final state = json['vrow'];
  return state == null ? _intValue(json['suborganization']) : _intValue(state);
}
