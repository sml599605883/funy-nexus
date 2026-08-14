import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/home_page.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/home/widgets/home_content.dart';

void main() {
  testWidgets('renders the Lanhu homepage with root-level assets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(
            body: HomeContent(
              data: HomeData(
                hasSections: true,
                primaryCard: HomeCardData(
                  productId: '101',
                  productName: 'Maya Agad',
                  productLogo: 'https://example.com/product.png',
                  amount: '₱88,888',
                  amountLabel: 'Available up to',
                  loanTerm: '90 Days',
                  loanTermLabel: 'Loan terms',
                  interestRate: '≤ 0.3% Day',
                  interestRateLabel: 'Interest rate',
                  description: 'Confirm your loan，Cash hits fast.',
                  actionText: 'Apply Now',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('home-product-identity')),
        matching: find.text('Maya Agad'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-product-logo')), findsOneWidget);
    expect(find.text('₱88,888'), findsOneWidget);
    expect(find.text('90 Days'), findsOneWidget);
    expect(find.text('≤ 0.3% Day'), findsOneWidget);
    expect(find.text('Confirm your loan，Cash hits fast.'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
    expect(
      find.text('Effortless borrowing here, a worry - free life so near!'),
      findsOneWidget,
    );

    final hero = tester.widget<Container>(
      find.byKey(const Key('home-loan-hero')),
    );
    final heroDecoration = hero.decoration! as BoxDecoration;
    expect(
      (heroDecoration.image!.image as AssetImage).assetName,
      AppAssets.homeLoanHero,
    );
    final productLogo = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('home-product-logo')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (productLogo.image as NetworkImage).url,
      'https://example.com/product.png',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-loan-hero')),
        matching: find.byType(Stack),
      ),
      findsNothing,
    );

    final chatIcon = tester.widget<Image>(
      find.byKey(const Key('home-chat-icon')),
    );
    expect((chatIcon.image as AssetImage).assetName, 'assets/chat_icon.png');

    expect(
      tester.getSize(find.byKey(const Key('home-header'))),
      const Size(375, 88),
    );
    expect(
      tester.getSize(find.byKey(const Key('home-loan-hero'))),
      const Size(375, 383),
    );
    expect(
      tester.getSize(find.byKey(const Key('home-apply-button'))),
      const Size(307, 44),
    );
    expect(
      tester.getSize(find.byKey(const Key('home-promo-banner'))),
      const Size(343, 120),
    );
  });

  testWidgets('shows retry when the home request fails', (tester) async {
    final cubit = HomeCubit(loadHome: () async => throw StateError('failed'));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScope(
          child: BlocProvider.value(value: cubit, child: const HomePage()),
        ),
      ),
    );
    await cubit.load();
    await tester.pump();

    expect(find.text('Unable to load home data'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('does not render a local fallback card without LARGE_CARD', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: HomeContent(data: HomeData(hasSections: true)),
        ),
      ),
    );

    expect(find.byKey(const Key('home-loan-hero')), findsNothing);
    expect(find.text('₱60,000'), findsNothing);
    expect(find.text('180 Days'), findsNothing);
    expect(find.text('Apply Now'), findsNothing);
  });

  testWidgets('applies from any area of the large loan card', (tester) async {
    var applyCount = 0;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(
            body: HomeContent(
              data: const HomeData(
                hasSections: true,
                primaryCard: HomeCardData(
                  productId: '101',
                  productName: 'Maya Agad',
                  productLogo: '',
                  amount: 'PHP 88,888',
                  amountLabel: 'Available up to',
                  loanTerm: '90 Days',
                  loanTermLabel: 'Loan terms',
                  interestRate: '0.3% Day',
                  interestRateLabel: 'Interest rate',
                  description: 'Cash hits fast.',
                  actionText: 'Apply Now',
                ),
              ),
              onApply: (_) => applyCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('home-product-identity')));
    await tester.pump();
    expect(applyCount, 1);

    await tester.tap(find.byKey(const Key('home-apply-button')));
    await tester.pump();
    expect(applyCount, 2);
  });

  testWidgets('cycles through all server banners', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(
            body: HomeContent(
              data: HomeData(
                hasSections: true,
                banners: [
                  HomeBannerData(
                    id: 'first',
                    target: '',
                    imageUrl: 'https://example.com/first.png',
                  ),
                  HomeBannerData(
                    id: 'second',
                    target: '',
                    imageUrl: 'https://example.com/second.png',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PageView), findsOneWidget);
    expect(
      tester
          .widget<Image>(
            find.descendant(
              of: find.byKey(const Key('home-promo-banner-image-0')),
              matching: find.byType(Image),
            ),
          )
          .image,
      const NetworkImage('https://example.com/first.png'),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester
          .widget<Image>(
            find.descendant(
              of: find.byKey(const Key('home-promo-banner-image-1')),
              matching: find.byType(Image),
            ),
          )
          .image,
      const NetworkImage('https://example.com/second.png'),
    );
  });
}
