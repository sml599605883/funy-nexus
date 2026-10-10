import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/startup/startup_network_gate.dart';

void main() {
  testWidgets('shows the launch image while probing and enters the app', (
    tester,
  ) async {
    final probe = Completer<bool>();
    await tester.pumpWidget(
      StartupNetworkGate(probe: () => probe.future, readyBuilder: _readyPage),
    );
    await tester.pump();

    expect(find.byKey(const Key('startup-launch')), findsOneWidget);
    expect(
      find.textContaining('Network error, please try again later or'),
      findsNothing,
    );
    expect(find.byKey(const Key('startup-network-retry')), findsNothing);
    expect(find.text('ready'), findsNothing);

    probe.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('hides the launch image after the probe fails', (tester) async {
    final probe = Completer<bool>();
    await tester.pumpWidget(
      StartupNetworkGate(probe: () => probe.future, readyBuilder: _readyPage),
    );
    await tester.pump();

    expect(find.byKey(const Key('startup-launch')), findsOneWidget);
    expect(find.byKey(const Key('startup-network-retry')), findsNothing);

    probe.complete(false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startup-launch')), findsNothing);
    expect(
      find.textContaining('Network error, please try again later or'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('startup-network-retry')), findsOneWidget);
    expect(find.text('ready'), findsNothing);
  });

  testWidgets('keeps the page on failure and retries once on tap', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      StartupNetworkGate(
        probe: () async {
          attempts++;
          return attempts > 1;
        },
        readyBuilder: _readyPage,
      ),
    );
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.text('ready'), findsNothing);
    expect(find.byKey(const Key('startup-launch')), findsNothing);

    await tester.tap(find.byKey(const Key('startup-network-retry')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('does not start a duplicate probe while checking', (
    tester,
  ) async {
    final retryProbe = Completer<bool>();
    var attempts = 0;
    await tester.pumpWidget(
      StartupNetworkGate(
        probe: () {
          attempts++;
          return attempts == 1 ? Future.value(false) : retryProbe.future;
        },
        readyBuilder: _readyPage,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('startup-network-retry')));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byKey(const Key('startup-launch')), findsNothing);

    await tester.tap(find.byKey(const Key('startup-network-retry')));
    await tester.pump();
    expect(attempts, 2);

    retryProbe.complete(false);
    await tester.pumpAndSettle();
  });

  testWidgets('matches the 375 by 812 network-error layout', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      StartupNetworkGate(
        probe: () async => false,
        readyBuilder: _readyPage,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const Key('startup-network-retry'))),
      const Rect.fromLTWH(16, 470, 343, 48),
    );
    expect(
      tester.getRect(find.byKey(const Key('startup-network-illustration'))),
      const Rect.fromLTWH(118.5, 300, 138, 102),
    );
  });
}

Widget _readyPage() {
  return const Directionality(
    textDirection: TextDirection.ltr,
    child: Text('ready'),
  );
}
