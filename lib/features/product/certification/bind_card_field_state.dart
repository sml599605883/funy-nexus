import 'package:flutter/material.dart';
import 'package:fund_nexus/features/product/data/bind_card_data.dart';

class BindCardFieldState {
  BindCardFieldState(this.data)
    : controller = TextEditingController(text: data.initialDisplayValue),
      submitValue = data.initialSubmitValue;

  final BindCardField data;
  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();
  final GlobalKey inputVisibilityKey = GlobalKey();
  String submitValue;

  String get currentSubmitValue =>
      (data.control == BindCardControl.text ? controller.text : submitValue)
          .trim();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

void disposeBindCardFields(Iterable<BindCardFieldState> fields) {
  for (final field in fields) {
    field.dispose();
  }
}
