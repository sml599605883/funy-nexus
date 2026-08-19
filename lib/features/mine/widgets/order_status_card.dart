import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/progress/order_list_models.dart';

class OrderStatusCard extends StatelessWidget {
  const OrderStatusCard({super.key, this.onStatusTap});

  final ValueChanged<OrderListStatus>? onStatusTap;

  @override
  Widget build(BuildContext context) {
    const statuses = [
      (status: OrderListStatus.all, asset: AppAssets.mineOrderAll),
      (status: OrderListStatus.unpaid, asset: AppAssets.mineOrderUnpaid),
      (status: OrderListStatus.late, asset: AppAssets.mineOrderLate),
      (status: OrderListStatus.paid, asset: AppAssets.mineOrderPaid),
    ];

    return Container(
      key: const Key('mine-order-statuses'),
      height: context.r(95),
      padding: EdgeInsets.fromLTRB(
        context.r(18),
        context.r(18),
        context.r(18),
        context.r(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.mineOrderShadow,
            offset: Offset(0, 3),
            blurRadius: 9,
          ),
        ],
      ),
      child: Row(
        children: statuses
            .map(
              (status) => Expanded(
                child: Semantics(
                  button: true,
                  label: '${status.status.label} orders',
                  child: InkWell(
                    key: Key(
                      'mine-order-${status.status.label.toLowerCase().replaceAll(' ', '-')}',
                    ),
                    borderRadius: BorderRadius.circular(context.r(8)),
                    onTap: () => onStatusTap?.call(status.status),
                    child: LayoutBuilder(
                      builder: (context, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: context.r(50),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                status.asset,
                                width: context.r(33),
                                height: context.r(35),
                              ),
                              SizedBox(height: context.r(8)),
                              Text(
                                status.status.label,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: context.r(12),
                                  height: 18 / 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
