import 'package:fund_nexus/core/json/json.dart';

enum BindCardControl { text, selection }

class BindCardOption {
  const BindCardOption({
    required this.label,
    required this.value,
    required this.logoUrl,
    required this.available,
    this.maintenanceMessage = '',
  });

  factory BindCardOption.fromJson(Json json) => BindCardOption(
    label: json['emit'].stringValue.trim(),
    value: json['etherifying'].stringValue.trim(),
    logoUrl: json['counterexamples'].stringValue.trim(),
    available: json['clavier'].numValue.toInt() != 0,
    maintenanceMessage: json['joust'].stringValue.trim(),
  );

  final String label;
  final String value;
  final String logoUrl;
  final bool available;
  final String maintenanceMessage;
}

class BindCardField {
  const BindCardField({
    required this.title,
    required this.saveKey,
    required this.placeholder,
    required this.control,
    required this.options,
    required this.required,
    this.numericKeyboard = false,
    this.suggestedValue = '',
    this.initialDisplayValue = '',
    this.initialSubmitValue = '',
  });

  factory BindCardField.fromJson(Json json) => BindCardField(
    title: json['culinarians'].stringValue.trim(),
    saveKey: json['fasciitis'].stringValue.trim(),
    placeholder: json['must'].stringValue.trim(),
    control: switch (json['presentableness'].stringValue.trim().toLowerCase()) {
      'enum' || 'coprince' => BindCardControl.selection,
      _ => BindCardControl.text,
    },
    options: json['rubicund'].listValue
        .map(BindCardOption.fromJson)
        .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
        .toList(growable: false),
    required: json['lambadas'].numValue.toInt() == 0,
    numericKeyboard: json['bobberies'].numValue.toInt() == 1,
    suggestedValue: json['pavilion'].stringValue.trim(),
    initialDisplayValue: _selectedLabel(json),
    initialSubmitValue: _selectedValue(json),
  );

  static String _selectedValue(Json json) {
    final current = json['steeplechases'].stringValue.trim();
    return current;
  }

  static String _selectedLabel(Json json) {
    final current = json['steeplechases'].stringValue.trim();
    if (current.isEmpty) return '';
    for (final option in json['rubicund'].listValue) {
      final value = option['etherifying'].stringValue.trim();
      final label = option['emit'].stringValue.trim();
      if (value == current || label == current) return label;
    }
    return current;
  }

  final String title;
  final String saveKey;
  final String placeholder;
  final BindCardControl control;
  final List<BindCardOption> options;
  final bool required;
  final bool numericKeyboard;
  final String suggestedValue;
  final String initialDisplayValue;
  final String initialSubmitValue;
}

class BindCardGroup {
  const BindCardGroup({
    required this.label,
    required this.type,
    required this.fields,
  });

  factory BindCardGroup.fromJson(Json json) => BindCardGroup(
    label: json['culinarians'].stringValue.trim(),
    type: json['etherifying'].stringValue.trim(),
    fields: json['orographical'].listValue
        .map(BindCardField.fromJson)
        .where((field) => field.saveKey.isNotEmpty && field.title.isNotEmpty)
        .toList(growable: false),
  );

  final String label;
  final String type;
  final List<BindCardField> fields;
}

class BindCardData {
  const BindCardData({
    required this.groups,
    required this.topPrompt,
    required this.bottomPrompt,
  });

  factory BindCardData.fromJson(Object? data) {
    final json = Json(data);
    // ApiClient passes the foresight payload, while direct callers may provide
    // the complete response envelope.
    final payload = json['orographical'].listOrNull == null
        ? json['foresight']
        : json;
    return BindCardData(
      groups: payload['orographical'].listValue
          .map(BindCardGroup.fromJson)
          .where((group) => group.type.isNotEmpty && group.fields.isNotEmpty)
          .toList(growable: false),
      topPrompt: payload['cornbraids'].stringValue.trim(),
      bottomPrompt: payload['zebroid'].stringValue.trim(),
    );
  }

  final List<BindCardGroup> groups;
  final String topPrompt;
  final String bottomPrompt;
}

class BindCardLivenessPayload {
  const BindCardLivenessPayload({
    this.type = '',
    this.livenessId = '',
    this.license = '',
  });

  final String type;
  final String livenessId;
  final String license;
}

class BindCardSubmitResult {
  const BindCardSubmitResult({required this.code, required this.bindId});

  factory BindCardSubmitResult.fromJson(Object? data, String code) {
    return BindCardSubmitResult(
      code: code,
      bindId: Json(data)['overadvertises'].stringValue.trim(),
    );
  }

  final String code;
  final String bindId;
}
