import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class AccountPanelAction extends StatelessWidget {
  const AccountPanelAction({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.r(43),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.r(14),
            fontWeight: FontWeight.w700,
            height: 17 / 14,
          ),
        ),
      ),
    );
  }
}
