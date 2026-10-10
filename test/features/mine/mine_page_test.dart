import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_theme.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/mine/account_session_coordinator.dart';
import 'package:fund_nexus/features/mine/mine_page.dart';

void main() {
  test('masks a stored phone number', () {
    expect(MinePage.formatPhone('96212341300'), '962 **** 1300');
    expect(MinePage.formatPhone('1234567'), '1234567');
  });

  testWidgets('renders Mine sections and semantic entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      _minePage(phone: '96212341300', onAccountExit: (_) async => true),
    );

    expect(find.byKey(const Key('mine-phone')), findsOneWidget);
    expect(find.text('962 **** 1300'), findsOneWidget);
    expect(find.byKey(const Key('mine-order-statuses')), findsOneWidget);
    expect(find.text('Customer Service'), findsOneWidget);
    expect(find.text('About Us'), findsOneWidget);
    expect(find.byKey(const Key('mine-customer-service')), findsOneWidget);
    expect(find.byKey(const Key('mine-account')), findsOneWidget);
  });

  testWidgets('opens customer service from Mine', (tester) async {
    var customerServiceCalls = 0;
    await tester.pumpWidget(
      _minePage(
        phone: '96212341300',
        onCustomerService: () => customerServiceCalls++,
      ),
    );

    final customerService = find.byKey(const Key('mine-customer-service'));
    final customerServiceTap = tester.widget<InkWell>(
      find.descendant(of: customerService, matching: find.byType(InkWell)),
    );
    customerServiceTap.onTap!();
    expect(customerServiceCalls, 1);
  });

  testWidgets('opens privacy agreement from Mine', (tester) async {
    var privacyPolicyCalls = 0;
    await tester.pumpWidget(
      _minePage(
        phone: '96212341300',
        onPrivacyPolicy: () => privacyPolicyCalls++,
      ),
    );

    final privacyAgreement = find.byKey(const Key('mine-privacy-agreement'));
    final privacyTap = tester.widget<InkWell>(
      find.descendant(of: privacyAgreement, matching: find.byType(InkWell)),
    );
    privacyTap.onTap!();
    expect(privacyPolicyCalls, 1);
  });

  testWidgets('shows the app version from the injected value', (tester) async {
    await tester.pumpWidget(
      _minePage(phone: '96212341300', appVersion: '1.0.0'),
    );

    expect(find.text('v1.0.0'), findsOneWidget);
  });

  testWidgets('opens the website from Mine', (tester) async {
    var websiteCalls = 0;
    await tester.pumpWidget(
      _minePage(phone: '96212341300', onWebsiteTap: () => websiteCalls++),
    );

    final website = find.byKey(const Key('mine-website'));
    final websiteTap = tester.widget<InkWell>(
      find.descendant(of: website, matching: find.byType(InkWell)),
    );
    websiteTap.onTap!();
    expect(websiteCalls, 1);
  });

  testWidgets('opens and closes the account action panel', (tester) async {
    await tester.pumpWidget(
      _minePage(phone: '96212341300', onAccountExit: (_) async => true),
    );

    final account = find.byKey(const Key('mine-account'));
    final accountTap = tester.widget<InkWell>(
      find.descendant(of: account, matching: find.byType(InkWell)),
    );
    accountTap.onTap!();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-account-panel')), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mine-account-panel-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-account-panel')), findsNothing);
  });

  testWidgets('opens the logout retention dialog and closes it on keep', (
    tester,
  ) async {
    await tester.pumpWidget(
      _minePage(phone: '96212341300', onAccountExit: (_) async => true),
    );

    await _openAccountPanel(tester);
    await tester.tap(find.byKey(const Key('mine-account-log-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-account-panel')), findsNothing);
    expect(
      find.byKey(const Key('mine-logout-retention-dialog')),
      findsOneWidget,
    );
    expect(find.text('Keep Me Notified'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mine-retention-exit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-logout-retention-dialog')), findsNothing);
  });

  testWidgets('opens the delete-account retention dialog', (tester) async {
    await tester.pumpWidget(
      _minePage(phone: '96212341300', onAccountExit: (_) async => true),
    );

    await _openAccountPanel(tester);
    await tester.tap(find.byKey(const Key('mine-account-delete')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mine-delete-account-retention-dialog')),
      findsOneWidget,
    );
    expect(find.text('Save My Data'), findsOneWidget);
    expect(find.text('Proceed to Delete'), findsOneWidget);
  });

  testWidgets('confirms an account action through the injected handler', (
    tester,
  ) async {
    AccountExitAction? action;
    await tester.pumpWidget(
      _minePage(
        phone: '96212341300',
        onAccountExit: (value) async {
          action = value;
          return true;
        },
      ),
    );

    await _openAccountPanel(tester);
    await tester.tap(find.byKey(const Key('mine-account-log-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mine-retention-exit')));
    await tester.pumpAndSettle();

    expect(action, AccountExitAction.logOut);
    expect(find.byKey(const Key('mine-logout-retention-dialog')), findsNothing);
  });

  testWidgets('keeps the confirmation dialog open when exit fails', (
    tester,
  ) async {
    final messages = <String>[];
    await tester.pumpWidget(
      _minePage(
        phone: '96212341300',
        onAccountExit: (_) async => throw const ApiException(
          type: ApiFailureType.business,
          message: 'exit failed',
        ),
        showMessage: (message) async => messages.add(message),
      ),
    );

    await _openAccountPanel(tester);
    await tester.tap(find.byKey(const Key('mine-account-log-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mine-retention-exit')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mine-logout-retention-dialog')),
      findsOneWidget,
    );
    expect(messages, ['exit failed']);
  });

  testWidgets('dismisses loading before showing the exit error', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      _minePage(
        phone: '96212341300',
        onAccountExit: (_) async => throw const ApiException(
          type: ApiFailureType.business,
          message: 'exit failed',
        ),
        showLoading: () async => events.add('loading'),
        dismissLoading: () async => events.add('dismiss'),
        showMessage: (message) async => events.add('message:$message'),
      ),
    );

    await _openAccountPanel(tester);
    await tester.tap(find.byKey(const Key('mine-account-log-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mine-retention-exit')));
    await tester.pumpAndSettle();

    expect(events, ['loading', 'dismiss', 'message:exit failed']);
  });
}

Future<void> _openAccountPanel(WidgetTester tester) async {
  final account = find.byKey(const Key('mine-account'));
  final accountTap = tester.widget<InkWell>(
    find.descendant(of: account, matching: find.byType(InkWell)),
  );
  accountTap.onTap!();
  await tester.pumpAndSettle();
}

Widget _minePage({
  required String phone,
  AccountExitHandler? onAccountExit,
  AccountExitMessageHandler? showMessage,
  Future<void> Function()? showLoading,
  Future<void> Function()? dismissLoading,
  VoidCallback? onCustomerService,
  VoidCallback? onPrivacyPolicy,
  VoidCallback? onWebsiteTap,
  String? appVersion,
}) {
  return RepositoryProvider<SessionStore>.value(
    value: _TestSessionStore(phone),
    child: MaterialApp(
      theme: AppTheme.light,
      home: ResponsiveScope(
        child: Scaffold(
          body: MinePage(
            onAccountExit: onAccountExit,
            onCustomerService: onCustomerService,
            onPrivacyPolicy: onPrivacyPolicy,
            onWebsiteTap: onWebsiteTap,
            appVersion: appVersion,
            showLoading: showLoading ?? () async {},
            dismissLoading: dismissLoading ?? () async {},
            showMessage: showMessage,
          ),
        ),
      ),
    ),
  );
}

class _TestSessionStore extends SessionStore {
  _TestSessionStore(this._phone) : super(_MemoryPersistence());

  final String _phone;

  @override
  String? get phone => _phone;
}

class _MemoryPersistence implements SessionPersistence {
  @override
  Future<String?> readPhone() async => null;

  @override
  Future<String?> readSessionId() async => null;

  @override
  Future<void> writePhone(String? phone) async {}

  @override
  Future<void> writeSessionId(String? sessionId) async {}
}
