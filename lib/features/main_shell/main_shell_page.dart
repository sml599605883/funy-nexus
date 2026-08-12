import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/navigation/app_route_observer.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/home/home_page.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/login/login_page.dart';
import 'package:fund_nexus/features/main_shell/state/main_tab_cubit.dart';
import 'package:fund_nexus/features/mine/mine_page.dart';
import 'package:fund_nexus/features/progress/progress_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({this.loginPageBuilder, super.key});

  final WidgetBuilder? loginPageBuilder;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage>
    with WidgetsBindingObserver, RouteAware {
  bool _openingLogin = false;
  bool _routeVisible = true;
  bool _wasInactive = false;
  bool _wasInBackground = false;
  bool _inactiveResumeRefreshConsumed = false;
  PageRoute<dynamic>? _subscribedRoute;

  static const _pages = <Widget>[
    HomePage(key: PageStorageKey('home-page')),
    ProgressPage(key: PageStorageKey('progress-page')),
    MinePage(key: PageStorageKey('mine-page')),
  ];

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _refreshHomeIfVisible();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _wasInactive = true;
      return;
    }
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wasInBackground = true;
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final resumedFromBackground = _wasInBackground;
    final firstInactiveResume = _wasInactive && !_inactiveResumeRefreshConsumed;
    _wasInactive = false;
    _wasInBackground = false;
    if (!resumedFromBackground && !firstInactiveResume) return;
    if (!resumedFromBackground) {
      _inactiveResumeRefreshConsumed = true;
    }
    _refreshHomeIfVisible();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainTabCubit, int>(
      builder: (context, selectedIndex) {
        return Scaffold(
          body: IndexedStack(index: selectedIndex, children: _pages),
          bottomNavigationBar: _FundNexusTabBar(
            items: _items,
            selectedIndex: selectedIndex,
            onSelected: (index) => _selectTab(context, index),
          ),
        );
      },
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
            builder: widget.loginPageBuilder ?? (_) => const LoginPage(),
          ),
        );
      } finally {
        _openingLogin = false;
      }
      return;
    }

    tabs.selectTab(index);
    if (index == 0) {
      await context.read<HomeCubit>().load();
    }
  }

  void _refreshHomeIfVisible() {
    if (!mounted || !_routeVisible || context.read<MainTabCubit>().state != 0) {
      return;
    }
    unawaited(context.read<HomeCubit>().load());
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
