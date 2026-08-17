import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/widgets/account_panel_action.dart';

class GreenActionPanelDialog extends StatelessWidget {
  const GreenActionPanelDialog({
    this.firstLabel,
    this.secondLabel,
    this.onFirstPressed,
    this.onSecondPressed,
    this.actions,
    required this.closeSemanticLabel,
    this.dialogKey,
    this.firstActionKey,
    this.secondActionKey,
    this.closeKey,
    this.actionPanelHeight,
    super.key,
  }) : assert(
         actions != null ||
             (firstLabel != null &&
                 secondLabel != null &&
                 onFirstPressed != null &&
                 onSecondPressed != null),
         'Provide actions or the first and second action configuration.',
       );

  final String? firstLabel;
  final String? secondLabel;
  final VoidCallback? onFirstPressed;
  final VoidCallback? onSecondPressed;
  final List<Widget>? actions;
  final String closeSemanticLabel;
  final Key? dialogKey;
  final Key? firstActionKey;
  final Key? secondActionKey;
  final Key? closeKey;
  final double? actionPanelHeight;

  @override
  Widget build(BuildContext context) {
    final panelActions =
        actions ??
        [
          AccountPanelAction(
            key: firstActionKey,
            label: firstLabel!,
            onPressed: onFirstPressed!,
          ),
          SizedBox(height: context.r(12)),
          AccountPanelAction(
            key: secondActionKey,
            label: secondLabel!,
            onPressed: onSecondPressed!,
          ),
        ];
    final panelHeight = context.r(actionPanelHeight ?? 134);
    return Dialog(
      key: dialogKey,
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
                height: panelHeight,
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
                child: Column(children: panelActions),
              ),
            ),
            Positioned(
              top: context.r(346) + panelHeight + context.r(16),
              child: Semantics(
                button: true,
                label: closeSemanticLabel,
                child: InkWell(
                  key: closeKey,
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
