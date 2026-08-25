import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/json/json.dart';
import 'package:fund_nexus/features/progress/order_list_models.dart';

void main() {
  test('parses the documented order item and targets', () {
    final item = OrderListItem.fromJson(
      Json({
        'incarcerates': 4,
        'readjusts': 'ORDER-4',
        'pesters': 1,
        'ritualize': 'PG Finance',
        'typographies': 'https://cdn.test/logo.png',
        'tarsal': 180,
        'blunter': 'Overdue',
        'breaststrokers': 'PHP 20,000.00',
        'haunted': 'Available up to',
        'soreness': 'Repay Now',
        'unreserve': '/legacy',
        'casebooks': 'Due Date',
        'jiggiest': '29-11-2023',
        'knouting': 2,
        'prudishnesses': '/order/detail?orderId=4',
        'circinate': '/repayment-detail?orderNo=ORDER-4',
        'outrushing': true,
        'agrestal': '16% Off',
        'berrylike': '/repay/early',
      }),
    );

    expect(item.orderId, '4');
    expect(item.productName, 'PG Finance');
    expect(item.statusText, 'Overdue');
    expect(item.actionTarget, '/repayment-detail?orderNo=ORDER-4');
    expect(item.cardTarget, '/order/detail?orderId=4');
    expect(item.hasAction, isTrue);
    expect(item.isOverdue, isTrue);
    expect(item.supportsEarlyRepay, isTrue);
  });

  test('shows repayment action only for repayment statuses', () {
    final repayStatuses = [180, 174];
    for (final status in repayStatuses) {
      final item = OrderListItem.fromJson(
        Json({'tarsal': status, 'soreness': '', 'circinate': ''}),
      );
      expect(item.hasAction, isTrue);
    }

    final nonRepayItem = OrderListItem.fromJson(
      Json({'tarsal': 7, 'soreness': 'Repay Now', 'circinate': '/repay'}),
    );
    expect(nonRepayItem.hasAction, isFalse);
  });

  test('maps status codes and the documented list envelope', () {
    expect(OrderListStatus.fromCode('7'), OrderListStatus.unpaid);
    expect(OrderListStatus.fromCode('unknown'), OrderListStatus.all);
    expect(
      parseOrderListItems(
        Json({
          'semihobos': [
            {'ritualize': 'PG Finance'},
          ],
        }),
      ),
      hasLength(1),
    );
  });
}
