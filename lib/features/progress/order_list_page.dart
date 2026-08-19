import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/navigation/app_route_observer.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';
import 'order_list_models.dart';

typedef OrderListLoader = Future<List<OrderListItem>> Function(String status);
typedef OrderListLoadingAction = Future<void> Function();

class OrderListPage extends StatefulWidget {
  const OrderListPage({
    super.key,
    this.initialStatus,
    this.loadOrders,
    this.showLoading,
    this.dismissLoading,
  });

  final OrderListStatus? initialStatus;
  final OrderListLoader? loadOrders;
  final OrderListLoadingAction? showLoading;
  final OrderListLoadingAction? dismissLoading;

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with RouteAware {
  late OrderListStatus _selectedStatus;
  List<OrderListItem> _items = const [];
  bool _loading = true;
  String? _error;
  int _generation = 0;
  PageRoute<dynamic>? _route;
  final Set<String> _activeActions = {};

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? OrderListStatus.all;
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && !identical(route, _route)) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() => unawaited(_load());

  @override
  void dispose() {
    if (_route != null) appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<List<OrderListItem>> _loadFromApi(String status) async {
    final response = await context.read<ApiClient>().fetchOrderList(
      status: status,
    );
    return parseOrderListItems(response.data);
  }

  Future<void> _load() async {
    final generation = ++_generation;
    unawaited(_showRequestLoading());
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await (widget.loadOrders ?? _loadFromApi)(
        _selectedStatus.code,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = error is ApiException
            ? error.message
            : 'Unable to load orders.';
      });
    } finally {
      if (generation == _generation) {
        await _dismissRequestLoading();
      }
    }
  }

  Future<void> _showRequestLoading() {
    if (widget.showLoading != null) return widget.showLoading!();
    if (widget.loadOrders != null) return Future<void>.value();
    return EasyLoading.show(status: 'Loading...');
  }

  Future<void> _dismissRequestLoading() {
    if (widget.dismissLoading != null) return widget.dismissLoading!();
    if (widget.loadOrders != null) return Future<void>.value();
    return EasyLoading.dismiss(animation: false);
  }

  void _selectStatus(OrderListStatus status) {
    if (status == _selectedStatus) return;
    setState(() => _selectedStatus = status);
    unawaited(_load());
  }

  Future<void> _openItem(OrderListItem item, {required bool action}) async {
    final rawTarget = action
        ? item.actionTarget
        : (item.cardTarget.isNotEmpty ? item.cardTarget : item.legacyTarget);
    final target = _absoluteTarget(rawTarget);
    final key = '${item.orderId}|$rawTarget';
    if (!_activeActions.add(key)) return;
    try {
      if (target.isNotEmpty && ProductWebPage.validUri(target) != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: target)),
        );
      } else if (!action && item.productId.isNotEmpty && mounted) {
        await _applyProduct(item.productId);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException ? error.message : 'Unable to open order.',
            ),
          ),
        );
      }
    } finally {
      _activeActions.remove(key);
    }
  }

  String _absoluteTarget(String target) {
    if (ProductWebPage.validUri(target) != null) return target;
    if (target.trim().startsWith('/')) {
      return context.read<AppConfig>().webBaseUrl.resolve(target).toString();
    }
    return target;
  }

  Future<void> _applyProduct(String productId) {
    return context.read<ProductApplicationFlow>().apply(
      productId: productId,
      openLogin: (_) async => false,
      openTarget: (target) async {
        if (!mounted || ProductWebPage.validUri(target) == null) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: target)),
        );
      },
      openCreditReview: (_) async {},
      openCertification: (_, _) async {},
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: () => EasyLoading.dismiss(animation: false),
      showMessage: (message) async {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: DecoratedBox(
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
          color: AppColors.orderActive,
          onRefresh: _load,
          child: ListView(
            key: const Key('order-list-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: context.r(24)),
            children: [
              _OrderHeader(onBack: () => Navigator.of(context).maybePop()),
              SizedBox(height: context.r(13)),
              _OrderTabs(selected: _selectedStatus, onSelected: _selectStatus),
              SizedBox(height: context.r(16)),
              if (_loading)
                const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _OrderError(message: _error!, onRetry: _load)
              else if (_items.isEmpty)
                const _OrderEmpty()
              else
                for (final item in _items) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.r(16)),
                    child: _OrderCard(
                      item: item,
                      onTap: () => _openItem(item, action: false),
                      onAction: item.hasAction
                          ? () => _openItem(item, action: true)
                          : null,
                    ),
                  ),
                  SizedBox(height: context.r(12)),
                ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(40),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            key: const Key('order-list-back'),
            onPressed: onBack,
            icon: Image.asset(
              AppAssets.identityBackButton,
              width: context.r(18),
              height: context.r(18),
            ),
          ),
        ),
        Text(
          'Loan List',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: context.r(17),
            fontWeight: FontWeight.w600,
            height: 24 / 17,
          ),
        ),
      ],
    ),
  );
}

class _OrderTabs extends StatelessWidget {
  const _OrderTabs({required this.selected, required this.onSelected});
  final OrderListStatus selected;
  final ValueChanged<OrderListStatus> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final status in OrderListStatus.values)
        Expanded(
          child: InkWell(
            key: ValueKey('order-tab-${status.code}'),
            onTap: () => onSelected(status),
            child: Column(
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    color: status == selected
                        ? AppColors.orderActive
                        : AppColors.orderInactive,
                    fontSize: context.r(15),
                    fontWeight: status == selected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    height: 18 / 15,
                  ),
                ),
                SizedBox(height: context.r(13)),
                SizedBox(
                  width: context.r(51),
                  height: context.r(4),
                  child: ColoredBox(
                    color: status == selected
                        ? AppColors.orderActive
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.item, required this.onTap, this.onAction});
  final OrderListItem item;
  final VoidCallback onTap;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isOverdue
        ? AppColors.orderOverdue
        : AppColors.orderActive;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(context.r(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: InkWell(
              key: ValueKey('order-card-${item.orderId}'),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(context.r(12)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (item.productLogo.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(context.r(2)),
                            child: Image.network(
                              item.productLogo,
                              width: context.r(20),
                              height: context.r(20),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
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
                              color: AppColors.orderProductText,
                              fontSize: context.r(14),
                              fontWeight: FontWeight.w500,
                              height: 16 / 14,
                            ),
                          ),
                        ),
                        SizedBox(width: context.r(8)),
                        Text(
                          item.statusText,
                          style: TextStyle(
                            color: item.isOverdue
                                ? AppColors.orderOverdue
                                : AppColors.orderActive,
                            fontSize: context.r(12),
                            height: 14 / 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.r(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _OrderMetric(
                            label: item.amountLabel,
                            value: item.amountText,
                          ),
                        ),
                        SizedBox(width: context.r(12)),
                        Expanded(
                          child: _OrderMetric(
                            label: item.dateLabel,
                            value: item.dateValue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onAction != null)
            SizedBox(
              width: double.infinity,
              height: context.r(60),
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: AppColors.surface,
                  backgroundColor: statusColor,
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(item.actionText),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: context.r(52),
    decoration: BoxDecoration(
      color: AppColors.orderMetricSurface,
      borderRadius: BorderRadius.circular(context.r(4)),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: context.r(8),
      vertical: context.r(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.orderMetricLabel,
            fontSize: context.r(12),
            height: 14 / 12,
          ),
        ),
        SizedBox(height: context.r(5)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.orderMetricValue,
            fontSize: context.r(14),
            fontWeight: FontWeight.w700,
            height: 17 / 14,
          ),
        ),
      ],
    ),
  );
}

class _OrderEmpty extends StatelessWidget {
  const _OrderEmpty();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(520),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          AppAssets.progressEmpty,
          key: const Key('order-empty-image'),
          width: context.r(138),
          height: context.r(102),
        ),
        SizedBox(height: context.r(13)),
        Text(
          'No information available',
          style: TextStyle(
            color: AppColors.homeValue,
            fontSize: context.r(14),
            height: 18 / 14,
          ),
        ),
      ],
    ),
  );
}

class _OrderError extends StatelessWidget {
  const _OrderError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(300),
    child: Center(
      child: TextButton(onPressed: onRetry, child: Text(message)),
    ),
  );
}
