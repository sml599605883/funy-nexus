import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/navigation/app_route_observer.dart';
import 'package:fund_nexus/app/theme/app_theme.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/main_shell/main_shell_page.dart';
import 'package:fund_nexus/features/main_shell/state/main_tab_cubit.dart';

void main() {
  testWidgets('starts on Home and exposes three tabs', (tester) async {
    await tester.pumpWidget(_testShell(authenticated: false));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('progress'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.byKey(const Key('tab-home')), findsOneWidget);
    expect(find.byKey(const Key('tab-progress')), findsOneWidget);
    expect(find.byKey(const Key('tab-mine')), findsOneWidget);
  });

  testWidgets('switches tabs while keeping all pages in the stack', (
    tester,
  ) async {
    var homeRequestCount = 0;
    await tester.pumpWidget(
      _testShell(
        authenticated: true,
        homeLoader: () async {
          homeRequestCount++;
          return const HomeData(hasSections: true);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(homeRequestCount, 1);

    await tester.tap(find.byKey(const Key('tab-progress')));
    await tester.pump();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab-home')));
    await tester.pumpAndSettle();
    expect(homeRequestCount, 2);

    await tester.tap(find.byKey(const Key('tab-mine')));
    await tester.pump();
    expect(find.text('Mine'), findsNWidgets(2));
  });

  testWidgets('refreshes the remembered phone when entering Mine', (
    tester,
  ) async {
    final session = _TestSessionStore(
      authenticated: true,
      phone: '09171234567',
    );
    await tester.pumpWidget(_testShell(authenticated: true, session: session));
    await tester.pumpAndSettle();
    session.phoneValue = '09981234567';

    await tester.tap(find.byKey(const Key('tab-mine')));
    await tester.pumpAndSettle();

    expect(find.text('099 **** 4567'), findsOneWidget);
  });

  testWidgets('unauthenticated protected tab opens login and keeps Home', (
    tester,
  ) async {
    final tabs = MainTabCubit();
    var loginBuildCount = 0;
    var homeRequestCount = 0;
    await tester.pumpWidget(
      _testShell(
        authenticated: false,
        tabs: tabs,
        homeLoader: () async {
          homeRequestCount++;
          return const HomeData(hasSections: true);
        },
        loginPageBuilder: (_) {
          loginBuildCount++;
          return Scaffold(
            body: Column(
              children: [
                const Text('Login stub'),
                Builder(
                  builder: (context) => TextButton(
                    key: const Key('login-success-stub'),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Complete login'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final progressTab = tester.widget<InkWell>(
      find.byKey(const Key('tab-progress')),
    );
    progressTab.onTap!();
    progressTab.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Login stub'), findsOneWidget);
    expect(loginBuildCount, 1);
    expect(tabs.state, 0);

    await tester.tap(find.byKey(const Key('login-success-stub')));
    await tester.pumpAndSettle();

    expect(find.text('Login stub'), findsNothing);
    expect(tabs.state, 0);
    expect(find.text('Home'), findsOneWidget);
    expect(homeRequestCount, 2);
  });

  testWidgets('route return refreshes Home but a covered Home stays idle', (
    tester,
  ) async {
    var homeRequestCount = 0;
    await tester.pumpWidget(
      _testShell(
        authenticated: true,
        homeLoader: () async {
          homeRequestCount++;
          return const HomeData(hasSections: true);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(homeRequestCount, 1);

    final shellContext = tester.element(find.byType(MainShellPage));
    Navigator.of(
      shellContext,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(homeRequestCount, 1);

    Navigator.of(shellContext).pop();
    await tester.pumpAndSettle();
    expect(homeRequestCount, 2);
  });

  testWidgets('lifecycle refresh matches MP Home visibility rules', (
    tester,
  ) async {
    var homeRequestCount = 0;
    await tester.pumpWidget(
      _testShell(
        authenticated: true,
        homeLoader: () async {
          homeRequestCount++;
          return const HomeData(hasSections: true);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(homeRequestCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(homeRequestCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(homeRequestCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(homeRequestCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(homeRequestCount, 2);

    await tester.tap(find.byKey(const Key('tab-progress')));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(homeRequestCount, 2);
  });
}

Widget _testShell({
  required bool authenticated,
  MainTabCubit? tabs,
  HomeLoader? homeLoader,
  WidgetBuilder? loginPageBuilder,
  _TestSessionStore? session,
}) {
  return RepositoryProvider<SessionStore>.value(
    value: session ?? _TestSessionStore(authenticated: authenticated),
    child: MaterialApp(
      theme: AppTheme.light,
      navigatorObservers: [appRouteObserver],
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: tabs ?? MainTabCubit()),
          BlocProvider(
            create: (_) => HomeCubit(
              loadHome:
                  homeLoader ?? () async => const HomeData(hasSections: true),
            )..load(),
          ),
        ],
        child: MainShellPage(loginPageBuilder: loginPageBuilder),
      ),
    ),
  );
}

class _TestSessionStore extends SessionStore {
  factory _TestSessionStore({required bool authenticated, String? phone}) {
    final persistence = _MemoryPersistence(phone: phone);
    return _TestSessionStore._(authenticated, persistence);
  }

  _TestSessionStore._(this.authenticated, this._persistence)
    : super(_persistence);

  final bool authenticated;
  final _MemoryPersistence _persistence;

  String? get phoneValue => phone;
  set phoneValue(String? value) => _persistence.phone = value;

  @override
  bool get isAuthenticated => authenticated;
}

class _MemoryPersistence implements SessionPersistence {
  _MemoryPersistence({this.phone});

  String? phone;

  @override
  Future<String?> readPhone() async => phone;

  @override
  Future<String?> readSessionId() async => null;

  @override
  Future<void> writePhone(String? phone) async {}

  @override
  Future<void> writeSessionId(String? sessionId) async {}
}
