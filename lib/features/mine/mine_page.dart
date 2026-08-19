import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/mine/account_session_coordinator.dart';
import 'package:fund_nexus/features/mine/mine_phone_formatter.dart';
import 'package:fund_nexus/features/mine/widgets/account_panel_dialog.dart';
import 'package:fund_nexus/features/mine/widgets/account_retention_dialog.dart';
import 'package:fund_nexus/features/mine/widgets/mine_body.dart';
import 'package:fund_nexus/features/mine/widgets/mine_header.dart';
import 'package:fund_nexus/features/mine/widgets/order_status_card.dart';
import 'package:fund_nexus/features/progress/order_list_models.dart';
import 'package:fund_nexus/features/progress/order_list_page.dart';

typedef AccountExitHandler = Future<bool> Function(AccountExitAction action);
typedef AccountExitSuccessHandler = Future<void> Function();
typedef AccountExitMessageHandler = Future<void> Function(String message);

class MinePage extends StatelessWidget {
  const MinePage({
    this.phone,
    this.onAccountExit,
    this.onAccountExitSuccess,
    this.onCustomerService,
    this.showLoading,
    this.dismissLoading,
    this.showMessage,
    super.key,
  });

  final String? phone;
  final AccountExitHandler? onAccountExit;
  final AccountExitSuccessHandler? onAccountExitSuccess;
  final VoidCallback? onCustomerService;
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
      child: Column(
        children: [
          SizedBox(
            height: context.r(184),
            child: MineHeader(phone: displayPhone),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: context.r(19),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MineBody(
                    onAccountTap: () => _showAccountPanel(context),
                    onCustomerService: onCustomerService,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: context.r(16),
                  right: context.r(16),
                  child: OrderStatusCard(
                    onStatusTap: (status) => _openOrderList(context, status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String formatPhone(String? phone) {
    return formatMinePhone(phone);
  }

  Future<void> _showAccountPanel(BuildContext context) async {
    final action = await showDialog<AccountExitAction>(
      context: context,
      barrierColor: AppColors.mineDialogBarrier,
      builder: (_) => const AccountPanelDialog(),
    );
    if (action == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: AppColors.mineDialogBarrier,
      builder: (_) => AccountRetentionDialog(
        action: action,
        onConfirm: () => _handleAccountExit(context, action),
      ),
    );
  }

  Future<void> _openOrderList(
    BuildContext context,
    OrderListStatus status,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderListPage(initialStatus: status),
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
