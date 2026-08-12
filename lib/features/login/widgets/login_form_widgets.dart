import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/login/state/login_cubit.dart';

class LoginFieldLabel extends StatelessWidget {
  const LoginFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 22 / 16,
    ),
  );
}

class LoginPhoneField extends StatelessWidget {
  const LoginPhoneField({required this.controller, super.key});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.loginFieldBackground,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const Text(
          '+63',
          style: TextStyle(color: AppColors.loginInputText, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 12, color: AppColors.loginInputDivider),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            key: const Key('loginPhoneField'),
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration.collapsed(
              hintText: 'Mobile numbers starting with 9',
              hintStyle: TextStyle(
                color: AppColors.loginPlaceholder,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class LoginCodeField extends StatelessWidget {
  const LoginCodeField({
    required this.phoneController,
    required this.controller,
    required this.focusNode,
    super.key,
  });
  final TextEditingController phoneController;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) => BlocBuilder<LoginCubit, LoginState>(
    builder: (context, state) {
      final countingDown = state.countdownSeconds > 0;
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.loginFieldBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('loginCodeField'),
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration.collapsed(
                  hintText: 'SMS code',
                  hintStyle: TextStyle(
                    color: AppColors.loginPlaceholder,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            GestureDetector(
              key: const Key('loginGetCodeButton'),
              onTap: state.requestingCode || countingDown
                  ? null
                  : () async {
                      final result = await context
                          .read<LoginCubit>()
                          .requestSmsCode(phoneController.text);
                      if (result && context.mounted) focusNode.requestFocus();
                    },
              child: SizedBox(
                width: 60,
                child: state.requestingCode
                    ? const Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        countingDown ? '${state.countdownSeconds}s' : 'Get it',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: countingDown
                              ? AppColors.loginPlaceholder
                              : AppColors.loginAgreementLink,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    required this.phoneController,
    required this.codeController,
    required this.enabled,
    super.key,
  });
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final bool enabled;

  @override
  Widget build(BuildContext context) => BlocBuilder<LoginCubit, LoginState>(
    builder: (context, state) {
      final canTap = enabled && state.agreementAccepted && !state.loggingIn;
      return GestureDetector(
        key: const Key('loginSubmitButton'),
        onTap: canTap
            ? () => context.read<LoginCubit>().submitSmsCode(
                phone: phoneController.text,
                code: codeController.text,
              )
            : null,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.loginButtonStart, AppColors.loginButtonEnd],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.loginButtonShadow,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: state.loggingIn
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.surface,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Apply Now',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    },
  );
}

class LoginAgreementRow extends StatefulWidget {
  const LoginAgreementRow({
    required this.accepted,
    required this.onToggle,
    this.onPrivacyPolicyTap,
    this.onTermsOfServiceTap,
    super.key,
  });
  final bool accepted;
  final VoidCallback onToggle;
  final VoidCallback? onPrivacyPolicyTap;
  final VoidCallback? onTermsOfServiceTap;

  @override
  State<LoginAgreementRow> createState() => _LoginAgreementRowState();
}

class _LoginAgreementRowState extends State<LoginAgreementRow> {
  late final TapGestureRecognizer _policy = TapGestureRecognizer()
    ..onTap = widget.onPrivacyPolicyTap;
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = widget.onTermsOfServiceTap;

  @override
  void didUpdateWidget(covariant LoginAgreementRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _policy.onTap = widget.onPrivacyPolicyTap;
    _terms.onTap = widget.onTermsOfServiceTap;
  }

  @override
  void dispose() {
    _policy.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: const Key('loginAgreementToggle'),
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Image.asset(
              widget.accepted
                  ? AppAssets.loginAgreementChecked
                  : AppAssets.loginAgreementUnchecked,
              key: Key(
                widget.accepted
                    ? 'loginAgreementChecked'
                    : 'loginAgreementUnchecked',
              ),
              width: 16,
              height: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 17 / 12,
              ),
              children: [
                const TextSpan(text: 'I have read and agree to the '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: AppColors.loginAgreementLink,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _policy,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
