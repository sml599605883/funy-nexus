import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

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
    final visibleCount = options.length.clamp(1, _maxVisibleOptions);
    final itemHeight = context.r(48);
    final itemSpacing = context.r(12);
    final listHeight =
        itemHeight * visibleCount + itemSpacing * (visibleCount - 1);

    return Dialog(
      key: const Key('certificationSingleSelectDialog'),
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: context.r(319),
        padding: EdgeInsets.all(context.r(12)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: SizedBox(
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
      ),
    );
  }
}
