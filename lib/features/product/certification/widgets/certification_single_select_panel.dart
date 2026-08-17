import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/widgets/green_action_panel_dialog.dart';

Future<T?> showCertificationSingleSelectPanel<T>(
  BuildContext context, {
  required List<T> options,
  required String Function(T option) labelBuilder,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final selected = await showDialog<T>(
    context: context,
    barrierColor: AppColors.mineDialogBarrier,
    builder: (_) => CertificationSingleSelectPanel<T>(
      options: options,
      labelBuilder: labelBuilder,
    ),
  );
  FocusManager.instance.primaryFocus?.unfocus();
  return selected;
}

class CertificationSingleSelectPanel<T> extends StatelessWidget {
  const CertificationSingleSelectPanel({
    required this.options,
    required this.labelBuilder,
    super.key,
  });

  static const _maxVisibleOptions = 5;

  final List<T> options;
  final String Function(T option) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final visibleCount = options.length > _maxVisibleOptions
        ? _maxVisibleOptions
        : options.length;
    final itemHeight = context.r(48);
    final itemSpacing = context.r(12);
    final listHeight =
        itemHeight * visibleCount + itemSpacing * (visibleCount - 1);

    return GreenActionPanelDialog(
      key: const Key('certificationSingleSelectDialog'),
      dialogKey: const Key('certificationSingleSelectPanel'),
      closeKey: const Key('certificationSingleSelectPanelClose'),
      closeSemanticLabel: 'Close options',
      actionPanelHeight: 24 + 48 * visibleCount + 12 * (visibleCount - 1),
      actions: [
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            key: const Key('certificationSingleSelectOptions'),
            itemCount: options.length,
            separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
            itemBuilder: (context, index) {
              final option = options[index];
              return SizedBox(
                height: itemHeight,
                child: TextButton(
                  key: Key('certificationSingleSelectOption-$index'),
                  onPressed: () => Navigator.of(context).pop(option),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.certificationSingleSelectText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                  ),
                  child: Text(
                    labelBuilder(option),
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
}
