import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/certification/personal_information_field_state.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_form.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

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

  testWidgets('uses the design placeholder color for an empty text input', (
    tester,
  ) async {
    final field = PersonalInformationFieldState(
      const PersonalInformationField(
        title: 'Home Phone Number',
        placeholder: 'Please enter',
        saveKey: 'home_phone',
        control: PersonalInformationControl.text,
        numericKeyboard: true,
        isRequired: true,
        options: [],
        initialDisplayValue: '',
        initialSubmitValue: '',
      ),
    );
    addTearDown(field.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(body: PersonalInformationInputField(field: field)),
        ),
      ),
    );

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(
      input.decoration?.hintStyle?.color,
      AppColors.personalInformationPlaceholder,
    );
  });

  testWidgets('ellipsizes a long field value without flex overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScope(
          child: Scaffold(
            body: PersonalInformationFieldValue(
              value:
                  'A very long address value that must stay inside the field width',
              isPlaceholder: false,
              showChevron: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsOneWidget);
    expect(tester.widget<Text>(find.byType(Text)).maxLines, 1);
    expect(
      tester.widget<Text>(find.byType(Text)).overflow,
      TextOverflow.ellipsis,
    );
  });
}
