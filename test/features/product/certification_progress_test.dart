import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_progress.dart';

void main() {
  testWidgets('uses active and inactive colors for the current step', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(body: CertificationProgress(currentStep: 1)),
        ),
      ),
    );

    expect(_segmentColor(tester, 0), AppColors.certificationProgressActive);
    expect(_segmentColor(tester, 1), AppColors.certificationProgressInactive);
    expect(_segmentColor(tester, 3), AppColors.certificationProgressInactive);
  });

  testWidgets('allows later certification pages to advance the progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(body: CertificationProgress(currentStep: 3)),
        ),
      ),
    );

    expect(_segmentColor(tester, 2), AppColors.certificationProgressActive);
    expect(_segmentColor(tester, 3), AppColors.certificationProgressInactive);
  });
}

Color? _segmentColor(WidgetTester tester, int index) => tester
    .widget<Container>(find.byKey(Key('certificationProgressSegment-$index')))
    .color;
