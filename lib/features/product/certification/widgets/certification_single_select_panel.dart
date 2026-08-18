import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/widgets/green_action_panel_dialog.dart';

Future<T?> showCertificationSingleSelectPanel<T>(
  BuildContext context, {
  required List<T> options,
  required String Function(T option) labelBuilder,
  Widget? Function(T option)? leadingBuilder,
  String Function(T option)? secondaryLabelBuilder,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final selected = await showDialog<T>(
    context: context,
    barrierColor: AppColors.mineDialogBarrier,
    builder: (_) => CertificationSingleSelectPanel<T>(
      options: options,
      labelBuilder: labelBuilder,
      leadingBuilder: leadingBuilder,
      secondaryLabelBuilder: secondaryLabelBuilder,
    ),
  );
  FocusManager.instance.primaryFocus?.unfocus();
  return selected;
}

class CertificationSingleSelectPanel<T> extends StatelessWidget {
  const CertificationSingleSelectPanel({
    required this.options,
    required this.labelBuilder,
    this.leadingBuilder,
    this.secondaryLabelBuilder,
    super.key,
  });

  static const _maxVisibleOptions = 5;

  final List<T> options;
  final String Function(T option) labelBuilder;
  final Widget? Function(T option)? leadingBuilder;
  final String Function(T option)? secondaryLabelBuilder;

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
              final secondaryLabel = secondaryLabelBuilder?.call(option) ?? '';
              final leading = leadingBuilder?.call(option);
              return SizedBox(
                height: itemHeight,
                child: Semantics(
                  button: true,
                  label: secondaryLabel.isEmpty
                      ? labelBuilder(option)
                      : '${labelBuilder(option)}, $secondaryLabel',
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(context.r(8)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: Key('certificationSingleSelectOption-$index'),
                      onTap: () => Navigator.of(context).pop(option),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.r(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (leading != null) ...[
                                SizedBox(
                                  width: context.r(20),
                                  height: context.r(20),
                                  child: leading,
                                ),
                                SizedBox(width: context.r(12)),
                              ],
                              secondaryLabel.isEmpty
                                  ? Text(
                                      labelBuilder(option),
                                      style: _labelStyle(context),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          labelBuilder(option),
                                          style: _labelStyle(context),
                                        ),
                                        Text(
                                          secondaryLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors
                                                .certificationSingleSelectMaintenance,
                                            fontSize: context.r(10),
                                            fontWeight: FontWeight.w700,
                                            height: 12 / 10,
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
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

  TextStyle _labelStyle(BuildContext context) => TextStyle(
    color: AppColors.certificationSingleSelectText,
    fontSize: context.r(16),
    fontWeight: FontWeight.w400,
    height: 22 / 16,
  );
}
