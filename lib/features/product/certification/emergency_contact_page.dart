import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/risk_report_scene.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_page_chrome.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_guard.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_progress.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_single_select_panel.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_form.dart';
import 'package:fund_nexus/features/product/data/emergency_contact_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class EmergencyPickedContact {
  const EmergencyPickedContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

typedef EmergencyContactPick = Future<EmergencyPickedContact?> Function();

class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({
    required this.productId,
    this.gateway,
    this.pickContact,
    this.continueFlow,
    super.key,
  });

  final String productId;
  final EmergencyContactGateway? gateway;
  final EmergencyContactPick? pickContact;
  final Future<void> Function(String productId)? continueFlow;

  @override
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  static const _defaultPrompt =
      'Please provide your emergency contact information for identity verification.';

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  _EmergencyContactLoadState _loadState = _EmergencyContactLoadState.loading;
  List<_EmergencyContactEntry> _contacts = const [];
  String _prompt = '';
  String _loadError = '';
  bool _submitting = false;
  bool _isLeaving = false;

  EmergencyContactGateway get _gateway =>
      widget.gateway ?? context.read<EmergencyContactGateway>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  void _completeDefaultBack() {
    if (!mounted || _isLeaving) return;
    setState(() => _isLeaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _loadState == _EmergencyContactLoadState.loading || _submitting;
    final onBack = CertificationRetentionGuard.backHandler(
      context: context,
      type: '4',
      productId: widget.productId,
      onDefaultBack: _completeDefaultBack,
    );
    return PopScope(
      canPop: _isLeaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy && !_isLeaving) onBack();
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
                key: const Key('emergencyContactDismissKeyboard'),
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: context.r(92)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CertificationPageHeader(
                        title: 'Urgent contact person',
                        onBack: _isLeaving ? null : onBack,
                        backButtonKey: const Key('emergencyContactBack'),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.r(16),
                          context.r(23),
                          context.r(172),
                          0,
                        ),
                        child: CertificationGuidance(
                          key: const Key('emergencyContactGuidance'),
                          text: _prompt.isEmpty ? _defaultPrompt : _prompt,
                        ),
                      ),
                      SizedBox(height: context.r(22)),
                      Center(
                        child: CertificationProgress(
                          key: const Key('emergencyContactProgress'),
                          currentStep: 4,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -context.r(27)),
                        child: _buildContent(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (busy)
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
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
                  _loadState == _EmergencyContactLoadState.content && !busy,
              onPressed: _submit,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_loadState) {
      case _EmergencyContactLoadState.loading:
        return PersonalInformationFormStatus(
          message: 'Loading...',
          showProgress: true,
        );
      case _EmergencyContactLoadState.empty:
        return PersonalInformationFormStatus(
          message: 'No emergency contacts available',
          onRetry: _load,
        );
      case _EmergencyContactLoadState.error:
        return PersonalInformationFormStatus(
          message: _loadError,
          onRetry: _load,
        );
      case _EmergencyContactLoadState.content:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.r(16)),
          child: Container(
            key: const Key('emergencyContactFormCard'),
            padding: EdgeInsets.fromLTRB(
              context.r(12),
              context.r(12),
              context.r(12),
              context.r(18),
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _contacts.length; index++)
                  _ContactGroup(
                    key: Key(
                      'emergencyContactGroup-${_contacts[index].data.number}',
                    ),
                    index: index,
                    entry: _contacts[index],
                    onRelationshipTap: () =>
                        _selectRelationship(_contacts[index]),
                    onContactTap: () => _selectContact(_contacts[index]),
                  ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loadState = _EmergencyContactLoadState.loading;
        _loadError = '';
      });
    }
    try {
      final data = await _gateway.fetchEmergencyContacts(widget.productId);
      final contacts = data.contacts
          .map(_EmergencyContactEntry.new)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _prompt = data.prompt;
        _loadState = contacts.isEmpty
            ? _EmergencyContactLoadState.empty
            : _EmergencyContactLoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _contacts = const [];
        _loadError = _messageFor(error);
        _loadState = _EmergencyContactLoadState.error;
      });
    }
  }

  Future<void> _selectRelationship(_EmergencyContactEntry entry) async {
    final selected =
        await showCertificationSingleSelectPanel<EmergencyContactOption>(
          context,
          options: entry.data.relationshipOptions,
          labelBuilder: (option) => option.label,
        );
    if (selected == null || !mounted) return;
    setState(() {
      entry.relationshipValue = selected.value;
      entry.relationshipLabel = selected.label;
    });
  }

  Future<void> _selectContact(_EmergencyContactEntry entry) async {
    try {
      final selected = widget.pickContact == null
          ? await _pickNativeContact()
          : await widget.pickContact!();
      if (selected == null || !mounted) return;
      setState(() {
        entry.name = selected.name.trim();
        entry.phone = selected.phone.trim();
      });
    } catch (error) {
      if (mounted) {
        await EasyLoading.showError(_messageFor(error));
      }
    }
  }

  Future<EmergencyPickedContact?> _pickNativeContact() async {
    final contact = await _contactPicker.selectContact();
    if (contact == null) return null;
    return EmergencyPickedContact(
      name: (contact.fullName ?? '').trim(),
      phone: _primaryPhone(contact),
    );
  }

  String _primaryPhone(Contact contact) {
    final selected = (contact.selectedPhoneNumber ?? '').trim();
    if (selected.isNotEmpty) return selected;
    for (final phone in contact.phoneNumbers ?? const <String>[]) {
      if (phone.trim().isNotEmpty) return phone.trim();
    }
    return '';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final reportService = context.read<ReportService?>();
    setState(() => _submitting = true);
    try {
      await EasyLoading.show(status: 'Loading...');
      await _gateway.saveEmergencyContacts(
        productId: widget.productId,
        contacts: _contacts.map((entry) => entry.toJson()).toList(),
      );
      RiskReportScene.report(
        reportService,
        productId: widget.productId,
        sceneType: '7',
      );
      await EasyLoading.dismiss();
      if (mounted) await _continue();
    } catch (error) {
      await EasyLoading.dismiss();
      if (mounted) await EasyLoading.showError(_messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(Object error) => error is ApiException
      ? error.message
      : 'Unable to load emergency contact information.';

  Future<void> _continue() async {
    if (widget.continueFlow != null) {
      await widget.continueFlow!(widget.productId);
      return;
    }
    if (!mounted) return;
    final flow = context.read<ProductApplicationFlow>();
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => _EmergencyContactContinuation(
          flow: flow,
          productId: widget.productId,
        ),
      ),
    );
  }
}

enum _EmergencyContactLoadState { loading, content, empty, error }

class _EmergencyContactEntry {
  _EmergencyContactEntry(this.data)
    : relationshipValue = data.relationshipValue,
      relationshipLabel = data.relationshipLabel,
      name = data.name,
      phone = data.phone;

  final EmergencyContact data;
  String relationshipValue;
  String relationshipLabel;
  String name;
  String phone;

  Map<String, String> toJson() => {
    'backgrounder': phone.trim(),
    'emit': name.trim(),
    'bettors': relationshipValue.trim(),
    'obstruent': data.number.trim(),
  };
}

class _ContactGroup extends StatelessWidget {
  const _ContactGroup({
    required this.index,
    required this.entry,
    required this.onRelationshipTap,
    required this.onContactTap,
    super.key,
  });

  final int index;
  final _EmergencyContactEntry entry;
  final VoidCallback onRelationshipTap;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = AppColors.personalInformationPlaceholder;
    final valueStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: context.r(14),
      height: 20 / 14,
    );
    final placeholderStyle = valueStyle.copyWith(color: placeholder);
    return Padding(
      padding: EdgeInsets.only(bottom: context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: context.r(19),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Relationship with Emergency Contacts - ${index + 1}',
                  key: Key('emergencyContactGroupTitle-${entry.data.number}'),
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.certificationSectionTitle,
                    fontSize: context.r(16),
                    fontWeight: FontWeight.w700,
                    height: 19 / 16,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.r(index == 0 ? 16 : 24)),
          _FieldLabel(text: 'Relationship'),
          SizedBox(height: context.r(8)),
          _ContactField(
            key: Key('emergencyContactRelationship-${entry.data.number}'),
            onTap: onRelationshipTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.relationshipLabel.isEmpty
                        ? 'Please select relationship'
                        : entry.relationshipLabel,
                    style: entry.relationshipLabel.isEmpty
                        ? placeholderStyle
                        : valueStyle,
                  ),
                ),
                Image.asset(
                  AppAssets.mineChevron,
                  width: context.r(7),
                  height: context.r(11),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onContactTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.r(12)),
                  _FieldLabel(text: 'Contact Information'),
                  SizedBox(height: context.r(8)),
                  _ContactField(
                    key: Key('emergencyContactPicker-${entry.data.number}'),
                    onTap: onContactTap,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name.isEmpty
                                ? 'Please enter contact name'
                                : entry.name,
                            style: entry.name.isEmpty
                                ? placeholderStyle
                                : valueStyle,
                          ),
                        ),
                        Image.asset(
                          AppAssets.emergencyContactPicker,
                          width: context.r(17),
                          height: context.r(17),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.r(12)),
                  _FieldLabel(text: 'telephone number'),
                  SizedBox(height: context.r(8)),
                  _ContactField(
                    key: Key('emergencyContactPhone-${entry.data.number}'),
                    onTap: onContactTap,
                    child: Text(
                      entry.phone.isEmpty
                          ? 'Please enter telephone number'
                          : entry.phone,
                      style: entry.phone.isEmpty
                          ? placeholderStyle
                          : valueStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontSize: context.r(16),
      fontWeight: FontWeight.w600,
      height: 22 / 16,
    ),
  );
}

class _ContactField extends StatelessWidget {
  const _ContactField({required this.onTap, required this.child, super.key});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.mineItemBackground,
    borderRadius: BorderRadius.circular(context.r(4)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(4)),
      child: SizedBox(
        height: context.r(48),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.r(12)),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    ),
  );
}

class _EmergencyContactContinuation extends StatefulWidget {
  const _EmergencyContactContinuation({
    required this.flow,
    required this.productId,
  });

  final ProductApplicationFlow flow;
  final String productId;

  @override
  State<_EmergencyContactContinuation> createState() =>
      _EmergencyContactContinuationState();
}

class _EmergencyContactContinuationState
    extends State<_EmergencyContactContinuation> {
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
