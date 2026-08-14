import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class OrderStatusCard extends StatelessWidget {
  const OrderStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    const statuses = [
      _OrderStatus(asset: AppAssets.mineOrderAll, label: 'View All'),
      _OrderStatus(asset: AppAssets.mineOrderUnpaid, label: 'Unpaid'),
      _OrderStatus(asset: AppAssets.mineOrderLate, label: 'Late'),
      _OrderStatus(asset: AppAssets.mineOrderPaid, label: 'Paid'),
    ];

    return Container(
      key: const Key('mine-order-statuses'),
      height: context.r(95),
      padding: EdgeInsets.fromLTRB(
        context.r(18),
        context.r(18),
        context.r(26),
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
                  label: '${status.label} orders',
                  child: InkWell(
                    key: Key(
                      'mine-order-${status.label.toLowerCase().replaceAll(' ', '-')}',
                    ),
                    borderRadius: BorderRadius.circular(context.r(8)),
                    onTap: () {},
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
                                status.label,
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

class _OrderStatus {
  const _OrderStatus({required this.asset, required this.label});

  final String asset;
  final String label;
}
