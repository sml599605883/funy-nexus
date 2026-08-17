import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_single_select_panel.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({
    required this.productId,
    this.gateway,
    super.key,
  });

  final String productId;
  final PersonalInformationGateway? gateway;

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  _PersonalInformationLoadState _loadState =
      _PersonalInformationLoadState.loading;
  List<_PersonalInformationFieldState> _fields = const [];
  List<PersonalAddressNode>? _addressNodes;
  String _prompt = '';
  String _loadError = '';
  String? _addressLoadingKey;
  bool _submitting = false;

  PersonalInformationGateway get _gateway =>
      widget.gateway ?? context.read<PersonalInformationGateway>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _disposeFields(_fields);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cachedGuidance = context
        .read<SessionStore>()
        .productDetailIdentityGuidance;
    final guidance = cachedGuidance.isEmpty && _prompt.isEmpty
        ? 'Add your work details to\nhelp us assess your\navailable credit limit.'
        : cachedGuidance.isNotEmpty
        ? cachedGuidance
        : _prompt;
    final busy =
        _loadState == _PersonalInformationLoadState.loading ||
        _submitting ||
        _addressLoadingKey != null;
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
            child: GestureDetector(
              key: const Key('personalInformationDismissKeyboard'),
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: context.r(92)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CertificationPageHeader(
                      title: 'Basic identity information',
                      onBack: () => Navigator.of(context).maybePop(),
                      backButtonKey: const Key('personalInformationBack'),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.r(16),
                        context.r(24),
                        context.r(172),
                        0,
                      ),
                      child: CertificationGuidance(
                        key: const Key('personalInformationGuidance'),
                        text: guidance.isEmpty
                            ? 'Add your work details to\nhelp us assess your\navailable credit limit.'
                            : guidance,
                      ),
                    ),
                    SizedBox(height: context.r(41)),
                    const Center(child: _Progress()),
                    Transform.translate(
                      offset: Offset(0, -context.r(27)),
                      child: _buildForm(context),
                    ),
                  ],
                ),
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
          child: _UploadButton(
            enabled:
                _loadState == _PersonalInformationLoadState.content && !busy,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return switch (_loadState) {
      _PersonalInformationLoadState.loading => _FormStatus(
        message: 'Loading...',
        showProgress: true,
      ),
      _PersonalInformationLoadState.empty => _FormStatus(
        message: 'No personal information available',
        onRetry: _load,
      ),
      _PersonalInformationLoadState.error => _FormStatus(
        message: _loadError,
        onRetry: _load,
      ),
      _PersonalInformationLoadState.content => _FormCard(
        fields: _fields,
        addressLoadingKey: _addressLoadingKey,
        onSelect: _selectField,
      ),
    };
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loadState = _PersonalInformationLoadState.loading;
        _loadError = '';
      });
    }
    try {
      final data = await _gateway.fetchPersonalInformation(widget.productId);
      final fields = data.fields
          .map(_PersonalInformationFieldState.new)
          .toList(growable: false);
      if (!mounted) {
        _disposeFields(fields);
        return;
      }
      setState(() {
        _disposeFields(_fields);
        _fields = fields;
        _prompt = data.prompt;
        _loadState = fields.isEmpty
            ? _PersonalInformationLoadState.empty
            : _PersonalInformationLoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _disposeFields(_fields);
        _fields = const [];
        _loadError = _messageFor(error);
        _loadState = _PersonalInformationLoadState.error;
      });
    }
  }

  Future<void> _selectField(_PersonalInformationFieldState field) async {
    switch (field.data.control) {
      case PersonalInformationControl.selection:
        await _selectOption(field);
      case PersonalInformationControl.address:
        await _selectAddress(field);
      case PersonalInformationControl.text:
      case PersonalInformationControl.unsupported:
        return;
    }
  }

  Future<void> _selectOption(_PersonalInformationFieldState field) async {
    final selected =
        await showCertificationSingleSelectPanel<PersonalInformationOption>(
          context,
          options: field.data.options,
          labelBuilder: (choice) => choice.label,
        );
    if (selected != null && mounted) {
      setState(() {
        field.submitValue = selected.value;
        field.controller.text = selected.label;
      });
    }
  }

  Future<void> _selectAddress(_PersonalInformationFieldState field) async {
    if (_addressLoadingKey != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _addressLoadingKey = field.data.saveKey);
    try {
      _addressNodes ??= await _gateway.fetchPersonalInformationAddresses();
      if (!mounted) return;
      final nodes = _addressNodes!;
      if (nodes.isEmpty) {
        throw const ApiException(
          type: ApiFailureType.invalidResponse,
          message: 'No address options available.',
        );
      }
      final selected = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surface,
        builder: (sheetContext) => _AddressOptionsSheet(
          nodes: nodes,
          initialValue: field.submitValue,
          onSelected: (value) => Navigator.of(sheetContext).pop(value),
        ),
      );
      if (selected != null && mounted) {
        setState(() {
          field.submitValue = selected;
          field.controller.text = selected;
        });
      }
    } catch (error) {
      if (mounted) {
        await EasyLoading.showError(
          _messageFor(error, fallback: 'Unable to load address options.'),
        );
      }
    } finally {
      if (mounted) setState(() => _addressLoadingKey = null);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final fields = <String, String>{
      for (final field in _fields) field.data.saveKey: field.currentSubmitValue,
    };
    setState(() => _submitting = true);
    try {
      await EasyLoading.show(status: 'Loading...');
      await _gateway.savePersonalInformation(
        productId: widget.productId,
        fields: fields,
      );
      await EasyLoading.dismiss();
      if (mounted) await _continue();
    } catch (error) {
      await EasyLoading.dismiss();
      if (mounted) {
        await EasyLoading.showError(
          _messageFor(error, fallback: 'Unable to save personal information.'),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(
    Object error, {
    String fallback = 'Unable to load personal information.',
  }) => error is ApiException ? error.message : fallback;

  void _disposeFields(Iterable<_PersonalInformationFieldState> fields) {
    for (final field in fields) {
      field.controller.dispose();
    }
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

enum _PersonalInformationLoadState { loading, content, empty, error }

class _PersonalInformationFieldState {
  _PersonalInformationFieldState(this.data)
    : controller = TextEditingController(text: data.initialDisplayValue),
      submitValue = data.initialSubmitValue;

  final PersonalInformationField data;
  final TextEditingController controller;
  String submitValue;

  String get currentSubmitValue =>
      (data.control == PersonalInformationControl.text
              ? controller.text
              : submitValue)
          .trim();
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
    required this.fields,
    required this.addressLoadingKey,
    required this.onSelect,
  });
  final List<_PersonalInformationFieldState> fields;
  final String? addressLoadingKey;
  final ValueChanged<_PersonalInformationFieldState> onSelect;

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
              _PersonalInformationFieldView(
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

class _PersonalInformationFieldView extends StatelessWidget {
  const _PersonalInformationFieldView({
    required this.field,
    required this.isLast,
    required this.isAddressLoading,
    required this.onTap,
  });
  final _PersonalInformationFieldState field;
  final bool isLast;
  final bool isAddressLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = field.data;
    final isText = data.control == PersonalInformationControl.text;
    return _FieldShell(
      label: data.title,
      bottomPadding: isLast ? 0 : null,
      child: isText
          ? _InputField(field: field)
          : _SelectField(
              field: field,
              isAddressLoading: isAddressLoading,
              onTap: onTap,
            ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.field});
  final _PersonalInformationFieldState field;

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

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.field,
    required this.isAddressLoading,
    required this.onTap,
  });
  final _PersonalInformationFieldState field;
  final bool isAddressLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('personalInformation-${field.data.saveKey}'),
    onTap: field.data.control == PersonalInformationControl.unsupported
        ? null
        : onTap,
    borderRadius: BorderRadius.circular(context.r(4)),
    child: _FieldValue(
      value: field.controller.text.isEmpty
          ? field.data.placeholder
          : field.controller.text,
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
  const _FieldValue({
    required this.value,
    required this.showChevron,
    this.trailing,
  });
  final String value;
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
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: context.r(14),
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

class _FormStatus extends StatelessWidget {
  const _FormStatus({
    required this.message,
    this.showProgress = false,
    this.onRetry,
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

enum _AddressLevel { region, province, municipality }

class _AddressOptionsSheet extends StatefulWidget {
  const _AddressOptionsSheet({
    required this.nodes,
    required this.initialValue,
    required this.onSelected,
  });

  final List<PersonalAddressNode> nodes;
  final String initialValue;
  final ValueChanged<String> onSelected;

  @override
  State<_AddressOptionsSheet> createState() => _AddressOptionsSheetState();
}

class _AddressOptionsSheetState extends State<_AddressOptionsSheet> {
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
