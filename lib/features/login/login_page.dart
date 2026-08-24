import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/navigation/customer_service_navigation.dart';
import 'package:fund_nexus/features/login/state/login_cubit.dart';
import 'package:fund_nexus/features/login/widgets/login_visuals.dart';
import 'package:fund_nexus/features/login/widgets/login_form_widgets.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({
    this.onPrivacyPolicyTap,
    this.onTermsOfServiceTap,
    this.onLoginSuccess,
    super.key,
  });

  final VoidCallback? onPrivacyPolicyTap;
  final VoidCallback? onTermsOfServiceTap;
  final LoginSuccessCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(
        apiClient: context.read<ApiClient>(),
        sessionStore: context.read<SessionStore>(),
        showMessage: (message) async {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        onLoginSuccess:
            onLoginSuccess ??
            () async {
              if (context.mounted) Navigator.of(context).pop(true);
            },
      ),
      child: _LoginView(
        onPrivacyPolicyTap:
            onPrivacyPolicyTap ?? () => _openPrivacyPolicy(context),
        onTermsOfServiceTap:
            onTermsOfServiceTap ??
            () => debugPrint('Terms of Service requested'),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductWebPage(
          url: privacyPolicyUrl(context.read<AppConfig>().webBaseUrl),
        ),
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({this.onPrivacyPolicyTap, this.onTermsOfServiceTap});

  final VoidCallback? onPrivacyPolicyTap;
  final VoidCallback? onTermsOfServiceTap;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_refresh);
    _codeController.addListener(_onCodeChanged);
    _loadRememberedPhone();
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_refresh)
      ..dispose();
    _codeController
      ..removeListener(_onCodeChanged)
      ..dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedPhone() async {
    final phone = context.read<SessionStore>().phone;
    if (phone == null || phone.isEmpty || _phoneController.text.isNotEmpty) {
      return;
    }
    _phoneController.text = phone;
  }

  void _refresh() => setState(() {});

  void _onCodeChanged() {
    setState(() {});
    if (_codeController.text.length == 6) {
      unawaited(_submitAutomatically());
    }
  }

  Future<void> _submitAutomatically() async {
    final cubit = context.read<LoginCubit>();
    final shouldResetOnFailure = cubit.state.agreementAccepted;
    final success = await cubit.submitSmsCode(
      phone: _phoneController.text,
      code: _codeController.text,
    );
    if (!success && shouldResetOnFailure && mounted) {
      _codeController.clear();
      _codeFocusNode.requestFocus();
    }
  }

  bool get _canSubmit {
    return _phoneController.text.trim().isNotEmpty &&
        _codeController.text.length == 6;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = context.responsive.scale;
                final canvasWidth = 375 * scale;
                return SingleChildScrollView(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: canvasWidth,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: SizedBox(
                            width: 375,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 502,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const LoginTopBar(),
                                      Positioned(
                                        top: 148,
                                        left: 16,
                                        right: 16,
                                        child: _LoginPanel(
                                          phoneController: _phoneController,
                                          codeController: _codeController,
                                          codeFocusNode: _codeFocusNode,
                                          canSubmit: _canSubmit,
                                          onPrivacyPolicyTap:
                                              widget.onPrivacyPolicyTap,
                                          onTermsOfServiceTap:
                                              widget.onTermsOfServiceTap,
                                        ),
                                      ),
                                      const LoginLogo(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 35),
                                const LoginBanner(),
                                const SizedBox(height: 135),
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
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.phoneController,
    required this.codeController,
    required this.codeFocusNode,
    required this.canSubmit,
    required this.onPrivacyPolicyTap,
    required this.onTermsOfServiceTap,
  });

  final TextEditingController phoneController;
  final TextEditingController codeController;
  final FocusNode codeFocusNode;
  final bool canSubmit;
  final VoidCallback? onPrivacyPolicyTap;
  final VoidCallback? onTermsOfServiceTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 354,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 52, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoginFieldLabel('Please enter mobile number'),
              const SizedBox(height: 8),
              LoginPhoneField(controller: phoneController),
              const SizedBox(height: 16),
              const LoginFieldLabel('Verify with SMS Code'),
              const SizedBox(height: 8),
              LoginCodeField(
                phoneController: phoneController,
                controller: codeController,
                focusNode: codeFocusNode,
              ),
              const SizedBox(height: 16),
              LoginSubmitButton(
                phoneController: phoneController,
                codeController: codeController,
                enabled: canSubmit,
              ),
              const SizedBox(height: 16),
              BlocBuilder<LoginCubit, LoginState>(
                builder: (context, state) => LoginAgreementRow(
                  accepted: state.agreementAccepted,
                  onToggle: context.read<LoginCubit>().toggleAgreement,
                  onPrivacyPolicyTap: onPrivacyPolicyTap,
                  onTermsOfServiceTap: onTermsOfServiceTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
