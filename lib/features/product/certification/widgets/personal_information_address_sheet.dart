import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

class PersonalInformationAddressOptionsSheet extends StatefulWidget {
  const PersonalInformationAddressOptionsSheet({
    required this.nodes,
    required this.initialValue,
    required this.onSelected,
    super.key,
  });

  final List<PersonalAddressNode> nodes;
  final String initialValue;
  final ValueChanged<String> onSelected;

  @override
  State<PersonalInformationAddressOptionsSheet> createState() =>
      _PersonalInformationAddressOptionsSheetState();
}

class _PersonalInformationAddressOptionsSheetState
    extends State<PersonalInformationAddressOptionsSheet> {
  PersonalAddressNode? _region;
  PersonalAddressNode? _province;
  _AddressLevel _activeLevel = _AddressLevel.region;

  @override
  void initState() {
    super.initState();
    _restoreInitialValue();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        key: const Key('personalInformationAddressSelectionSheet'),
        height: context.r(464),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(context.r(12)),
              child: Row(
                children: [
                  for (final level in _AddressLevel.values)
                    Expanded(
                      child: TextButton(
                        onPressed: () => _selectLevel(level),
                        child: Text(_labelFor(level)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: const Key('personalInformationAddressOptions'),
                itemCount: _activeOptions.length,
                itemBuilder: (context, index) {
                  final option = _activeOptions[index];
                  return ListTile(
                    key: Key('personalInformationAddressOption-${option.id}'),
                    title: Text(option.label),
                    onTap: () => _selectNode(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PersonalAddressNode> get _activeOptions => switch (_activeLevel) {
    _AddressLevel.region => widget.nodes,
    _AddressLevel.province => _region?.children ?? const [],
    _AddressLevel.municipality => _province?.children ?? const [],
  };

  String _labelFor(_AddressLevel level) => switch (level) {
    _AddressLevel.region => _region?.label ?? 'Region',
    _AddressLevel.province => _province?.label ?? 'Province',
    _AddressLevel.municipality => 'Municipality',
  };

  void _selectLevel(_AddressLevel level) {
    if (level == _AddressLevel.province && _region == null) return;
    if (level == _AddressLevel.municipality && _province == null) return;
    setState(() => _activeLevel = level);
  }

  void _selectNode(PersonalAddressNode node) {
    switch (_activeLevel) {
      case _AddressLevel.region:
        setState(() {
          _region = node;
          _province = null;
          _activeLevel = _AddressLevel.province;
        });
      case _AddressLevel.province:
        setState(() {
          _province = node;
          _activeLevel = _AddressLevel.municipality;
        });
      case _AddressLevel.municipality:
        final region = _region;
        final province = _province;
        if (region == null || province == null) return;
        widget.onSelected('${region.label}-${province.label}-${node.label}');
    }
  }

  void _restoreInitialValue() {
    final labels = widget.initialValue
        .split('-')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) return;
    _region = _findByLabel(widget.nodes, labels.first);
    if (_region == null || labels.length < 2) {
      _activeLevel = _AddressLevel.region;
      return;
    }
    _province = _findByLabel(_region!.children, labels[1]);
    _activeLevel = _province == null || labels.length < 3
        ? _AddressLevel.province
        : _AddressLevel.municipality;
  }

  PersonalAddressNode? _findByLabel(
    List<PersonalAddressNode> nodes,
    String label,
  ) {
    for (final node in nodes) {
      if (node.label == label) return node;
    }
    return null;
  }
}

enum _AddressLevel { region, province, municipality }
