import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/widgets/green_action_panel_dialog.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

class PersonalInformationSalarySelection {
  const PersonalInformationSalarySelection({
    required this.group,
    required this.option,
  });

  final PersonalInformationOption group;
  final PersonalInformationOption option;

  String get displayValue => '${group.label}|${option.label}';
  String get submitValue => option.value;
}

Future<PersonalInformationSalarySelection?> showCertificationSalaryDayPanel(
  BuildContext context, {
  required List<PersonalInformationOption> options,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final selected = await showDialog<PersonalInformationSalarySelection>(
    context: context,
    barrierColor: AppColors.mineDialogBarrier,
    builder: (_) => CertificationSalaryDayPanel(options: options),
  );
  FocusManager.instance.primaryFocus?.unfocus();
  return selected;
}

class CertificationSalaryDayPanel extends StatefulWidget {
  const CertificationSalaryDayPanel({required this.options, super.key});

  static const maxVisibleOptions = 5;

  final List<PersonalInformationOption> options;

  @override
  State<CertificationSalaryDayPanel> createState() =>
      _CertificationSalaryDayPanelState();
}

class _CertificationSalaryDayPanelState
    extends State<CertificationSalaryDayPanel> {
  PersonalInformationOption? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final options = _selectedGroup == null
        ? widget.options
        : _selectedGroup!.children;
    final visibleCount = options.length.clamp(
      0,
      CertificationSalaryDayPanel.maxVisibleOptions,
    );
    final itemHeight = context.r(48);
    final itemSpacing = context.r(12);
    final listHeight = visibleCount == 0
        ? 0.0
        : itemHeight * visibleCount + itemSpacing * (visibleCount - 1);

    return GreenActionPanelDialog(
      key: const Key('certificationSalaryDayDialog'),
      dialogKey: const Key('certificationSalaryDayPanel'),
      closeKey: const Key('certificationSalaryDayPanelClose'),
      closeSemanticLabel: 'Close salary day options',
      actionPanelHeight: 24 + 48 * visibleCount + 12 * (visibleCount - 1),
      actions: [
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            key: const Key('certificationSalaryDayOptions'),
            itemCount: options.length,
            separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
            itemBuilder: (context, index) {
              final option = options[index];
              return SizedBox(
                height: itemHeight,
                child: TextButton(
                  key: Key('certificationSalaryDayOption-$index'),
                  onPressed: () => _select(option),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.certificationSingleSelectText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: AppColors.certificationSingleSelectText,
                      fontSize: context.r(16),
                      fontWeight: FontWeight.w400,
                      height: 22 / 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _select(PersonalInformationOption option) {
    final group = _selectedGroup;
    if (group == null) {
      if (option.children.isNotEmpty) {
        setState(() => _selectedGroup = option);
      }
      return;
    }
    Navigator.of(
      context,
    ).pop(PersonalInformationSalarySelection(group: group, option: option));
  }
}
