import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/account_session_coordinator.dart';
import 'package:fund_nexus/features/mine/widgets/account_panel_action.dart';

class AccountPanelDialog extends StatelessWidget {
  const AccountPanelDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('mine-account-panel'),
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: context.r(375),
        height: context.r(812),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: context.r(332),
              child: Container(
                width: context.r(343),
                height: context.r(28),
                padding: EdgeInsets.fromLTRB(
                  context.r(12),
                  context.r(8),
                  context.r(12),
                  context.r(8),
                ),
                decoration: BoxDecoration(
                  color: AppColors.mineAccountPanelAccent,
                  borderRadius: BorderRadius.circular(context.r(28)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.mineAccountPanelTop,
                    borderRadius: BorderRadius.circular(context.r(28)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: context.r(346),
              child: Container(
                width: context.r(319),
                height: context.r(134),
                padding: EdgeInsets.all(context.r(12)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(context.r(12)),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.mineAccountPanelStart,
                      AppColors.mineAccountPanelEnd,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    AccountPanelAction(
                      key: const Key('mine-account-log-out'),
                      label: 'Log out',
                      onPressed: () =>
                          Navigator.of(context).pop(AccountExitAction.logOut),
                    ),
                    SizedBox(height: context.r(12)),
                    AccountPanelAction(
                      key: const Key('mine-account-delete'),
                      label: 'Delete Account',
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(AccountExitAction.deleteAccount),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: context.r(496),
              child: Semantics(
                button: true,
                label: 'Close account panel',
                child: InkWell(
                  key: const Key('mine-account-panel-close'),
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(context.r(16)),
                  child: Image.asset(
                    AppAssets.mineAccountPanelClose,
                    width: context.r(32),
                    height: context.r(32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
