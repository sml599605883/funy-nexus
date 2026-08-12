import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/state/async_state.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';

void main() {
  test('shows and dismisses loading around a successful home load', () async {
    final loadingEvents = <String>[];
    final cubit = HomeCubit(
      loadHome: () async => const HomeData(hasSections: true),
      showLoading: () async => loadingEvents.add('show'),
      dismissLoading: () async => loadingEvents.add('dismiss'),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(loadingEvents, ['show', 'dismiss']);
  });

  test('dismisses loading when the home load fails', () async {
    final loadingEvents = <String>[];
    final cubit = HomeCubit(
      loadHome: () async => throw StateError('failed'),
      showLoading: () async => loadingEvents.add('show'),
      dismissLoading: () async => loadingEvents.add('dismiss'),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(loadingEvents, ['show', 'dismiss']);
    expect(cubit.state, isA<AsyncFailure<HomeData>>());
  });

  test('an older request does not dismiss a newer request loading', () async {
    final firstRequest = Completer<HomeData>();
    final secondRequest = Completer<HomeData>();
    final loadingEvents = <String>[];
    var requestCount = 0;
    final cubit = HomeCubit(
      loadHome: () =>
          requestCount++ == 0 ? firstRequest.future : secondRequest.future,
      showLoading: () async => loadingEvents.add('show'),
      dismissLoading: () async => loadingEvents.add('dismiss'),
    );
    addTearDown(cubit.close);

    final firstLoad = cubit.load();
    await Future<void>.delayed(Duration.zero);
    final secondLoad = cubit.load();
    await Future<void>.delayed(Duration.zero);

    firstRequest.complete(const HomeData(hasSections: true));
    await firstLoad;
    expect(loadingEvents, ['show', 'show']);

    secondRequest.complete(const HomeData(hasSections: true));
    await secondLoad;
    expect(loadingEvents, ['show', 'show', 'dismiss']);
  });

  test('overlapping loads retain the newest response', () async {
    final firstRequest = Completer<HomeData>();
    var requestCount = 0;
    final cubit = HomeCubit(
      loadHome: () {
        requestCount++;
        if (requestCount == 1) return firstRequest.future;
        return Future.value(
          const HomeData(
            hasSections: true,
            primaryCard: HomeCardData(
              productId: 'newest',
              productName: '',
              amount: '',
              amountLabel: '',
              loanTerm: '',
              loanTermLabel: '',
              interestRate: '',
              interestRateLabel: '',
              description: '',
              actionText: '',
            ),
          ),
        );
      },
    );
    addTearDown(cubit.close);

    final firstLoad = cubit.load();
    await cubit.load();
    expect(requestCount, 2);
    expect(
      (cubit.state as AsyncData<HomeData>).data.primaryCard?.productId,
      'newest',
    );

    firstRequest.complete(
      const HomeData(
        hasSections: true,
        primaryCard: HomeCardData(
          productId: 'older',
          productName: '',
          amount: '',
          amountLabel: '',
          loanTerm: '',
          loanTermLabel: '',
          interestRate: '',
          interestRateLabel: '',
          description: '',
          actionText: '',
        ),
      ),
    );
    await firstLoad;

    expect(
      (cubit.state as AsyncData<HomeData>).data.primaryCard?.productId,
      'newest',
    );
  });

  test('emits empty and failure states', () async {
    final emptyCubit = HomeCubit(
      loadHome: () async => const HomeData(hasSections: false),
    );
    addTearDown(emptyCubit.close);
    await emptyCubit.load();
    expect(emptyCubit.state, isA<AsyncEmpty<HomeData>>());

    final failureCubit = HomeCubit(loadHome: () async => throw StateError('x'));
    addTearDown(failureCubit.close);
    await failureCubit.load();
    expect(failureCubit.state, isA<AsyncFailure<HomeData>>());
  });

  test('refresh failure retains previously delivered home data', () async {
    var shouldFail = false;
    final cubit = HomeCubit(
      loadHome: () async {
        if (shouldFail) throw StateError('refresh failed');
        return const HomeData(hasSections: true);
      },
    );
    addTearDown(cubit.close);

    await cubit.load();
    shouldFail = true;
    await cubit.load();

    final failure = cubit.state as AsyncFailure<HomeData>;
    expect(failure.previousData, isNotNull);
  });
}
