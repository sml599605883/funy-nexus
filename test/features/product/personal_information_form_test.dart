import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_form.dart';

void main() {
  testWidgets('uses the design placeholder color for an unselected value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(
            body: PersonalInformationFieldValue(
              value: 'Please select',
              isPlaceholder: true,
              showChevron: true,
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Please select'));
    expect(text.style?.color, AppColors.personalInformationPlaceholder);
  });

  testWidgets('keeps selected values in the primary text color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(
            body: PersonalInformationFieldValue(
              value: 'College',
              isPlaceholder: false,
              showChevron: true,
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('College'));
    expect(text.style?.color, AppColors.textPrimary);
  });
}
