import 'package:fund_nexus/core/json/json.dart';

enum PersonalInformationControl { selection, text, address, unsupported }

class PersonalInformationOption {
  const PersonalInformationOption({
    required this.label,
    required this.value,
    this.children = const [],
  });

  factory PersonalInformationOption.fromJson(Json json) {
    return PersonalInformationOption(
      label: json['emit'].stringValue.trim(),
      value: json['etherifying'].stringValue.trim(),
      children: json['rubicund'].listValue
          .map(PersonalInformationOption.fromJson)
          .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String label;
  final String value;
  final List<PersonalInformationOption> children;
}

class PersonalInformationField {
  const PersonalInformationField({
    required this.title,
    required this.placeholder,
    required this.saveKey,
    required this.control,
    required this.numericKeyboard,
    required this.isRequired,
    required this.options,
    required this.initialDisplayValue,
    required this.initialSubmitValue,
  });

  factory PersonalInformationField.fromJson(Json json) {
    final rawType = json['presentableness'].stringValue.trim().toLowerCase();
    final control = switch (rawType) {
      'enum' || 'coprince' || 'stepped' => PersonalInformationControl.selection,
      'txt' || 'odometry' || 'onto' => PersonalInformationControl.text,
      'cityselect' ||
      'ballasterlowboy' ||
      'stage' => PersonalInformationControl.address,
      _ => PersonalInformationControl.unsupported,
    };
    final options = json['rubicund'].listValue
        .map(PersonalInformationOption.fromJson)
        .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
        .toList(growable: false);
    final currentValue = json['steeplechases'].stringValue.trim();
    PersonalInformationOption? selectedOption;
    for (final option in options) {
      if (option.label == currentValue || option.value == currentValue) {
        selectedOption = option;
        break;
      }
    }

    return PersonalInformationField(
      title: json['culinarians'].stringValue.trim(),
      placeholder: json['must'].stringValue.trim(),
      saveKey: json['fasciitis'].stringValue.trim(),
      control: control,
      numericKeyboard: json['bobberies'].numValue.toInt() == 1,
      isRequired: json['lambadas'].numValue.toInt() == 0,
      options: options,
      initialDisplayValue: selectedOption?.label ?? currentValue,
      initialSubmitValue: selectedOption?.value ?? currentValue,
    );
  }

  final String title;
  final String placeholder;
  final String saveKey;
  final PersonalInformationControl control;
  final bool numericKeyboard;
  final bool isRequired;
  final List<PersonalInformationOption> options;
  final String initialDisplayValue;
  final String initialSubmitValue;
}

class PersonalInformationData {
  const PersonalInformationData({required this.prompt, required this.fields});

  factory PersonalInformationData.fromJson(Object? data) {
    final json = Json(data);
    final payload = json['orographical'].listOrNull == null
        ? json['foresight']
        : json;
    final fields = payload['orographical'].listValue
        .map(PersonalInformationField.fromJson)
        .where((field) => field.title.isNotEmpty && field.saveKey.isNotEmpty)
        .toList(growable: false);
    return PersonalInformationData(
      prompt:
          (payload['cornbraids'].stringOrNull ??
                  payload['dextrorse'].stringValue)
              .trim(),
      fields: fields,
    );
  }

  final String prompt;
  final List<PersonalInformationField> fields;
}

class PersonalAddressNode {
  const PersonalAddressNode({
    required this.id,
    required this.label,
    required this.children,
  });

  factory PersonalAddressNode.fromJson(Json json) {
    final children =
        json['semihobos'].listOrNull ??
        json['bedtimes'].listOrNull ??
        json['children'].listValue;
    return PersonalAddressNode(
      id: (json['ecclesia'].stringOrNull ?? json['fasciitis'].stringValue)
          .trim(),
      label: json['emit'].stringValue.trim(),
      children: children
          .map(PersonalAddressNode.fromJson)
          .where((node) => node.label.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String id;
  final String label;
  final List<PersonalAddressNode> children;

  static List<PersonalAddressNode> parseList(Object? data) {
    final json = Json(data);
    final nodes =
        json['semihobos'].listOrNull ??
        json['foresight']['semihobos'].listValue;
    return nodes
        .map(PersonalAddressNode.fromJson)
        .where((node) => node.label.isNotEmpty)
        .toList(growable: false);
  }
}
