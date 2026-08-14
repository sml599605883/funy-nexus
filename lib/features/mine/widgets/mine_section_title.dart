import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class MineSectionTitle extends StatelessWidget {
  const MineSectionTitle({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppAssets.mineSectionTitleMarker,
          width: context.r(22),
          height: context.r(22),
        ),
        SizedBox(width: context.r(4)),
        Text(
          label,
          style: TextStyle(
            color: AppColors.mineSectionTitle,
            fontSize: context.r(16),
            fontWeight: FontWeight.w700,
            height: 19 / 16,
          ),
        ),
      ],
    );
  }
}
