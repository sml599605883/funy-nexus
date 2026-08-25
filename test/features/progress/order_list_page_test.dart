import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/json/json.dart';
import 'package:fund_nexus/features/progress/order_list_models.dart';
import 'package:fund_nexus/features/progress/order_list_page.dart';

void main() {
  testWidgets('renders empty state and requests the selected filter', (
    tester,
  ) async {
    final statuses = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderListPage(
          loadOrders: (status) async {
            statuses.add(status);
            return const [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(statuses, ['4']);
    expect(find.text('Loan List'), findsOneWidget);
    expect(find.text('No information available'), findsOneWidget);
    expect(find.byKey(const Key('order-empty-image')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('order-tab-6')));
    await tester.pumpAndSettle();
    expect(statuses, ['4', '6']);
  });

  testWidgets('renders order cards and action target', (tester) async {
    final item = OrderListItem.fromJson(
      Json({
        'incarcerates': 4,
        'ritualize': 'PG Finance',
        'tarsal': 174,
        'blunter': 'Outstanding',
        'breaststrokers': 'PHP 20,000.00',
        'haunted': 'Available up to',
        'soreness': 'Server-provided copy',
        'jiggiest': '29-11-2023',
        'casebooks': 'Due Date',
        'circinate': '/repayment-detail?orderNo=ORDER-4',
      }),
    );
    final page = OrderListPage(loadOrders: (_) async => [item]);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('order-card-4')), findsOneWidget);
    expect(find.text('PG Finance'), findsOneWidget);
    expect(find.text('Repay Now'), findsOneWidget);
    expect(find.text('Server-provided copy'), findsNothing);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(
      button.style?.backgroundColor?.resolve({}),
      AppColors.orderRepayActive,
    );
  });

  testWidgets('shows repayment buttons only for statuses 180 and 174', (
    tester,
  ) async {
    OrderListItem item(int orderId, int status) => OrderListItem(
      orderId: '$orderId',
      orderNumber: 'ORDER-$orderId',
      productId: 'PRODUCT-$orderId',
      productName: 'Product $orderId',
      productLogo: '',
      statusCode: status,
      statusText: 'Status',
      amountText: 'PHP 1,000.00',
      amountLabel: 'Amount',
      actionText: 'Ignored server copy',
      legacyTarget: '',
      dateLabel: 'Due Date',
      dateValue: '29-11-2023',
      overdueDays: 0,
      cardTarget: '',
      actionTarget: '/repay/$orderId',
      supportsEarlyRepay: false,
      earlyRepayLabel: '',
      earlyRepayTarget: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrderListPage(
          loadOrders: (_) async => [item(180, 180), item(174, 174), item(7, 7)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.text('Repay Now'), findsNWidgets(2));
    final buttons = tester.widgetList<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(
      buttons.elementAt(0).style?.backgroundColor?.resolve({}),
      AppColors.orderOverdue,
    );
    expect(
      buttons.elementAt(1).style?.backgroundColor?.resolve({}),
      AppColors.orderRepayActive,
    );
  });

  testWidgets('dismisses request loading after the latest response', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderListPage(
          showLoading: () async => events.add('show'),
          dismissLoading: () async => events.add('dismiss'),
          loadOrders: (_) async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(events, ['show', 'dismiss']);
  });
}
