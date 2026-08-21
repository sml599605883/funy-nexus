import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_theme.dart';
import 'package:fund_nexus/core/json/json.dart';
import 'package:fund_nexus/features/main_shell/home_popup.dart';
import 'package:fund_nexus/features/main_shell/home_popup_data.dart';

void main() {
  testWidgets('renders upgrade popup and opens its update URL', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? openedUrl;
    final data = HomePopupData.fromResponse(
      Json({
        'etherifying': 1,
        'leapt': {
          'stookers': '1.1.4',
          'heliacally': 'New version is now available',
          'redepositing': 'https://store.example.test/app',
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: ResponsiveScope(
              child: HomePopup(
                data: data,
                externalOpener: (url) async {
                  openedUrl = url;
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(HomePopup.cardKey), findsOneWidget);
    expect(find.text('V1.1.4'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(HomePopup.cardKey),
        matching: find.byType(Stack),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(HomePopup.updateButtonKey));
    await tester.pump();
    expect(openedUrl, 'https://store.example.test/app');
  });

  testWidgets(
    'renders a marketing image at the documented width and opens it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? openedUrl;
      const data = HomePopupData(
        type: HomePopupType.marketing,
        imageUrl: 'https://cdn.example.test/promo.png',
        targetUrl: 'https://example.test/promo',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(375, 812)),
              child: ResponsiveScope(
                child: HomePopup(
                  data: data,
                  externalOpener: (_) async => true,
                  inAppOpener: (url) async => openedUrl = url,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(HomePopup.marketingContentKey), findsOneWidget);
      expect(find.byKey(HomePopup.marketingImageKey), findsOneWidget);
      expect(find.byKey(HomePopup.marketingCloseKey), findsOneWidget);
      expect(find.byKey(HomePopup.marketingCloseGapKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(HomePopup.marketingImageKey)).width,
        343,
      );

      final imageTap = tester.widget<GestureDetector>(
        find.byKey(HomePopup.marketingImageKey),
      );
      imageTap.onTap!.call();
      await tester.pump();
      expect(openedUrl, 'https://example.test/promo');
    },
  );
}
