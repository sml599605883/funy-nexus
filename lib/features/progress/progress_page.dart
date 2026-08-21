import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/state/async_state.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/login/login_page.dart';
import 'package:fund_nexus/features/product/account/account_list_page.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/credit_review/credit_review_page.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _actionRequesting = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, AsyncState<HomeData>>(
      builder: (context, state) {
        final previousData = switch (state) {
          AsyncLoading<HomeData>(:final previousData) => previousData,
          AsyncFailure<HomeData>(:final previousData) => previousData,
          _ => null,
        };
        final data = switch (state) {
          AsyncData<HomeData>(:final data) => data,
          _ => previousData,
        };
        return _ProgressContent(
          items: data?.progressItems ?? const [],
          isLoading:
              state is AsyncInitial<HomeData> ||
              (state is AsyncLoading<HomeData> && data == null),
          error: state is AsyncFailure<HomeData> && data == null,
          onRefresh: context.read<HomeCubit>().load,
          onItemTap: _handleProgressTap,
          onActionTap: _handleProgressActionTap,
        );
      },
    );
  }

  Future<void> _handleProgressTap(HomeProgressItem item) async {
    if (_actionRequesting) return;
    final productId = item.productId.trim();
    final target = item.detailTarget.trim();
    if (productId.isEmpty && target.isEmpty) return;

    _actionRequesting = true;
    try {
      if (target.isNotEmpty) {
        await _openProgressTarget(target);
      } else {
        await _applyProduct(productId);
      }
    } finally {
      _actionRequesting = false;
    }
  }

  Future<void> _handleProgressActionTap(
    HomeProgressItem item,
    HomeProgressAction action,
  ) async {
    if (_actionRequesting) return;
    switch (action.type.trim().toLowerCase()) {
      case 'detail':
      case 'fallback':
      case 'repay':
        await _handleProgressTap(item);
        return;
      case 'retry':
        await _retryProgress(item);
        return;
      case 'change':
        await _changeProgressAccount(item);
        return;
      default:
        return;
    }
  }

  Future<void> _retryProgress(HomeProgressItem item) async {
    final orderNumber = item.orderNumber.trim();
    if (orderNumber.isEmpty || _actionRequesting) return;
    _actionRequesting = true;
    var loadingVisible = false;
    final apiClient = context.read<ApiClient>();
    try {
      await EasyLoading.show(status: 'Loading...');
      loadingVisible = true;
      final response = await apiClient.retryProgressOrder(
        orderNumber: orderNumber,
      );
      final target = response.data['topical'].stringValue.trim();
      if (target.isEmpty) {
        throw const ApiException(
          type: ApiFailureType.business,
          message: 'Unable to retry this order.',
        );
      }
      await EasyLoading.dismiss(animation: false);
      loadingVisible = false;
      await _openProgressTarget(target);
    } catch (error) {
      if (loadingVisible) await EasyLoading.dismiss(animation: false);
      if (mounted) _showProgressMessage(_messageFor(error));
    } finally {
      _actionRequesting = false;
    }
  }

  Future<void> _changeProgressAccount(HomeProgressItem item) async {
    final productId = item.productId.trim();
    final orderNumber = item.orderNumber.trim();
    if (productId.isEmpty || orderNumber.isEmpty || _actionRequesting) return;
    _actionRequesting = true;
    var loadingVisible = false;
    try {
      await EasyLoading.show(status: 'Loading...');
      loadingVisible = true;
      await EasyLoading.dismiss(animation: false);
      loadingVisible = false;
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              AccountListPage(productId: productId, orderNumber: orderNumber),
        ),
      );
    } catch (error) {
      if (loadingVisible) await EasyLoading.dismiss(animation: false);
      if (mounted) _showProgressMessage(_messageFor(error));
    } finally {
      _actionRequesting = false;
    }
  }

  Future<void> _openProgressTarget(String target) async {
    final uri = ProductWebPage.validUri(target);
    if (uri == null) {
      _showProgressMessage('Unable to open the requested page.');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductWebPage(url: uri.toString()),
      ),
    );
  }

  Future<void> _applyProduct(String productId) {
    return context.read<ProductApplicationFlow>().apply(
      productId: productId,
      openLogin: (_) async {
        if (!mounted) return false;
        final startedAt = ReportService.nowSeconds();
        final reportService = context.read<ReportService>();
        return await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => LoginPage(
                  onLoginSuccess: () async {
                    await reportService.loginSucceeded(
                      riskStartedAtSeconds: startedAt,
                    );
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
            ) ??
            false;
      },
      openTarget: _openProgressTarget,
      openCreditReview: (_) async {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CreditReviewPage(productId: productId),
          ),
        );
      },
      openCertification: (step, nextProductId) async {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                CertificationHandoffPage(productId: nextProductId, step: step),
          ),
        );
      },
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: () => EasyLoading.dismiss(animation: false),
      showMessage: (message) async => _showProgressMessage(message),
    );
  }

  void _showProgressMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) =>
      error is ApiException ? error.message : 'Unable to complete this action.';
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onItemTap,
    required this.onActionTap,
  });

  final List<HomeProgressItem> items;
  final bool isLoading;
  final bool error;
  final Future<void> Function() onRefresh;
  final ValueChanged<HomeProgressItem> onItemTap;
  final void Function(HomeProgressItem, HomeProgressAction) onActionTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.progressBackgroundStart,
            AppColors.progressBackgroundEnd,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _ProgressTitle()),
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ProgressError(onRetry: onRefresh),
                )
              else if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ProgressEmptyState(),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    context.r(16),
                    context.r(17),
                    context.r(16),
                    context.r(24),
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    itemBuilder: (context, index) => _ProgressCard(
                      item: items[index],
                      onTap: () => onItemTap(items[index]),
                      onActionTap: (action) =>
                          onActionTap(items[index], action),
                    ),
                    separatorBuilder: (_, _) => SizedBox(height: context.r(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressTitle extends StatelessWidget {
  const _ProgressTitle();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(64),
    child: Center(
      child: Text(
        'progress',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: context.r(17),
          fontWeight: FontWeight.w600,
          height: 24 / 17,
        ),
      ),
    ),
  );
}

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        AppAssets.progressEmpty,
        key: const Key('progress-empty-image'),
        width: context.r(138),
        height: context.r(102),
        fit: BoxFit.contain,
      ),
      SizedBox(height: context.r(13)),
      Text(
        'No progress yet',
        style: TextStyle(
          color: AppColors.homeValue,
          fontSize: context.r(14),
          height: 18 / 14,
        ),
      ),
    ],
  );
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      key: const Key('progress-load-retry'),
      onPressed: onRetry,
      child: const Text('Retry'),
    ),
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.item,
    required this.onTap,
    required this.onActionTap,
  });

  final HomeProgressItem item;
  final VoidCallback onTap;
  final ValueChanged<HomeProgressAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    final presentation = _ProgressPresentation.from(item);
    final actions = item.actions.isEmpty ? presentation.actions : item.actions;
    return SizedBox(
      key: const Key('progress-card'),
      height: context.r(147),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.progressCardBorder,
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.r(12)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.progressCardSurface,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.r(8),
                context.r(4),
                context.r(8),
                context.r(5),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Column(
                      children: [
                        _ProgressHeader(item: item, presentation: presentation),
                        SizedBox(height: context.r(12)),
                        _ProgressMetrics(
                          item: item,
                          presentation: presentation,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.r(5)),
                  Expanded(
                    child: _ProgressActions(
                      actions: actions,
                      presentation: presentation,
                      onActionTap: onActionTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.item, required this.presentation});

  final HomeProgressItem item;
  final _ProgressPresentation presentation;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(17),
    child: Row(
      children: [
        if (item.productLogo.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(2)),
            child: Image.network(
              item.productLogo,
              width: context.r(12),
              height: context.r(12),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => SizedBox(width: context.r(12)),
            ),
          ),
          SizedBox(width: context.r(4)),
        ],
        Expanded(
          child: Text(
            item.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.homeValue,
              fontSize: context.r(10),
              height: 16 / 10,
            ),
          ),
        ),
        SizedBox(width: context.r(8)),
        Text(
          presentation.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: presentation.statusColor,
            fontSize: context.r(12),
            height: 17 / 12,
          ),
        ),
      ],
    ),
  );
}

class _ProgressMetrics extends StatelessWidget {
  const _ProgressMetrics({required this.item, required this.presentation});

  final HomeProgressItem item;
  final _ProgressPresentation presentation;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(60),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.progressMetricSurface,
        borderRadius: BorderRadius.circular(context.r(4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProgressMetric(
              value: item.amount,
              label: item.amountLabel.isEmpty
                  ? presentation.amountLabel
                  : item.amountLabel,
            ),
          ),
          Container(
            width: context.r(1),
            height: context.r(28),
            color: AppColors.surface.withValues(alpha: 0.43),
          ),
          Expanded(
            child: _ProgressMetric(
              value: item.date,
              label: item.dateLabel.isEmpty
                  ? presentation.dateLabel
                  : item.dateLabel,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.r(12), bottom: context.r(11)),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.progressMetricValue,
            fontSize: context.r(14),
            fontWeight: FontWeight.w700,
            height: 17 / 14,
          ),
        ),
        SizedBox(height: context.r(6)),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.progressMetricLabel,
            fontSize: context.r(10),
            height: 14 / 10,
          ),
        ),
      ],
    ),
  );
}

class _ProgressActions extends StatelessWidget {
  const _ProgressActions({
    required this.actions,
    required this.presentation,
    required this.onActionTap,
  });

  final List<HomeProgressAction> actions;
  final _ProgressPresentation presentation;
  final ValueChanged<HomeProgressAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: actions
          .map((action) {
            final isHighlighted = action.type == 'retry';
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: context.r(12)),
              child: GestureDetector(
                key: Key('progress-action-${action.type}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onActionTap(action),
                child: Text(
                  action.label,
                  style: TextStyle(
                    color: isHighlighted
                        ? AppColors.progressAction
                        : presentation.statusColor,
                    fontSize: context.r(14),
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ProgressPresentation {
  const _ProgressPresentation({
    required this.label,
    required this.amountLabel,
    required this.dateLabel,
    required this.statusColor,
    this.actions = const [],
  });

  final String label;
  final String amountLabel;
  final String dateLabel;
  final Color statusColor;
  final List<HomeProgressAction> actions;

  factory _ProgressPresentation.from(HomeProgressItem item) {
    final serverLabel = item.statusLabel;
    switch (item.status) {
      case HomeProgressState.activeLoan:
      case HomeProgressState.overdue:
        return _ProgressPresentation(
          label: serverLabel.isEmpty
              ? (item.status == HomeProgressState.overdue
                    ? 'Overdue'
                    : 'Active Loan')
              : serverLabel,
          amountLabel: 'Repayment',
          dateLabel: 'Repayment Date',
          statusColor: AppColors.progressStatus,
          actions: _changeAction,
        );
      case HomeProgressState.disbursing:
        return _ProgressPresentation(
          label: serverLabel.isEmpty ? 'Disbursing' : serverLabel,
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          statusColor: AppColors.homeValue,
        );
      case HomeProgressState.disbursementFailed:
      case HomeProgressState.disbursementFailedAlternative:
        return _ProgressPresentation(
          label: serverLabel.isEmpty ? 'Disbursement Failed' : serverLabel,
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          statusColor: AppColors.progressStatus,
          actions: _failedActions,
        );
      case HomeProgressState.inReview:
      default:
        return _ProgressPresentation(
          label: serverLabel.isEmpty ? 'In Review' : serverLabel,
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          statusColor: AppColors.homeValue,
        );
    }
  }

  static const _changeAction = [
    HomeProgressAction(
      type: 'change',
      visible: true,
      label: 'Change',
      badge: '',
      target: '',
    ),
  ];
  static const _failedActions = [
    HomeProgressAction(
      type: 'retry',
      visible: true,
      label: 'Try again',
      badge: '',
      target: '',
    ),
    HomeProgressAction(
      type: 'change',
      visible: true,
      label: 'Change',
      badge: '',
      target: '',
    ),
  ];
}
