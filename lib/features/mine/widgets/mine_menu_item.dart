import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class MineMenuItem extends StatelessWidget {
  const MineMenuItem({
    required this.iconAsset,
    required this.label,
    this.onTap,
    this.trailingLabel,
    this.showChevron = true,
    super.key,
  });

  final String iconAsset;
  final String label;
  final VoidCallback? onTap;
  final String? trailingLabel;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(context.r(8)),
        child: Container(
          height: context.r(56),
          padding: EdgeInsets.symmetric(horizontal: context.r(14)),
          decoration: BoxDecoration(
            color: AppColors.mineItemBackground,
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                width: context.r(20),
                height: context.r(20),
              ),
              SizedBox(width: context.r(14)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.mineItemText,
                    fontSize: context.r(14),
                    height: 20 / 14,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel!,
                  style: TextStyle(
                    color: AppColors.mineItemValue,
                    fontSize: context.r(12),
                    height: 17 / 12,
                  ),
                ),
                SizedBox(width: context.r(8)),
              ],
              if (showChevron)
                Image.asset(
                  AppAssets.mineChevron,
                  width: context.r(6),
                  height: context.r(10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
