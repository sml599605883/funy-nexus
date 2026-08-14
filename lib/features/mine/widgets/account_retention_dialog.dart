import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/account_session_coordinator.dart';

class AccountRetentionDialog extends StatefulWidget {
  const AccountRetentionDialog({
    required this.action,
    required this.onConfirm,
    super.key,
  });

  final AccountExitAction action;
  final Future<bool> Function() onConfirm;

  @override
  State<AccountRetentionDialog> createState() => _AccountRetentionDialogState();
}

class _AccountRetentionDialogState extends State<AccountRetentionDialog> {
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final succeeded = await widget.onConfirm();
    if (!mounted) return;
    if (succeeded) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogOut = widget.action == AccountExitAction.logOut;
    final dialogAsset = isLogOut
        ? AppAssets.mineLogoutRetentionDialog
        : AppAssets.mineDeleteAccountRetentionDialog;

    return Dialog(
      key: Key(
        isLogOut
            ? 'mine-logout-retention-dialog'
            : 'mine-delete-account-retention-dialog',
      ),
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: context.r(375),
        height: context.r(812),
        child: Stack(
          children: [
            Positioned(
              top: context.r(156),
              left: 0,
              right: 0,
              child: Image.asset(
                dialogAsset,
                width: context.r(375),
                height: context.r(500),
              ),
            ),
            Positioned(
              top: context.r(463),
              left: context.r(64),
              child: SizedBox(
                width: context.r(247),
                height: context.r(40),
                child: TextButton(
                  key: const Key('mine-retention-continue'),
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style:
                      TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.mineRetentionContinueText,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(20)),
                        ),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.all(
                          AppColors.mineRetentionContinueStart,
                        ),
                      ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.mineRetentionContinueStart,
                          AppColors.mineRetentionContinueEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(context.r(20)),
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: AppColors.mineRetentionContinueText,
                          fontSize: context.r(15),
                          fontWeight: FontWeight.w700,
                          height: 18 / 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: context.r(515),
              left: context.r(64),
              child: SizedBox(
                width: context.r(247),
                height: context.r(30),
                child: TextButton(
                  key: const Key('mine-retention-exit'),
                  onPressed: _submitting ? null : _confirm,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mineRetentionExitText,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Exit',
                    style: TextStyle(
                      fontSize: context.r(15),
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                    ),
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
