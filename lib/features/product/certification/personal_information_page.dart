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
import 'package:fund_nexus/features/product/certification/personal_information_field_state.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_progress.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_single_select_panel.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_address_sheet.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_form.dart';
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
  List<PersonalInformationFieldState> _fields = const [];
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
    disposePersonalInformationFields(_fields);
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
                    const Center(
                      child: CertificationProgress(
                        key: Key('personalInformationProgress'),
                      ),
                    ),
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
          child: PersonalInformationSubmitButton(
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
      _PersonalInformationLoadState.loading => PersonalInformationFormStatus(
        message: 'Loading...',
        showProgress: true,
      ),
      _PersonalInformationLoadState.empty => PersonalInformationFormStatus(
        message: 'No personal information available',
        onRetry: _load,
      ),
      _PersonalInformationLoadState.error => PersonalInformationFormStatus(
        message: _loadError,
        onRetry: _load,
      ),
      _PersonalInformationLoadState.content => PersonalInformationForm(
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
          .map(PersonalInformationFieldState.new)
          .toList(growable: false);
      if (!mounted) {
        disposePersonalInformationFields(fields);
        return;
      }
      setState(() {
        disposePersonalInformationFields(_fields);
        _fields = fields;
        _prompt = data.prompt;
        _loadState = fields.isEmpty
            ? _PersonalInformationLoadState.empty
            : _PersonalInformationLoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        disposePersonalInformationFields(_fields);
        _fields = const [];
        _loadError = _messageFor(error);
        _loadState = _PersonalInformationLoadState.error;
      });
    }
  }

  Future<void> _selectField(PersonalInformationFieldState field) async {
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

  Future<void> _selectOption(PersonalInformationFieldState field) async {
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

  Future<void> _selectAddress(PersonalInformationFieldState field) async {
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
        builder: (sheetContext) => PersonalInformationAddressOptionsSheet(
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
