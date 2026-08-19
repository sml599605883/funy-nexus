import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/navigation/app_route_observer.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/navigation/customer_service_navigation.dart';
import 'package:fund_nexus/features/home/home_page.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/login/login_page.dart';
import 'package:fund_nexus/features/main_shell/state/main_tab_cubit.dart';
import 'package:fund_nexus/features/mine/mine_page.dart';
import 'package:fund_nexus/features/progress/progress_page.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({
    this.loginPageBuilder,
    this.sessionExpiryEvents,
    this.reportService,
    super.key,
  });

  final WidgetBuilder? loginPageBuilder;
  final Stream<void>? sessionExpiryEvents;
  final ReportService? reportService;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage>
    with WidgetsBindingObserver, RouteAware {
  bool _openingLogin = false;
  bool _routeVisible = true;
  bool _wasInBackground = false;
  PageRoute<dynamic>? _subscribedRoute;
  StreamSubscription<void>? _sessionExpirySubscription;

  static const _items = <_TabItemData>[
    _TabItemData(
      id: 'home',
      label: 'Home',
      selectedAsset: AppAssets.tabHomeSelected,
      unselectedAsset: AppAssets.tabHomeUnselected,
    ),
    _TabItemData(
      id: 'progress',
      label: 'progress',
      selectedAsset: AppAssets.tabProgressSelected,
      unselectedAsset: AppAssets.tabProgressUnselected,
    ),
    _TabItemData(
      id: 'mine',
      label: 'Mine',
      selectedAsset: AppAssets.tabMineSelected,
      unselectedAsset: AppAssets.tabMineUnselected,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.reportService?.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sessionExpirySubscription ??= widget.sessionExpiryEvents?.listen(
      (_) => unawaited(_openLoginAfterSessionExpiry()),
    );
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        appRouteObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _sessionExpirySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _refreshVisibleTab();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wasInBackground = true;
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final resumedFromBackground = _wasInBackground;
    _wasInBackground = false;
    if (!resumedFromBackground) return;
    unawaited(widget.reportService?.resumed());
    _refreshVisibleTab();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainTabCubit, int>(
      builder: (context, selectedIndex) {
        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: [
              const HomePage(key: PageStorageKey('home-page')),
              const ProgressPage(key: PageStorageKey('progress-page')),
              MinePage(
                key: const PageStorageKey('mine-page'),
                phone: context.read<SessionStore>().phone,
                onCustomerService: () => _openCustomerService(context),
                onAccountExitSuccess: () async {
                  context.read<MainTabCubit>().selectTab(0);
                  await context.read<HomeCubit>().load();
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          bottomNavigationBar: _FundNexusTabBar(
            items: _items,
            selectedIndex: selectedIndex,
            onSelected: (index) => _selectTab(context, index),
          ),
        );
      },
    );
  }

  Future<void> _openCustomerService(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductWebPage(
          url: customerServiceUrl(context.read<AppConfig>().webBaseUrl),
        ),
      ),
    );
  }

  Future<void> _selectTab(BuildContext context, int index) async {
    final tabs = context.read<MainTabCubit>();
    if (index == tabs.state) return;

    if (index != 0 && !context.read<SessionStore>().isAuthenticated) {
      if (_openingLogin) return;
      _openingLogin = true;
      try {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: widget.loginPageBuilder ?? _buildLoginPage,
          ),
        );
      } finally {
        _openingLogin = false;
      }
      return;
    }

    tabs.selectTab(index);
    if (index == 0 || index == 1) {
      await context.read<HomeCubit>().load();
    } else if (index == 2) {
      await context.read<SessionStore>().refreshPhone();
      if (mounted) setState(() {});
    }
  }

  Future<void> _openLoginAfterSessionExpiry() async {
    if (!mounted || _openingLogin) return;
    _openingLogin = true;
    context.read<MainTabCubit>().selectTab(0);
    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: widget.loginPageBuilder ?? _buildLoginPage,
        ),
      );
    } finally {
      _openingLogin = false;
      if (mounted) setState(() {});
    }
  }

  void _refreshVisibleTab() {
    if (!mounted || !_routeVisible) {
      return;
    }
    final selectedTab = context.read<MainTabCubit>().state;
    if (selectedTab == 0 || selectedTab == 1) {
      unawaited(context.read<HomeCubit>().load());
    }
  }

  Widget _buildLoginPage(BuildContext context) {
    final riskStartedAtSeconds = ReportService.nowSeconds();
    return LoginPage(
      onLoginSuccess: () async {
        await widget.reportService?.loginSucceeded(
          riskStartedAtSeconds: riskStartedAtSeconds,
        );
        if (context.mounted) Navigator.of(context).pop(true);
      },
    );
  }
}

class _FundNexusTabBar extends StatelessWidget {
  const _FundNexusTabBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_TabItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        height: context.r(49) + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: InkWell(
                  key: Key('tab-${item.id}'),
                  onTap: () => onSelected(index),
                  child: Semantics(
                    selected: isSelected,
                    button: true,
                    label: item.label,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          isSelected
                              ? item.selectedAsset
                              : item.unselectedAsset,
                          key: Key('tab-${item.id}-icon'),
                          width: context.r(24),
                          height: context.r(24),
                        ),
                        SizedBox(height: context.r(2)),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.loginInputText
                                : AppColors.tabUnselected,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 17 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItemData {
  const _TabItemData({
    required this.id,
    required this.label,
    required this.selectedAsset,
    required this.unselectedAsset,
  });

  final String id;
  final String label;
  final String selectedAsset;
  final String unselectedAsset;
}
