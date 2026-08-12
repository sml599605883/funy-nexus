import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/mine/account_session_coordinator.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

typedef AccountExitHandler = Future<bool> Function(AccountExitAction action);
typedef AccountExitSuccessHandler = Future<void> Function();
typedef AccountExitMessageHandler = Future<void> Function(String message);

class MinePage extends StatelessWidget {
  const MinePage({
    this.phone,
    this.onAccountExit,
    this.onAccountExitSuccess,
    this.showLoading,
    this.dismissLoading,
    this.showMessage,
    super.key,
  });

  final String? phone;
  final AccountExitHandler? onAccountExit;
  final AccountExitSuccessHandler? onAccountExitSuccess;
  final Future<void> Function()? showLoading;
  final Future<void> Function()? dismissLoading;
  final AccountExitMessageHandler? showMessage;

  @override
  Widget build(BuildContext context) {
    final displayPhone = phone ?? context.read<SessionStore>().phone;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.homeHeaderStart, AppColors.homeHeaderEnd],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _MineHeader(phone: displayPhone),
          Positioned(
            top: context.r(203),
            left: 0,
            right: 0,
            bottom: 0,
            child: _MineBody(onAccountTap: () => _showAccountPanel(context)),
          ),
          Positioned(
            top: context.r(184),
            left: context.r(16),
            right: context.r(16),
            child: const _OrderStatusCard(),
          ),
        ],
      ),
    );
  }

  static String formatPhone(String? phone) {
    final value = phone?.trim() ?? '';
    if (value.length <= 7) return value;
    return '${value.substring(0, 3)} **** ${value.substring(value.length - 4)}';
  }

  Future<void> _showAccountPanel(BuildContext context) async {
    final action = await showDialog<AccountExitAction>(
      context: context,
      barrierColor: AppColors.mineDialogBarrier,
      builder: (_) => const _AccountPanelDialog(),
    );
    if (action == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: AppColors.mineDialogBarrier,
      builder: (_) => _AccountRetentionDialog(
        action: action,
        onConfirm: () => _handleAccountExit(context, action),
      ),
    );
  }

  Future<bool> _handleAccountExit(
    BuildContext context,
    AccountExitAction action,
  ) async {
    try {
      await (showLoading ?? _defaultShowLoading)();
      final succeeded =
          await (onAccountExit ??
              (action) async {
                await AccountSessionCoordinator(
                  apiClient: context.read<ApiClient>(),
                  sessionStore: context.read<SessionStore>(),
                ).execute(action);
                return true;
              })(action);
      if (!succeeded) return false;
      await onAccountExitSuccess?.call();
      return true;
    } catch (error) {
      await (showMessage ?? _defaultShowMessage)(_messageFor(error));
      return false;
    } finally {
      await (dismissLoading ?? _defaultDismissLoading)();
    }
  }

  static Future<void> _defaultShowLoading() =>
      EasyLoading.show(status: 'Loading...');

  static Future<void> _defaultDismissLoading() => EasyLoading.dismiss();

  static Future<void> _defaultShowMessage(String message) =>
      EasyLoading.showError(message);

  static String _messageFor(Object error) {
    return error is ApiException ? error.message : 'Unexpected request error';
  }
}

class _MineHeader extends StatelessWidget {
  const _MineHeader({required this.phone});

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
            MinePage.formatPhone(phone),
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

class _MineBody extends StatelessWidget {
  const _MineBody({required this.onAccountTap});

  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(12)),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.r(16),
          context.r(100),
          context.r(16),
          context.r(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(label: 'Customer Service'),
            SizedBox(height: context.r(12)),
            _MineMenuItem(
              key: const Key('mine-customer-service'),
              iconAsset: AppAssets.mineCustomerService,
              label: 'Smart customer service',
            ),
            SizedBox(height: context.r(16)),
            const _SectionTitle(label: 'About Us'),
            SizedBox(height: context.r(12)),
            const _MineMenuItem(
              key: Key('mine-website'),
              iconAsset: AppAssets.mineWebsite,
              label: 'Website',
            ),
            SizedBox(height: context.r(8)),
            const _MineMenuItem(
              key: Key('mine-app-version'),
              iconAsset: AppAssets.mineAppVersion,
              label: 'APP Version',
            ),
            SizedBox(height: context.r(8)),
            const _MineMenuItem(
              key: Key('mine-privacy-agreement'),
              iconAsset: AppAssets.minePrivacyAgreement,
              label: 'Privacy Agreement',
            ),
            SizedBox(height: context.r(8)),
            _MineMenuItem(
              key: Key('mine-account'),
              iconAsset: AppAssets.mineAccount,
              label: 'Account',
              onTap: onAccountTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard();

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
                      builder: (context, constraints) => FittedBox(
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

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

class _MineMenuItem extends StatelessWidget {
  const _MineMenuItem({
    required this.iconAsset,
    required this.label,
    this.onTap,
    super.key,
  });

  final String iconAsset;
  final String label;
  final VoidCallback? onTap;

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

class _AccountPanelDialog extends StatelessWidget {
  const _AccountPanelDialog();

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
                    _AccountPanelAction(
                      key: const Key('mine-account-log-out'),
                      label: 'Log out',
                      onPressed: () =>
                          Navigator.of(context).pop(AccountExitAction.logOut),
                    ),
                    SizedBox(height: context.r(12)),
                    _AccountPanelAction(
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

class _AccountPanelAction extends StatelessWidget {
  const _AccountPanelAction({
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

class _AccountRetentionDialog extends StatefulWidget {
  const _AccountRetentionDialog({
    required this.action,
    required this.onConfirm,
  });

  final AccountExitAction action;
  final Future<bool> Function() onConfirm;

  @override
  State<_AccountRetentionDialog> createState() =>
      _AccountRetentionDialogState();
}

class _AccountRetentionDialogState extends State<_AccountRetentionDialog> {
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
