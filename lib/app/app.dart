import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/navigation/app_route_observer.dart';
import 'package:fund_nexus/app/theme/app_theme.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_crypto.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/session/session_expiry_coordinator.dart';
import 'package:fund_nexus/features/home/data/home_repository.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/main_shell/main_shell_page.dart';
import 'package:fund_nexus/features/main_shell/state/main_tab_cubit.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';

class FundNexusApp extends StatelessWidget {
  const FundNexusApp({
    required this.apiClient,
    required this.apiCrypto,
    required this.config,
    required this.sessionStore,
    required this.sessionExpiryCoordinator,
    super.key,
  });

  final ApiClient apiClient;
  final ApiCrypto apiCrypto;
  final AppConfig config;
  final SessionStore sessionStore;
  final SessionExpiryCoordinator sessionExpiryCoordinator;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfig>.value(value: config),
        RepositoryProvider<SessionStore>.value(value: sessionStore),
        RepositoryProvider<SessionExpiryCoordinator>.value(
          value: sessionExpiryCoordinator,
        ),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<ApiCrypto>.value(value: apiCrypto),
        RepositoryProvider<ProductGateway>(
          create: (_) => ProductRepository(apiClient: apiClient),
        ),
        RepositoryProvider<PermissionCoordinator>.value(
          value: PermissionCoordinator.instance,
        ),
        RepositoryProvider(
          create: (context) => ProductApplicationFlow(
            repository: context.read<ProductGateway>(),
            sessionStore: sessionStore,
            permissions: context.read<PermissionCoordinator>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Fund Nexus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorObservers: [appRouteObserver],
        builder: (context, child) => EasyLoading.init()(
          context,
          ResponsiveScope(child: child ?? const SizedBox.shrink()),
        ),
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => MainTabCubit()),
            BlocProvider(
              create: (_) {
                final repository = HomeRepository(apiClient: apiClient);
                return HomeCubit(
                  loadHome: repository.fetchHome,
                  showLoading: () => EasyLoading.show(),
                  dismissLoading: EasyLoading.dismiss,
                )..load();
              },
            ),
          ],
          child: MainShellPage(
            sessionExpiryEvents: sessionExpiryCoordinator.events,
          ),
        ),
      ),
    );
  }
}
