import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({required this.productId, super.key});

  final String productId;

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _homePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _values = <String, String>{
    'Gender': 'Female',
    'Type of Residence': 'Female',
  };
  bool _submitting = false;

  static const _options = <String, List<String>>{
    'Gender': ['Female', 'Male'],
    'Education': ['High school', 'College', 'Postgraduate'],
    'Marriage Status': ['Single', 'Married'],
    'Type of Residence': ['Owned', 'Rented', 'Family home'],
    'Address Input': ['Metro Manila', 'Luzon', 'Visayas', 'Mindanao'],
    'Reason for Loan': ['Medical', 'Education', 'Home improvement', 'Business'],
  };

  @override
  void dispose() {
    _homePhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guidance = context.read<SessionStore>().productDetailIdentityGuidance;
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.identityUploadBackground,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: context.r(92)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.r(16),
                      context.r(24),
                      context.r(172),
                      0,
                    ),
                    child: SizedBox(
                      key: const Key('personalInformationGuidance'),
                      height: context.r(57),
                      child: Text(
                        guidance.isEmpty
                            ? 'Add your work details to\nhelp us assess your\navailable credit limit.'
                            : guidance,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.identityUploadGuidance,
                          fontSize: context.r(16),
                          fontWeight: FontWeight.w700,
                          height: 19 / 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.r(41)),
                  const Center(child: _Progress()),
                  Transform.translate(
                    offset: Offset(0, -context.r(27)),
                    child: _FormCard(
                      values: _values,
                      homePhoneController: _homePhoneController,
                      addressController: _addressController,
                      onSelect: _select,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.r(16),
            context.r(14),
            context.r(16),
            context.r(14),
          ),
          child: _UploadButton(enabled: !_submitting, onPressed: _submit),
        ),
      ),
    );
  }

  Future<void> _select(String label) async {
    final choices = _options[label];
    if (choices == null) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ...choices.map(
              (choice) => ListTile(
                title: Text(choice),
                trailing: _values[label] == choice
                    ? const Icon(
                        Icons.check,
                        color: AppColors.homeApplyButtonEnd,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(choice),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _values[label] = selected);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final missing = _options.keys.any((key) => !_values.containsKey(key));
    if (missing ||
        _homePhoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please complete your information.')),
        );
      return;
    }
    setState(() => _submitting = true);
    await EasyLoading.show(status: 'Loading...');
    // The personal-information API contract is server-driven and will be wired
    // here once its documented endpoint is available.
    await EasyLoading.dismiss();
    if (!mounted) return;
    setState(() => _submitting = false);
    await _continue();
  }

  Future<void> _continue() async {
    if (!mounted) return;
    final flow = context.read<ProductApplicationFlow>();
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => _PersonalInformationContinuation(
          flow: flow,
          productId: widget.productId,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.r(60),
      child: Row(
        children: [
          SizedBox(width: context.r(24)),
          SizedBox(
            width: context.r(24),
            height: context.r(24),
            child: IconButton(
              key: const Key('personalInformationBack'),
              onPressed: onBack,
              icon: Image.asset(AppAssets.identityBackButton),
              padding: EdgeInsets.zero,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Basic identity information',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: context.r(17),
                  fontWeight: FontWeight.w600,
                  height: 24 / 17,
                ),
              ),
            ),
          ),
          SizedBox(width: context.r(48)),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('personalInformationProgress'),
      width: context.r(343),
      height: context.r(67),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(12)),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.personalProgressBackgroundStart,
              AppColors.surface,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.r(12),
            context.r(12),
            context.r(12),
            context.r(31),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (_) => Container(
                    width: context.r(50),
                    height: context.r(6),
                    color: AppColors.personalProgressTrack,
                  ),
                ),
              ),
              SizedBox(height: context.r(4)),
              SizedBox(
                height: context.r(14),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: context.r(14),
                    right: context.r(11),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['25%', '50%', '75%', '100%']
                        .map(
                          (value) => Text(
                            value,
                            style: TextStyle(
                              color: AppColors.personalProgressTrack,
                              fontSize: context.r(10),
                              fontWeight: FontWeight.w600,
                              height: 14 / 10,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.values,
    required this.homePhoneController,
    required this.addressController,
    required this.onSelect,
  });
  final Map<String, String> values;
  final TextEditingController homePhoneController;
  final TextEditingController addressController;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _SelectField(
        label: 'Gender',
        value: values['Gender'],
        onTap: () => onSelect('Gender'),
      ),
      _SelectField(
        label: 'Education',
        value: values['Education'],
        onTap: () => onSelect('Education'),
      ),
      _SelectField(
        label: 'Marriage Status',
        value: values['Marriage Status'],
        onTap: () => onSelect('Marriage Status'),
      ),
      _SelectField(
        label: 'Type of Residence',
        value: values['Type of Residence'],
        onTap: () => onSelect('Type of Residence'),
      ),
      _InputField(
        label: 'Home Phone Number',
        controller: homePhoneController,
        prefix: '0321',
      ),
      _SelectField(
        label: 'Address Input',
        value: values['Address Input'],
        onTap: () => onSelect('Address Input'),
      ),
      _InputField(label: 'Complete Address', controller: addressController),
      _SelectField(
        label: 'Reason for Loan',
        value: values['Reason for Loan'],
        onTap: () => onSelect('Reason for Loan'),
        isLast: true,
      ),
    ];
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
          children: fields,
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) => _FieldShell(
    label: label,
    bottomPadding: isLast ? 0 : null,
    child: InkWell(
      key: Key('personalInformation-$label'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(4)),
      child: _FieldValue(value: value ?? 'Please select', showChevron: true),
    ),
  );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.prefix,
  });
  final String label;
  final TextEditingController controller;
  final String? prefix;

  @override
  Widget build(BuildContext context) => _FieldShell(
    label: label,
    child: Container(
      height: context.r(48),
      padding: EdgeInsets.symmetric(horizontal: context.r(12)),
      decoration: BoxDecoration(
        color: AppColors.mineItemBackground,
        borderRadius: BorderRadius.circular(context.r(4)),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[
            Text(
              prefix!,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: context.r(14),
              ),
            ),
            SizedBox(width: context.r(8)),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                hintText: 'Please enter',
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
    ),
  );
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.child,
    this.bottomPadding,
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

class _FieldValue extends StatelessWidget {
  const _FieldValue({required this.value, required this.showChevron});
  final String value;
  final bool showChevron;
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
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: context.r(14),
          ),
        ),
        if (showChevron)
          Image.asset(
            AppAssets.mineChevron,
            width: context.r(7),
            height: context.r(11),
          ),
      ],
    ),
  );
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.enabled, required this.onPressed});
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

class _PersonalInformationContinuation extends StatefulWidget {
  const _PersonalInformationContinuation({
    required this.flow,
    required this.productId,
  });
  final ProductApplicationFlow flow;
  final String productId;
  @override
  State<_PersonalInformationContinuation> createState() =>
      _PersonalInformationContinuationState();
}

class _PersonalInformationContinuationState
    extends State<_PersonalInformationContinuation> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
  }

  Future<void> _continue() async {
    await widget.flow.resumeAfterCertification(
      productId: widget.productId,
      openTarget: (target) async {
        if (mounted) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ProductWebPage(url: target),
            ),
          );
        }
      },
      openCertification: (step, productId) async {
        if (mounted) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  CertificationHandoffPage(productId: productId, step: step),
            ),
          );
        }
      },
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: EasyLoading.dismiss,
      showMessage: (message) async {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
