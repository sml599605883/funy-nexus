import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/risk_report_scene.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/certification/personal_information_field_state.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_guard.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_progress.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_salary_day_panel.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_single_select_panel.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_address_sheet.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_form.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

enum PersonalInformationKind { personal, work }

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({
    required this.productId,
    this.gateway,
    this.kind = PersonalInformationKind.personal,
    super.key,
  });

  const PersonalInformationPage.work({
    required this.productId,
    this.gateway,
    super.key,
  }) : kind = PersonalInformationKind.work;

  final String productId;
  final PersonalInformationGateway? gateway;
  final PersonalInformationKind kind;

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
  Future<List<PersonalAddressNode>>? _addressPreloadFuture;
  bool _submitting = false;

  PersonalInformationGateway get _gateway =>
      widget.gateway ?? context.read<PersonalInformationGateway>();

  bool get _isWorkInformation => widget.kind == PersonalInformationKind.work;

  String get _pageKey =>
      _isWorkInformation ? 'workInformation' : 'personalInformation';

  @override
  void initState() {
    super.initState();
    _addressPreloadFuture = _preloadAddressOptions();
    unawaited(
      _addressPreloadFuture!.catchError((_) => const <PersonalAddressNode>[]),
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    disposePersonalInformationFields(_fields);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guidance = _guidance(context);
    final busy =
        _loadState == _PersonalInformationLoadState.loading ||
        _submitting ||
        _addressLoadingKey != null;
    final onBack = CertificationRetentionGuard.backHandler(
      context: context,
      type: _isWorkInformation ? '3' : '2',
      productId: widget.productId,
      onDefaultBack: () => Navigator.of(context).maybePop(),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) onBack();
      },
      child: Scaffold(
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
                        title: _isWorkInformation
                            ? 'Job information'
                            : 'Basic identity information',
                        onBack: onBack,
                        backButtonKey: Key('${_pageKey}Back'),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.r(16),
                          context.r(24),
                          context.r(172),
                          0,
                        ),
                        child: CertificationGuidance(
                          key: Key('${_pageKey}Guidance'),
                          text: guidance,
                        ),
                      ),
                      SizedBox(height: context.r(41)),
                      Center(
                        child: CertificationProgress(
                          key: Key('${_pageKey}Progress'),
                          currentStep: _isWorkInformation ? 2 : 1,
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
        message: _isWorkInformation
            ? 'No work information available'
            : 'No personal information available',
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
      final data = _isWorkInformation
          ? await _gateway.fetchWorkInformation(widget.productId)
          : await _gateway.fetchPersonalInformation(widget.productId);
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
    if (_isWorkInformation &&
        field.data.options.any((option) => option.children.isNotEmpty)) {
      await _selectSalaryDay(field);
      return;
    }
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

  Future<void> _selectSalaryDay(PersonalInformationFieldState field) async {
    final selected = await showCertificationSalaryDayPanel(
      context,
      options: field.data.options,
    );
    if (selected != null && mounted) {
      setState(() {
        field.submitValue = selected.submitValue;
        field.controller.text = selected.displayValue;
      });
    }
  }

  Future<void> _selectAddress(PersonalInformationFieldState field) async {
    if (_addressLoadingKey != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _addressLoadingKey = field.data.saveKey);
    late final List<PersonalAddressNode> nodes;
    try {
      nodes = await _addressOptionsForSelection();
    } catch (error) {
      if (mounted) {
        await EasyLoading.showError(
          _messageFor(error, fallback: 'Unable to load address options.'),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _addressLoadingKey = null);
    }
    if (!mounted) return;
    final selected = await showPersonalInformationAddressOptionsSheet(
      context: context,
      nodes: nodes,
      initialValue: field.submitValue,
    );
    if (selected != null && mounted) {
      setState(() {
        field.submitValue = selected;
        field.controller.text = selected;
      });
    }
  }

  Future<List<PersonalAddressNode>> _addressOptionsForSelection() async {
    final cachedNodes = _addressNodes;
    if (cachedNodes != null) return cachedNodes;

    final preload = _addressPreloadFuture;
    if (preload != null) {
      try {
        return await preload;
      } catch (_) {
        _addressPreloadFuture = null;
      }
    }

    return _addressPreloadFuture ??= _preloadAddressOptions();
  }

  Future<List<PersonalAddressNode>> _preloadAddressOptions() async {
    final nodes = await _gateway.fetchPersonalInformationAddresses();
    if (nodes.isEmpty) {
      throw const ApiException(
        type: ApiFailureType.invalidResponse,
        message: 'No address options available.',
      );
    }
    if (mounted) _addressNodes = nodes;
    return nodes;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final reportService = context.read<ReportService?>();
    final fields = <String, String>{
      for (final field in _fields) field.data.saveKey: field.currentSubmitValue,
    };
    setState(() => _submitting = true);
    try {
      await EasyLoading.show(status: 'Loading...');
      if (_isWorkInformation) {
        await _gateway.saveWorkInformation(
          productId: widget.productId,
          fields: fields,
        );
      } else {
        await _gateway.savePersonalInformation(
          productId: widget.productId,
          fields: fields,
        );
      }
      RiskReportScene.report(
        reportService,
        productId: widget.productId,
        sceneType: _isWorkInformation ? '6' : '5',
      );
      await EasyLoading.dismiss();
      if (mounted) await _continue();
    } catch (error) {
      await EasyLoading.dismiss();
      if (mounted) {
        await EasyLoading.showError(
          _messageFor(
            error,
            fallback: _isWorkInformation
                ? 'Unable to save work information.'
                : 'Unable to save personal information.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(Object error, {String? fallback}) => error is ApiException
      ? error.message
      : fallback ??
            (_isWorkInformation
                ? 'Unable to load work information.'
                : 'Unable to load personal information.');

  String _guidance(BuildContext context) {
    const defaultGuidance =
        'Add your work details to\nhelp us assess your\navailable credit limit.';
    if (_isWorkInformation) {
      return _prompt.isEmpty ? defaultGuidance : _prompt;
    }
    final cachedGuidance = context
        .read<SessionStore>()
        .productDetailIdentityGuidance;
    if (cachedGuidance.isNotEmpty) return cachedGuidance;
    return _prompt.isEmpty ? defaultGuidance : _prompt;
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
