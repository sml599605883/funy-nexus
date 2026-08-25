import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/risk_report_scene.dart';

class IdentityConfirmationPage extends StatefulWidget {
  const IdentityConfirmationPage({
    required this.productId,
    required this.identityType,
    required this.recognizedInfo,
    this.gateway,
    this.promptMessage,
    this.onSaved,
    super.key,
  });

  final String productId;
  final String identityType;
  final IdentityRecognitionData recognizedInfo;
  final ProductGateway? gateway;
  final String? promptMessage;
  final Future<void> Function()? onSaved;

  @override
  State<IdentityConfirmationPage> createState() =>
      _IdentityConfirmationPageState();
}

class _IdentityConfirmationPageState extends State<IdentityConfirmationPage> {
  static const _prompt =
      'Check your info once more to keep everything on track.';

  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _birthdayController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _idFocusNode;
  final _nameInputKey = GlobalKey();
  final _idInputKey = GlobalKey();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.recognizedInfo.fullName,
    );
    _idController = TextEditingController(text: widget.recognizedInfo.idNumber);
    _birthdayController = TextEditingController(
      text: _normalizeBirthday(widget.recognizedInfo.dateOfBirth),
    );
    _nameFocusNode = FocusNode()..addListener(_ensureNameVisible);
    _idFocusNode = FocusNode()..addListener(_ensureIdVisible);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _birthdayController.dispose();
    _nameFocusNode
      ..removeListener(_ensureNameVisible)
      ..dispose();
    _idFocusNode
      ..removeListener(_ensureIdVisible)
      ..dispose();
    super.dispose();
  }

  void _ensureNameVisible() =>
      _ensureFocusedFieldVisible(_nameFocusNode, _nameInputKey);

  void _ensureIdVisible() =>
      _ensureFocusedFieldVisible(_idFocusNode, _idInputKey);

  void _ensureFocusedFieldVisible(FocusNode focusNode, GlobalKey inputKey) {
    if (!focusNode.hasFocus) return;
    void scroll() {
      if (!mounted || !focusNode.hasFocus) return;
      final fieldContext = inputKey.currentContext;
      if (fieldContext == null) return;
      final scrollable = Scrollable.maybeOf(fieldContext);
      final renderObject = fieldContext.findRenderObject();
      if (scrollable == null || renderObject is! RenderBox) return;
      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      final mediaQuery = MediaQuery.of(fieldContext);
      final safeBottom =
          mediaQuery.size.height - mediaQuery.viewInsets.bottom - context.r(48);
      final overflow = rect.bottom - safeBottom;
      if (overflow <= 0) return;
      final position = scrollable.position;
      final target = (position.pixels + overflow).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      position.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
    Future<void>.delayed(const Duration(milliseconds: 400), scroll);
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.promptMessage?.trim();
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.identityUploadBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Column(
                children: [
                  const CertificationPageHeader(title: 'ID Verification'),
                  Padding(
                    padding: EdgeInsets.only(
                      left: context.r(16),
                      top: context.r(32),
                      right: context.r(172),
                    ),
                    child: CertificationGuidance(
                      key: const Key('identityConfirmationPrompt'),
                      text: prompt == null || prompt.isEmpty ? _prompt : prompt,
                    ),
                  ),
                  SizedBox(height: context.r(32)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        context.r(16),
                        0,
                        context.r(16),
                        context.r(16) + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: _IdentityInformationCard(
                        imageUrl: widget.recognizedInfo.imageUrl,
                        nameController: _nameController,
                        nameFocusNode: _nameFocusNode,
                        nameInputKey: _nameInputKey,
                        idController: _idController,
                        idFocusNode: _idFocusNode,
                        idInputKey: _idInputKey,
                        birthdayController: _birthdayController,
                        onBirthdayTap: _selectBirthday,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.r(16),
              0,
              context.r(16),
              context.r(22),
            ),
            child: _ConfirmationButton(
              enabled: !_isSubmitting,
              onPressed: _submit,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthday() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final initial = _parseBirthday(_birthdayController.text) ?? DateTime.now();
    final date = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.identityDatePickerBarrier,
      builder: (_) => _IdentityDatePicker(initialDate: initial),
    );
    if (date == null || !mounted) return;
    _birthdayController.text =
        '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final gateway = widget.gateway ?? context.read<ProductGateway>();
    final reportService = context.read<ReportService?>();
    setState(() => _isSubmitting = true);
    await EasyLoading.show(status: 'Loading...');
    try {
      await gateway.saveIdentityDocument(
        fullName: _nameController.text.trim(),
        idNumber: _idController.text.trim(),
        dateOfBirth: _birthdayController.text.trim(),
        identityType: widget.identityType,
      );
      RiskReportScene.report(
        reportService,
        productId: widget.productId,
        sceneType: '3',
      );
      await EasyLoading.dismiss();
      if (!mounted) return;
      await widget.onSaved?.call();
      if (mounted && widget.onSaved == null) Navigator.of(context).pop(true);
    } catch (_) {
      await EasyLoading.showError('Unable to save identity information.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  static String _normalizeBirthday(String value) {
    final parts = value.split(RegExp(r'[-/]'));
    if (parts.length != 3) return value;
    if (parts[0].length == 4) {
      return '${parts[2].padLeft(2, '0')}-'
          '${parts[1].padLeft(2, '0')}-${parts[0]}';
    }
    return '${parts[0].padLeft(2, '0')}-'
        '${parts[1].padLeft(2, '0')}-${parts[2]}';
  }

  static DateTime? _parseBirthday(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
  }
}

class _IdentityInformationCard extends StatelessWidget {
  const _IdentityInformationCard({
    required this.imageUrl,
    required this.nameController,
    required this.nameFocusNode,
    required this.nameInputKey,
    required this.idController,
    required this.idFocusNode,
    required this.idInputKey,
    required this.birthdayController,
    required this.onBirthdayTap,
  });

  final String imageUrl;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final GlobalKey nameInputKey;
  final TextEditingController idController;
  final FocusNode idFocusNode;
  final GlobalKey idInputKey;
  final TextEditingController birthdayController;
  final VoidCallback onBirthdayTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('identityConfirmationCard'),
      width: context.r(343),
      padding: EdgeInsets.fromLTRB(
        context.r(12),
        context.r(12),
        context.r(12),
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        children: [
          _IdentityImage(url: imageUrl),
          SizedBox(height: context.r(12)),
          _IdentityField(
            label: 'Full Name',
            controller: nameController,
            focusNode: nameFocusNode,
            inputKey: nameInputKey,
            fieldKey: const Key('identityConfirmationNameInput'),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: context.r(8)),
          _IdentityField(
            label: 'ID No.',
            controller: idController,
            focusNode: idFocusNode,
            inputKey: idInputKey,
            fieldKey: const Key('identityConfirmationIdInput'),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: context.r(8)),
          _IdentityField(
            label: 'Date of Birth',
            controller: birthdayController,
            fieldKey: const Key('identityConfirmationBirthdayInput'),
            readOnly: true,
            showDivider: false,
            onTap: onBirthdayTap,
          ),
        ],
      ),
    );
  }
}

class _IdentityImage extends StatelessWidget {
  const _IdentityImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(8)),
      child: SizedBox(
        key: const Key('identityConfirmationImage'),
        width: context.r(319),
        height: context.r(200),
        child: url.isEmpty
            ? const ColoredBox(color: AppColors.identitySectionGradientEnd)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.identitySectionGradientEnd,
                ),
              ),
      ),
    );
  }
}

class _IdentityField extends StatelessWidget {
  const _IdentityField({
    required this.label,
    required this.controller,
    required this.fieldKey,
    this.textInputAction,
    this.focusNode,
    this.inputKey,
    this.readOnly = false,
    this.showDivider = true,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final Key fieldKey;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final GlobalKey? inputKey;
  final bool readOnly;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.r(56),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: AppColors.identityConfirmationDivider,
                  width: context.r(1),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: context.r(78),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.identityConfirmationLabel,
                fontSize: context.r(14),
                height: 20 / 14,
              ),
            ),
          ),
          Expanded(
            child: KeyedSubtree(
              key: inputKey,
              child: TextField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                readOnly: readOnly,
                onTap: onTap,
                maxLines: 1,
                textAlign: TextAlign.right,
                textInputAction: textInputAction,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: context.r(14),
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationButton extends StatelessWidget {
  const _ConfirmationButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('identityConfirmationSubmit'),
      width: double.infinity,
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
            borderRadius: BorderRadius.circular(context.r(24)),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: Text(
                'Upload',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: context.r(16),
                  fontWeight: FontWeight.w700,
                  height: 19 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityDatePicker extends StatefulWidget {
  const _IdentityDatePicker({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_IdentityDatePicker> createState() => _IdentityDatePickerState();
}

class _IdentityDatePickerState extends State<_IdentityDatePicker> {
  late int _day;
  late int _month;
  late int _year;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate;
    _day = date.day;
    _month = date.month;
    _year = date.year.clamp(1900, DateTime.now().year);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(initialItem: _year - 1900);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.r(1);
    return SizedBox(
      height: context.r(307),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.r(16)),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: context.r(47),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('identityConfirmationDateDone'),
                  onPressed: () => Navigator.of(context).pop(
                    DateTime(
                      _year,
                      _month,
                      _day.clamp(1, _daysInMonth).toInt(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.identityConfirmationLabel,
                    padding: EdgeInsets.only(right: context.r(15)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.identityConfirmationLabel,
                      fontSize: context.r(16),
                      height: 19 / 16,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(child: _dayWheel(scale)),
                      Expanded(child: _monthWheel(scale)),
                      Expanded(child: _yearWheel(scale)),
                    ],
                  ),
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: context.r(52),
                        decoration: const BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: AppColors.divider),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  Widget _dayWheel(double scale) {
    return _wheel(
      controller: _dayController,
      count: 31,
      selected: _day,
      label: (index) => index + 1,
      onChanged: (value) => setState(() => _day = value + 1),
      scale: scale,
    );
  }

  Widget _monthWheel(double scale) {
    return _wheel(
      controller: _monthController,
      count: 12,
      selected: _month,
      label: (index) => index + 1,
      onChanged: (value) {
        setState(() {
          _month = value + 1;
          if (_day > _daysInMonth) _day = _daysInMonth;
        });
      },
      scale: scale,
    );
  }

  Widget _yearWheel(double scale) {
    return _wheel(
      controller: _yearController,
      count: DateTime.now().year - 1899,
      selected: _year,
      label: (index) => index + 1900,
      onChanged: (value) {
        setState(() {
          _year = value + 1900;
          if (_day > _daysInMonth) _day = _daysInMonth;
        });
      },
      scale: scale,
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required int Function(int index) label,
    required ValueChanged<int> onChanged,
    required double scale,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 52 * scale,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (_, index) {
          final value = label(index);
          final isSelected = value == selected;
          return Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.identityConfirmationLabel,
                fontSize: 20 * scale,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                height: 24 / 20,
              ),
            ),
          );
        },
      ),
    );
  }
}
