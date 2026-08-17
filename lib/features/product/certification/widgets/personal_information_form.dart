import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/certification/personal_information_field_state.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

class PersonalInformationForm extends StatelessWidget {
  const PersonalInformationForm({
    required this.fields,
    required this.addressLoadingKey,
    required this.onSelect,
    super.key,
  });

  final List<PersonalInformationFieldState> fields;
  final String? addressLoadingKey;
  final ValueChanged<PersonalInformationFieldState> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.r(16)),
      child: Container(
        key: const Key('personalInformationFormCard'),
        constraints: BoxConstraints(minHeight: context.r(732)),
        padding: EdgeInsets.all(context.r(12)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < fields.length; index++)
              PersonalInformationFieldView(
                field: fields[index],
                isLast: index == fields.length - 1,
                isAddressLoading:
                    fields[index].data.saveKey == addressLoadingKey,
                onTap: () => onSelect(fields[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class PersonalInformationFieldView extends StatelessWidget {
  const PersonalInformationFieldView({
    required this.field,
    required this.isLast,
    required this.isAddressLoading,
    required this.onTap,
    super.key,
  });

  final PersonalInformationFieldState field;
  final bool isLast;
  final bool isAddressLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = field.data;
    final isText = data.control == PersonalInformationControl.text;
    return PersonalInformationFieldShell(
      label: data.title,
      bottomPadding: isLast ? 0 : null,
      child: isText
          ? PersonalInformationInputField(field: field)
          : PersonalInformationSelectField(
              field: field,
              isAddressLoading: isAddressLoading,
              onTap: onTap,
            ),
    );
  }
}

class PersonalInformationInputField extends StatelessWidget {
  const PersonalInformationInputField({required this.field, super.key});

  final PersonalInformationFieldState field;

  @override
  Widget build(BuildContext context) => Container(
    height: context.r(48),
    padding: EdgeInsets.symmetric(horizontal: context.r(12)),
    decoration: BoxDecoration(
      color: AppColors.mineItemBackground,
      borderRadius: BorderRadius.circular(context.r(4)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: Key('personalInformationInput-${field.data.saveKey}'),
            controller: field.controller,
            keyboardType: field.data.numericKeyboard
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: field.data.placeholder,
              hintStyle: TextStyle(
                color: AppColors.personalInformationPlaceholder,
                fontSize: context.r(14),
              ),
              border: InputBorder.none,
              isDense: true,
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: context.r(14),
            ),
          ),
        ),
      ],
    ),
  );
}

class PersonalInformationSelectField extends StatelessWidget {
  const PersonalInformationSelectField({
    required this.field,
    required this.isAddressLoading,
    required this.onTap,
    super.key,
  });

  final PersonalInformationFieldState field;
  final bool isAddressLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = field.controller.text.isEmpty;
    return InkWell(
      key: Key('personalInformation-${field.data.saveKey}'),
      onTap: field.data.control == PersonalInformationControl.unsupported
          ? null
          : onTap,
      borderRadius: BorderRadius.circular(context.r(4)),
      child: PersonalInformationFieldValue(
        value: isPlaceholder ? field.data.placeholder : field.controller.text,
        isPlaceholder: isPlaceholder,
        showChevron: !isAddressLoading,
        trailing: isAddressLoading
            ? SizedBox(
                width: context.r(18),
                height: context.r(18),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }
}

class PersonalInformationFieldShell extends StatelessWidget {
  const PersonalInformationFieldShell({
    required this.label,
    required this.child,
    this.bottomPadding,
    super.key,
  });

  final String label;
  final Widget child;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.r(bottomPadding ?? 12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: context.r(16),
            fontWeight: FontWeight.w600,
            height: 22 / 16,
          ),
        ),
        SizedBox(height: context.r(8)),
        child,
      ],
    ),
  );
}

class PersonalInformationFieldValue extends StatelessWidget {
  const PersonalInformationFieldValue({
    required this.value,
    required this.isPlaceholder,
    required this.showChevron,
    this.trailing,
    super.key,
  });

  final String value;
  final bool isPlaceholder;
  final bool showChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    height: context.r(48),
    padding: EdgeInsets.symmetric(horizontal: context.r(12)),
    decoration: BoxDecoration(
      color: AppColors.mineItemBackground,
      borderRadius: BorderRadius.circular(context.r(4)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPlaceholder
                  ? AppColors.personalInformationPlaceholder
                  : AppColors.textPrimary,
              fontSize: context.r(14),
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (showChevron)
          Image.asset(
            AppAssets.mineChevron,
            width: context.r(7),
            height: context.r(11),
          ),
      ],
    ),
  );
}

class PersonalInformationFormStatus extends StatelessWidget {
  const PersonalInformationFormStatus({
    required this.message,
    this.showProgress = false,
    this.onRetry,
    super.key,
  });

  final String message;
  final bool showProgress;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('personalInformationStatus'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.r(732)),
      padding: EdgeInsets.all(context.r(24)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress) const CircularProgressIndicator(),
          if (showProgress) SizedBox(height: context.r(16)),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            SizedBox(height: context.r(16)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class PersonalInformationSubmitButton extends StatelessWidget {
  const PersonalInformationSubmitButton({
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.r(52),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(24)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.identityUploadButtonShadow,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            AppColors.homeApplyButtonStart,
            AppColors.homeApplyButtonEnd,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(context.r(24)),
          child: Center(
            child: Text(
              'Upload',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: context.r(16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
