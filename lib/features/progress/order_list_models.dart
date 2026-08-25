import 'package:fund_nexus/core/json/json.dart';

enum OrderListStatus {
  all('4', 'View All'),
  unpaid('7', 'Unpaid'),
  late('6', 'Late'),
  paid('5', 'Paid');

  const OrderListStatus(this.code, this.label);

  final String code;
  final String label;

  static OrderListStatus fromCode(String? code) => values.firstWhere(
    (status) => status.code == code?.trim(),
    orElse: () => OrderListStatus.all,
  );
}

class OrderListItem {
  const OrderListItem({
    required this.orderId,
    required this.orderNumber,
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.statusCode,
    required this.statusText,
    required this.amountText,
    required this.amountLabel,
    required this.actionText,
    required this.legacyTarget,
    required this.dateLabel,
    required this.dateValue,
    required this.overdueDays,
    required this.cardTarget,
    required this.actionTarget,
    required this.supportsEarlyRepay,
    required this.earlyRepayLabel,
    required this.earlyRepayTarget,
  });

  factory OrderListItem.fromJson(Json json) => OrderListItem(
    orderId: json['incarcerates'].stringValue.trim(),
    orderNumber: json['readjusts'].stringValue.trim(),
    productId: json['pesters'].stringValue.trim(),
    productName: json['ritualize'].stringValue.trim(),
    productLogo: json['typographies'].stringValue.trim(),
    statusCode: json['tarsal'].numValue.toInt(),
    statusText: json['blunter'].stringValue.trim(),
    amountText: json['breaststrokers'].stringValue.trim(),
    amountLabel: json['haunted'].stringValue.trim(),
    actionText: json['soreness'].stringValue.trim(),
    legacyTarget: json['unreserve'].stringValue.trim(),
    dateLabel: json['casebooks'].stringValue.trim(),
    dateValue: json['jiggiest'].stringValue.trim(),
    overdueDays: json['knouting'].numValue.toInt(),
    cardTarget: json['prudishnesses'].stringValue.trim(),
    actionTarget: json['circinate'].stringValue.trim(),
    supportsEarlyRepay: json['outrushing'].value == true,
    earlyRepayLabel: json['agrestal'].stringValue.trim(),
    earlyRepayTarget: json['berrylike'].stringValue.trim(),
  );

  final String orderId;
  final String orderNumber;
  final String productId;
  final String productName;
  final String productLogo;
  final int statusCode;
  final String statusText;
  final String amountText;
  final String amountLabel;
  final String actionText;
  final String legacyTarget;
  final String dateLabel;
  final String dateValue;
  final int overdueDays;
  final String cardTarget;
  final String actionTarget;
  final bool supportsEarlyRepay;
  final String earlyRepayLabel;
  final String earlyRepayTarget;

  bool get hasAction => statusCode == 180 || statusCode == 174;
  bool get isOverdue => statusText.toLowerCase().contains('overdue');
}

List<OrderListItem> parseOrderListItems(Json states) => states['semihobos']
    .listValue
    .map(OrderListItem.fromJson)
    .toList(growable: false);
