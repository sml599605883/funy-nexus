import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/core/state/async_state.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/progress/progress_page.dart';

void main() {
  testWidgets('renders the semantic empty-state asset', (tester) async {
    final cubit = HomeCubit(
      loadHome: () async => const HomeData(hasSections: true),
    )..emit(const AsyncData(HomeData(hasSections: true)));
    addTearDown(cubit.close);

    await tester.pumpWidget(_Harness(cubit: cubit));

    final image = tester.widget<Image>(
      find.byKey(const Key('progress-empty-image')),
    );
    expect(image.image, const AssetImage(AppAssets.progressEmpty));
    expect(find.text('No progress yet'), findsOneWidget);
  });

  testWidgets('renders Acidulations progress states and actions', (
    tester,
  ) async {
    final item = HomeProgressItem.fromJson({
      'clipsheet': 'order-1',
      'modernised': 'product-1',
      'briarwoods': 'PG Finance',
      'culinarians': 'Disbursement Failed',
      'breaststrokers': 20000,
      'apodoses': 'Loan Amount',
      'psittacosis': '12-07-2024',
      'callboys': 'Loan Date',
      'nightside': 5,
      'endurances': '₱20,000',
      'bettor': 'Disbursement Failed',
      'suffocated': [
        {'etherifying': 'retry', 'mammoth': 1, 'exarchies': 'Try again'},
        {'etherifying': 'change', 'mammoth': 1, 'exarchies': 'Change'},
      ],
    });
    expect(item, isNotNull);
    final cubit = HomeCubit(
      loadHome: () async => const HomeData(hasSections: true),
    )..emit(AsyncData(HomeData(hasSections: true, progressItems: [item!])));
    addTearDown(cubit.close);

    await tester.pumpWidget(_Harness(cubit: cubit));

    expect(find.byKey(const Key('progress-card')), findsOneWidget);
    expect(find.text('PG Finance'), findsOneWidget);
    expect(find.text('₱20,000'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.byKey(const Key('progress-action-retry')), findsOneWidget);
    expect(find.byKey(const Key('progress-action-change')), findsOneWidget);
  });

  testWidgets('ignores unknown server progress actions', (tester) async {
    final item = HomeProgressItem.fromJson({
      'clipsheet': 'order-1',
      'modernised': 'product-1',
      'briarwoods': 'PG Finance',
      'suffocated': [
        {'etherifying': 'unsupported', 'mammoth': 1, 'exarchies': 'More'},
      ],
    });
    final cubit = HomeCubit(
      loadHome: () async => const HomeData(hasSections: true),
    )..emit(AsyncData(HomeData(hasSections: true, progressItems: [item!])));
    addTearDown(cubit.close);

    await tester.pumpWidget(_Harness(cubit: cubit));
    await tester.tap(find.byKey(const Key('progress-action-unsupported')));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.cubit});

  final HomeCubit cubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider.value(value: cubit, child: const ProgressPage()),
    );
  }
}
