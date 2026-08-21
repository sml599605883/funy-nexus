import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/face/face_liveness_bridge.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/risk_report_scene.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:fund_nexus/features/product/certification/bind_card_field_state.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_continuation.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_progress.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_single_select_panel.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_form.dart';
import 'package:fund_nexus/features/product/data/bind_card_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';
import 'package:permission_handler/permission_handler.dart';

typedef BindCardLivenessLauncher = Future<FaceLivenessResult> Function(String);

class BindCardPage extends StatefulWidget {
  const BindCardPage({
    required this.productId,
    required this.orderNumber,
    this.isAccountChange = false,
    this.gateway,
    this.faceGateway,
    this.permissions,
    this.launchLiveness,
    super.key,
  });

  final String productId;
  final String orderNumber;
  final bool isAccountChange;
  final BindCardGateway? gateway;
  final FaceVerificationGateway? faceGateway;
  final PermissionCoordinator? permissions;
  final BindCardLivenessLauncher? launchLiveness;

  @override
  State<BindCardPage> createState() => _BindCardPageState();
}

class _BindCardPageState extends State<BindCardPage> {
  _BindCardLoadState _loadState = _BindCardLoadState.loading;
  Map<String, List<BindCardFieldState>> _groupFields = const {};
  BindCardData? _data;
  String _selectedType = '';
  String _prompt = '';
  String _loadError = '';
  final _dismissedSuggestionKeys = <String>{};
  String? _activeSuggestionKey;
  bool _submitting = false;

  BindCardGateway get _gateway =>
      widget.gateway ?? context.read<BindCardGateway>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    disposeBindCardFields(_groupFields.values.expand((fields) => fields));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPrompt = _data?.bottomPrompt ?? '';
    final footerHeight =
        context.r(bottomPrompt.isEmpty ? 80 : 116) +
        MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
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
              key: const Key('bindCardDismissKeyboard'),
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom:
                      footerHeight +
                      MediaQuery.viewInsetsOf(context).bottom +
                      context.r(16),
                ),
                child: Column(
                  children: [
                    CertificationPageHeader(
                      title: 'Account management',
                      onBack: _submitting
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      backButtonKey: const Key('bindCardBack'),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: context.r(16),
                        top: context.r(23),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: context.r(187),
                          height: context.r(76),
                          child: Text(
                            _prompt,
                            maxLines: 4,
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
                    ),
                    SizedBox(height: context.r(19)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.r(16)),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: CertificationProgress(currentStep: 4),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: context.r(40)),
                            child: _buildBody(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.surface,
        padding: EdgeInsets.fromLTRB(
          context.r(16),
          context.r(14),
          context.r(16),
          context.r(14),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bottomPrompt.isNotEmpty) ...[
                Text(
                  bottomPrompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.addressPickerOption,
                    fontSize: context.r(12),
                  ),
                ),
                SizedBox(height: context.r(8)),
              ],
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: context.r(16)),
                height: context.r(50),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.r(25)),
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
                        AppColors.identityFaceButtonStart,
                        AppColors.identityFaceButtonEnd,
                      ],
                    ),
                  ),
                  child: TextButton(
                    key: const Key('bindCardUpload'),
                    onPressed:
                        _loadState != _BindCardLoadState.content || _submitting
                        ? null
                        : _submit,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.surface,
                      disabledForegroundColor: AppColors.surface,
                    ),
                    child: Text(
                      _submitting ? 'Loading...' : 'Upload',
                      style: TextStyle(fontSize: context.r(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_loadState) {
      case _BindCardLoadState.loading:
        return _BindCardFormStatus(child: const CircularProgressIndicator());
      case _BindCardLoadState.error:
        return _BindCardFormStatus(
          child: TextButton(
            key: const Key('bindCardRetry'),
            onPressed: _load,
            child: Text(_loadError),
          ),
        );
      case _BindCardLoadState.empty:
        return const _BindCardFormStatus(
          child: Text('No payment methods available'),
        );
      case _BindCardLoadState.content:
        break;
    }
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final group = _selectedGroup(data);
    final fields = _groupFields[group.type] ?? const <BindCardFieldState>[];
    return Container(
      key: const Key('bindCardForm'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.r(331)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTabs(data.groups, group.type),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.r(12),
              context.r(13),
              context.r(12),
              context.r(12),
            ),
            child: Column(
              children: [
                for (var index = 0; index < fields.length; index++)
                  _buildField(
                    group.type,
                    fields[index],
                    isLast: index == fields.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(List<BindCardGroup> groups, String selectedType) =>
      SizedBox(
        height: context.r(48),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  for (final group in groups)
                    Expanded(
                      child: TextButton(
                        key: Key('bindCardTab-${group.type}'),
                        onPressed: _submitting
                            ? null
                            : () => _selectGroup(group.type),
                        child: Text(
                          group.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: group.type == selectedType
                                ? AppColors.loginBackground
                                : AppColors.addressPickerOption,
                            fontSize: context.r(
                              group.type == selectedType ? 16 : 14,
                            ),
                            fontWeight: group.type == selectedType
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                for (final group in groups)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: context.r(51),
                        height: context.r(4),
                        color: group.type == selectedType
                            ? AppColors.loginBackground
                            : Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _buildField(
    String groupType,
    BindCardFieldState state, {
    required bool isLast,
  }) {
    final field = state.data;
    final isPlaceholder = state.controller.text.isEmpty;
    return PersonalInformationFieldShell(
      label: field.title,
      bottomPadding: isLast ? 0 : null,
      child: field.control == BindCardControl.selection
          ? InkWell(
              key: Key('bindCardPicker-${field.saveKey}'),
              onTap: () => _select(state),
              borderRadius: BorderRadius.circular(context.r(4)),
              child: PersonalInformationFieldValue(
                value: isPlaceholder
                    ? field.placeholder
                    : state.controller.text,
                isPlaceholder: isPlaceholder,
                showChevron: true,
              ),
            )
          : Stack(
              alignment: Alignment.centerRight,
              children: [
                KeyedSubtree(
                  key: state.inputVisibilityKey,
                  child: PersonalInformationInputField.value(
                    inputKey: Key('bindCardInput-${field.saveKey}'),
                    controller: state.controller,
                    focusNode: state.focusNode,
                    numericKeyboard: field.numericKeyboard,
                    placeholder: field.placeholder,
                  ),
                ),
                if (_activeSuggestionKey == _fieldKey(groupType, field))
                  Positioned(
                    right: context.r(12),
                    top: context.r(14),
                    height: context.r(20),
                    child: _BindCardSuggestion(
                      field: field,
                      onApply: () => _applySuggestions(groupType),
                      onClose: () => _dismissSuggestion(groupType, field),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loadState = _BindCardLoadState.loading;
        _loadError = '';
      });
    }
    try {
      final data = await _gateway.fetchBindCard(widget.productId);
      final groupFields = <String, List<BindCardFieldState>>{
        for (final group in data.groups)
          group.type: group.fields
              .map(BindCardFieldState.new)
              .toList(growable: false),
      };
      for (final fields in groupFields.values) {
        for (final state in fields) {
          if (state.data.control != BindCardControl.text) continue;
          state.controller.addListener(_updateActiveSuggestion);
          state.focusNode.addListener(() {
            _updateActiveSuggestion();
            _ensureFocusedFieldVisible(state);
          });
        }
      }
      if (!mounted) {
        disposeBindCardFields(groupFields.values.expand((fields) => fields));
        return;
      }
      setState(() {
        disposeBindCardFields(_groupFields.values.expand((fields) => fields));
        _data = data;
        _groupFields = groupFields;
        _dismissedSuggestionKeys.clear();
        _activeSuggestionKey = null;
        _prompt = data.topPrompt;
        _selectedType = data.groups.firstOrNull?.type ?? '';
        _loadState = data.groups.isEmpty
            ? _BindCardLoadState.empty
            : _BindCardLoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        disposeBindCardFields(_groupFields.values.expand((fields) => fields));
        _groupFields = const {};
        _data = null;
        _dismissedSuggestionKeys.clear();
        _activeSuggestionKey = null;
        _loadError = _messageFor(error);
        _loadState = _BindCardLoadState.error;
      });
    }
  }

  Future<void> _select(BindCardFieldState state) async {
    final field = state.data;
    if (field.control != BindCardControl.selection) return;
    final selected = await showCertificationSingleSelectPanel<BindCardOption>(
      context,
      options: field.options,
      labelBuilder: (option) => option.label,
      leadingBuilder: (option) => option.logoUrl.isEmpty
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(context.r(4)),
              child: Image.network(
                option.logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
      secondaryLabelBuilder: (option) =>
          option.available ? '' : option.maintenanceMessage,
    );
    if (selected == null || !mounted) return;
    setState(() {
      state.submitValue = selected.value;
      state.controller.text = selected.label;
    });
  }

  void _updateActiveSuggestion() {
    if (!mounted) return;
    final data = _data;
    if (data == null || data.groups.isEmpty) return;
    final group = _selectedGroup(data);
    String? nextKey;
    for (final state in _groupFields[group.type] ?? const []) {
      final field = state.data;
      final key = _fieldKey(group.type, field);
      if (field.control == BindCardControl.text &&
          state.focusNode.hasFocus &&
          state.controller.text.trim().isEmpty &&
          field.suggestedValue.isNotEmpty &&
          !_dismissedSuggestionKeys.contains(key)) {
        nextKey = key;
        break;
      }
    }
    if (_activeSuggestionKey != nextKey) {
      setState(() => _activeSuggestionKey = nextKey);
    }
  }

  void _ensureFocusedFieldVisible(BindCardFieldState state) {
    if (!state.focusNode.hasFocus) return;
    _scrollFocusedFieldIntoView(state);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        _scrollFocusedFieldIntoView(state);
      }),
    );
  }

  void _scrollFocusedFieldIntoView(BindCardFieldState state) {
    if (!mounted || !state.focusNode.hasFocus) return;
    final fieldContext = state.inputVisibilityKey.currentContext;
    if (fieldContext == null) return;
    final scrollable = Scrollable.maybeOf(fieldContext);
    final renderObject = fieldContext.findRenderObject();
    if (scrollable == null || renderObject is! RenderBox) return;
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final mediaQuery = MediaQuery.of(fieldContext);
    final safeBottom =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - context.r(24);
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

  void _dismissSuggestion(String groupType, BindCardField field) {
    setState(() {
      _dismissedSuggestionKeys.add(_fieldKey(groupType, field));
      _activeSuggestionKey = null;
    });
  }

  void _applySuggestions(String groupType) {
    final fields = _groupFields[groupType] ?? const <BindCardFieldState>[];
    for (final state in fields) {
      final suggestion = state.data.suggestedValue.trim();
      if (state.data.control == BindCardControl.text &&
          state.controller.text.trim().isEmpty &&
          suggestion.isNotEmpty) {
        state.controller.text = suggestion;
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) setState(() => _activeSuggestionKey = null);
  }

  void _selectGroup(String type) {
    if (_selectedType == type) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedType = type;
      _activeSuggestionKey = null;
    });
  }

  Future<void> _submit() async {
    final data = _data;
    if (_submitting || data == null) return;
    final group = _selectedGroup(data);
    final fieldStates =
        _groupFields[group.type] ?? const <BindCardFieldState>[];
    final fields = <String, String>{};
    for (final state in fieldStates) {
      final field = state.data;
      final value = state.currentSubmitValue;
      if (field.required && value.isEmpty) {
        await EasyLoading.showError(
          field.placeholder.isEmpty
              ? 'Please complete ${field.title}.'
              : field.placeholder,
        );
        return;
      }
      fields[field.saveKey] = value;
    }
    final first = fields['cardNo'];
    final repeat = fields['confirmCardNo'];
    if (first != null && repeat != null && first != repeat) {
      await EasyLoading.showError('The account numbers do not match.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await EasyLoading.show(status: 'Loading...');
      var result = await _gateway.submitBindCard(
        productId: widget.productId,
        cardType: group.type,
        fields: fields,
        liveness: const BindCardLivenessPayload(),
      );
      if (result.code == '20000') {
        await EasyLoading.dismiss();
        result = await _completeLiveness(group, fields);
      }
      await EasyLoading.dismiss();
      if (!mounted) return;
      if (result.code == '20000') {
        await EasyLoading.showError('Liveness verification was not accepted.');
        return;
      }
      if (widget.isAccountChange) {
        final bindId = result.bindId.trim();
        if (bindId.isEmpty) {
          await EasyLoading.showError('Missing binding information.');
          return;
        }
        final response = await context.read<ApiClient>().changeProgressAccount(
          orderNumber: widget.orderNumber,
          bindId: bindId,
        );
        final url = response.data['topical'].stringValue.trim();
        final uri = ProductWebPage.validUri(url);
        if (uri == null) {
          await EasyLoading.showError('Invalid account change result url');
          return;
        }
        if (mounted) Navigator.of(context).pop(uri.toString());
        return;
      }
      RiskReportScene.report(
        context.read<ReportService?>(),
        productId: widget.productId,
        sceneType: '8',
        orderNo: widget.orderNumber,
      );
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => IdentityUploadContinuationPage(
            flow: context.read<ProductApplicationFlow>(),
            productId: widget.productId,
          ),
        ),
      );
    } catch (error) {
      await EasyLoading.dismiss();
      if (mounted) {
        await EasyLoading.showError(
          _messageFor(error, fallback: 'Unable to bind account.'),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<BindCardSubmitResult> _completeLiveness(
    BindCardGroup group,
    Map<String, String> fields,
  ) async {
    final permissions =
        widget.permissions ?? context.read<PermissionCoordinator>();
    final faceGateway =
        widget.faceGateway ?? context.read<FaceVerificationGateway>();
    final permission = await permissions.requestCamera();
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.limited) {
      throw const _BindCardFailure(
        'Camera access is required for verification.',
      );
    }
    final orderNumber = widget.orderNumber.trim();
    if (orderNumber.isEmpty) {
      throw const _BindCardFailure('Order information is not ready yet.');
    }
    final token = await faceGateway.fetchFaceLivenessToken(
      orderNumber: orderNumber,
      type: '1',
    );
    if (token.resultCode != '200' || token.license.isEmpty) {
      throw _BindCardFailure(
        token.errorMessage.isEmpty
            ? 'Unable to start liveness verification.'
            : token.errorMessage,
      );
    }
    if (token.livenessType != 7) {
      throw const _BindCardFailure(
        'This liveness verification method is unavailable.',
      );
    }
    final liveness =
        await (widget.launchLiveness ?? FaceLivenessBridge.instance.start)(
          token.license,
        );
    if (!liveness.success || liveness.livenessId.trim().isEmpty) {
      throw _BindCardFailure(
        liveness.message.isEmpty
            ? 'Liveness verification was not completed.'
            : liveness.message,
      );
    }
    return _gateway.submitBindCard(
      productId: widget.productId,
      cardType: group.type,
      fields: fields,
      liveness: BindCardLivenessPayload(
        type: '7',
        livenessId: liveness.livenessId.trim(),
        license: token.license,
      ),
    );
  }

  BindCardGroup _selectedGroup(BindCardData data) => data.groups.firstWhere(
    (group) => group.type == _selectedType,
    orElse: () => data.groups.first,
  );

  String _fieldKey(String groupType, BindCardField field) =>
      '$groupType:${field.saveKey}';

  String _messageFor(Object error, {String? fallback}) => error is ApiException
      ? error.message
      : error is _BindCardFailure
      ? error.message
      : fallback ?? 'Unable to load payment methods.';
}

enum _BindCardLoadState { loading, content, empty, error }

class _BindCardFormStatus extends StatelessWidget {
  const _BindCardFormStatus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: context.r(331)),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(context.r(12)),
    ),
    alignment: Alignment.center,
    padding: EdgeInsets.all(context.r(24)),
    child: child,
  );
}

class _BindCardSuggestion extends StatelessWidget {
  const _BindCardSuggestion({
    required this.field,
    required this.onApply,
    required this.onClose,
  });

  final BindCardField field;
  final VoidCallback onApply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: context.r(160)),
    child: SizedBox(
      height: context.r(20),
      child: Material(
        color: AppColors.bindCardSuggestionBackground,
        borderRadius: BorderRadius.circular(context.r(4)),
        child: InkWell(
          key: Key('bindCardSuggestion-${field.saveKey}'),
          onTap: onApply,
          borderRadius: BorderRadius.circular(context.r(4)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.r(3),
              context.r(3),
              context.r(4),
              context.r(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    field.suggestedValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: context.r(12),
                      height: 14 / 12,
                    ),
                  ),
                ),
                SizedBox(width: context.r(5)),
                GestureDetector(
                  key: Key('bindCardSuggestionClose-${field.saveKey}'),
                  onTap: onClose,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.r(2)),
                    child: Icon(
                      Icons.cancel,
                      size: context.r(10),
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BindCardFailure implements Exception {
  const _BindCardFailure(this.message);

  final String message;
}
