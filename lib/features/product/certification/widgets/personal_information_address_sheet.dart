import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

Future<String?> showPersonalInformationAddressOptionsSheet({
  required BuildContext context,
  required List<PersonalAddressNode> nodes,
  String initialValue = '',
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.addressPickerBarrier,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(16))),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => PersonalInformationAddressOptionsSheet(
      nodes: nodes,
      initialValue: initialValue,
    ),
  );
}

class PersonalInformationAddressOptionsSheet extends StatefulWidget {
  const PersonalInformationAddressOptionsSheet({
    required this.nodes,
    this.initialValue = '',
    super.key,
  });

  final List<PersonalAddressNode> nodes;
  final String initialValue;

  @override
  State<PersonalInformationAddressOptionsSheet> createState() =>
      _PersonalInformationAddressOptionsSheetState();
}

class _PersonalInformationAddressOptionsSheetState
    extends State<PersonalInformationAddressOptionsSheet> {
  PersonalAddressNode? _region;
  PersonalAddressNode? _province;
  PersonalAddressNode? _municipality;
  _AddressLevel _activeLevel = _AddressLevel.region;

  @override
  void initState() {
    super.initState();
    _restoreInitialValue();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('personalInformationAddressSelectionSheet'),
    width: double.infinity,
    height: context.r(464),
    child: SafeArea(
      top: false,
      child: Stack(
        children: [
          Positioned(
            top: context.r(45),
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              AppAssets.addressPickerOptionsBackground,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            top: context.r(21),
            right: context.r(15),
            child: GestureDetector(
              key: const Key('personalInformationAddressClose'),
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                AppAssets.addressPickerClose,
                width: context.r(24),
                height: context.r(24),
              ),
            ),
          ),
          Positioned(
            top: context.r(56),
            left: context.r(12),
            right: context.r(12),
            child: _AddressProgressPanel(
              activeLevel: _activeLevel,
              regionLabel: _region?.label ?? 'Region',
              provinceLabel: _province?.label ?? 'Province',
              municipalityLabel: _municipality?.label ?? 'Municipality',
              provinceEnabled: _region != null,
              municipalityEnabled: _province != null,
              onLevelSelected: _selectLevel,
            ),
          ),
          Positioned(
            top: context.r(201),
            left: 0,
            right: 0,
            bottom: 0,
            child: _AddressOptions(
              key: ValueKey('$_activeLevel-${_selectedNode?.id ?? ''}'),
              level: _activeLevel,
              options: _activeOptions,
              selectedNode: _selectedNode,
              onSelected: _selectNode,
            ),
          ),
        ],
      ),
    ),
  );

  List<PersonalAddressNode> get _activeOptions => switch (_activeLevel) {
    _AddressLevel.region => widget.nodes,
    _AddressLevel.province => _region?.children ?? const [],
    _AddressLevel.municipality => _province?.children ?? const [],
  };

  PersonalAddressNode? get _selectedNode => switch (_activeLevel) {
    _AddressLevel.region => _region,
    _AddressLevel.province => _province,
    _AddressLevel.municipality => _municipality,
  };

  void _restoreInitialValue() {
    final labels = widget.initialValue
        .split('-')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) return;

    _region = _findByLabel(widget.nodes, labels.first);
    if (_region == null || labels.length == 1) {
      _activeLevel = _region == null
          ? _AddressLevel.region
          : _AddressLevel.province;
      return;
    }
    _province = _findByLabel(_region!.children, labels[1]);
    if (_province == null || labels.length == 2) {
      _activeLevel = _province == null
          ? _AddressLevel.province
          : _AddressLevel.municipality;
      return;
    }
    _municipality = _findByLabel(_province!.children, labels[2]);
    _activeLevel = _AddressLevel.municipality;
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

  void _selectLevel(_AddressLevel level) {
    if (level == _AddressLevel.province && _region == null) return;
    if (level == _AddressLevel.municipality && _province == null) return;
    setState(() {
      _activeLevel = level;
      switch (level) {
        case _AddressLevel.region:
          _province = null;
          _municipality = null;
        case _AddressLevel.province:
          _municipality = null;
        case _AddressLevel.municipality:
          break;
      }
    });
  }

  void _selectNode(PersonalAddressNode node) {
    switch (_activeLevel) {
      case _AddressLevel.region:
        setState(() {
          _region = node;
          _province = null;
          _municipality = null;
          _activeLevel = _AddressLevel.province;
        });
      case _AddressLevel.province:
        setState(() {
          _province = node;
          _municipality = null;
          _activeLevel = _AddressLevel.municipality;
        });
      case _AddressLevel.municipality:
        final region = _region;
        final province = _province;
        if (region == null || province == null) return;
        Navigator.of(
          context,
        ).pop('${region.label}-${province.label}-${node.label}');
    }
  }
}

class _AddressProgressPanel extends StatelessWidget {
  const _AddressProgressPanel({
    required this.activeLevel,
    required this.regionLabel,
    required this.provinceLabel,
    required this.municipalityLabel,
    required this.provinceEnabled,
    required this.municipalityEnabled,
    required this.onLevelSelected,
  });

  final _AddressLevel activeLevel;
  final String regionLabel;
  final String provinceLabel;
  final String municipalityLabel;
  final bool provinceEnabled;
  final bool municipalityEnabled;
  final ValueChanged<_AddressLevel> onLevelSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(121),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.addressPickerPanel,
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Stack(
        children: [
          _connector(context, _AddressLevel.province, 21, 39),
          _connector(context, _AddressLevel.municipality, 60, 41),
          _indicator(context, _AddressLevel.region, 17),
          _indicator(context, _AddressLevel.province, 56),
          _indicator(context, _AddressLevel.municipality, 97),
          _step(context, _AddressLevel.region, regionLabel, 9, true),
          _step(
            context,
            _AddressLevel.province,
            provinceLabel,
            48,
            provinceEnabled,
          ),
          _step(
            context,
            _AddressLevel.municipality,
            municipalityLabel,
            89,
            municipalityEnabled,
          ),
        ],
      ),
    ),
  );

  Widget _connector(
    BuildContext context,
    _AddressLevel targetLevel,
    double top,
    double height,
  ) => Positioned(
    top: context.r(top),
    left: context.r(24),
    width: context.r(2),
    height: context.r(height),
    child: ColoredBox(
      key: Key('personalInformationAddressStepLine_${targetLevel.name}'),
      color: targetLevel.index <= activeLevel.index
          ? AppColors.addressPickerActive
          : AppColors.surface,
    ),
  );

  Widget _indicator(BuildContext context, _AddressLevel level, double top) =>
      Positioned(
        top: context.r(top),
        left: context.r(21),
        width: context.r(8),
        height: context.r(8),
        child: DecoratedBox(
          key: Key('personalInformationAddressStepIndicator_${level.name}'),
          decoration: BoxDecoration(
            color: level.index <= activeLevel.index
                ? AppColors.addressPickerActive
                : AppColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget _step(
    BuildContext context,
    _AddressLevel level,
    String label,
    double top,
    bool enabled,
  ) => Positioned(
    top: context.r(top),
    left: context.r(74),
    right: context.r(20),
    height: context.r(24),
    child: InkWell(
      key: Key('personalInformationAddressStep_${level.name}'),
      onTap: enabled ? () => onLevelSelected(level) : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              key: Key('personalInformationAddressStepLabel_${level.name}'),
              style: TextStyle(
                color: activeLevel == level
                    ? AppColors.addressPickerActive
                    : AppColors.addressPickerLabel,
                fontSize: context.r(14),
                fontWeight: activeLevel == level
                    ? FontWeight.w700
                    : FontWeight.w400,
                height: 18 / 14,
              ),
            ),
          ),
          Image.asset(
            AppAssets.addressPickerChevron,
            width: context.r(13),
            height: context.r(13),
          ),
        ],
      ),
    ),
  );
}

class _AddressOptions extends StatefulWidget {
  const _AddressOptions({
    required this.level,
    required this.options,
    required this.selectedNode,
    required this.onSelected,
    super.key,
  });

  final _AddressLevel level;
  final List<PersonalAddressNode> options;
  final PersonalAddressNode? selectedNode;
  final ValueChanged<PersonalAddressNode> onSelected;

  @override
  State<_AddressOptions> createState() => _AddressOptionsState();
}

class _AddressOptionsState extends State<_AddressOptions> {
  late int _selectedIndex;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialIndex();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) {
      return Center(
        key: Key('personalInformationAddressOptions_${widget.level.name}'),
        child: Text(
          'No ${_levelLabel(widget.level)} available',
          style: TextStyle(
            color: AppColors.addressPickerMuted,
            fontSize: context.r(18),
          ),
        ),
      );
    }

    return ListWheelScrollView.useDelegate(
      key: Key('personalInformationAddressOptions_${widget.level.name}'),
      controller: _controller,
      itemExtent: context.r(52),
      diameterRatio: 1000,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => setState(() => _selectedIndex = index),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.options.length,
        builder: (context, index) {
          final option = widget.options[index];
          final distance = (index - _selectedIndex).abs();
          final selected = distance == 0;
          return InkWell(
            key: selected
                ? Key(
                    'personalInformationAddressOptionSelected_${option.label}',
                  )
                : null,
            onTap: () => widget.onSelected(option),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: selected
                    ? const Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.addressPickerDivider,
                        ),
                      )
                    : null,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.r(24)),
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.addressPickerSelected
                          : distance == 1
                          ? AppColors.addressPickerOption
                          : AppColors.addressPickerMuted,
                      fontSize: context.r(18),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      height: 20 / 18,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _initialIndex() {
    final selected = widget.selectedNode;
    if (selected == null) return 0;
    final index = widget.options.indexWhere((item) => item.id == selected.id);
    return index < 0 ? 0 : index;
  }

  String _levelLabel(_AddressLevel level) => switch (level) {
    _AddressLevel.region => 'Region',
    _AddressLevel.province => 'Province',
    _AddressLevel.municipality => 'Municipality',
  };
}

enum _AddressLevel { region, province, municipality }
