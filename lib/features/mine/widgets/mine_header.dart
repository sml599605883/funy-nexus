import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/mine_phone_formatter.dart';

class MineHeader extends StatelessWidget {
  const MineHeader({required this.phone, super.key});

  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: context.r(50),
          left: 0,
          right: 0,
          child: Text(
            'Mine',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: context.r(17),
              fontWeight: FontWeight.w600,
              height: 24 / 17,
            ),
          ),
        ),
        Positioned(
          top: context.r(112),
          left: context.r(16),
          child: Container(
            width: context.r(48),
            height: context.r(48),
            decoration: BoxDecoration(
              color: AppColors.mineAvatar,
              borderRadius: BorderRadius.circular(context.r(4)),
              border: Border.all(color: AppColors.surface),
            ),
          ),
        ),
        Positioned(
          top: context.r(124),
          left: context.r(76),
          child: Text(
            formatMinePhone(phone),
            key: const Key('mine-phone'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: context.r(20),
              fontWeight: FontWeight.w700,
              height: 25 / 20,
            ),
          ),
        ),
      ],
    );
  }
}
