import 'package:flutter/material.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

class PersonalInformationFieldState {
  PersonalInformationFieldState(this.data)
    : controller = TextEditingController(text: data.initialDisplayValue),
      submitValue = data.initialSubmitValue;

  final PersonalInformationField data;
  final TextEditingController controller;
  String submitValue;

  String get currentSubmitValue =>
      (data.control == PersonalInformationControl.text
              ? controller.text
              : submitValue)
          .trim();

  void dispose() => controller.dispose();
}

void disposePersonalInformationFields(
  Iterable<PersonalInformationFieldState> fields,
) {
  for (final field in fields) {
    field.dispose();
  }
}
