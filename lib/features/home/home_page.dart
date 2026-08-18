import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/navigation/customer_service_navigation.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/state/async_state.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/state/home_cubit.dart';
import 'package:fund_nexus/features/home/widgets/home_content.dart';
import 'package:fund_nexus/features/login/login_page.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/credit_review/credit_review_page.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, AsyncState<HomeData>>(
      listener: (context, state) {
        if (state case AsyncFailure<HomeData>(
          :final previousData,
        ) when previousData != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Unable to refresh home data')),
            );
        }
      },
      builder: (context, state) {
        final previousData = switch (state) {
          AsyncLoading<HomeData>(:final previousData) => previousData,
          AsyncFailure<HomeData>(:final previousData) => previousData,
          _ => null,
        };
        if (state case AsyncData<HomeData>(:final data)) {
          return HomeContent(
            data: data,
            onRefresh: context.read<HomeCubit>().load,
            onApply: (card) => _apply(context, card),
            onCustomerService: () => _openCustomerService(context),
          );
        }
        if (previousData != null) {
          if (state is AsyncLoading<HomeData>) {
            return Stack(
              children: [
                HomeContent(
                  data: previousData,
                  onRefresh: context.read<HomeCubit>().load,
                  onApply: (card) => _apply(context, card),
                  onCustomerService: () => _openCustomerService(context),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: context.r(88),
                  child: const LinearProgressIndicator(),
                ),
              ],
            );
          }
          return HomeContent(
            data: previousData,
            onRefresh: context.read<HomeCubit>().load,
            onApply: (card) => _apply(context, card),
            onCustomerService: () => _openCustomerService(context),
          );
        }
        if (state is AsyncFailure<HomeData>) {
          return _HomeStatusView(
            message: 'Unable to load home data',
            onRetry: context.read<HomeCubit>().load,
          );
        }
        if (state is AsyncEmpty<HomeData>) {
          return _HomeStatusView(
            message: 'No loan offers are available',
            onRetry: context.read<HomeCubit>().load,
          );
        }
        return const _HomeStatusView();
      },
    );
  }

  Future<void> _apply(BuildContext context, HomeCardData card) {
    return context.read<ProductApplicationFlow>().apply(
      productId: card.productId,
      openLogin: (productId) async {
        if (!context.mounted) return false;
        final riskStartedAtSeconds = ReportService.nowSeconds();
        return await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => LoginPage(
                  onLoginSuccess: () async {
                    await context.read<ReportService>().loginSucceeded(
                      riskStartedAtSeconds: riskStartedAtSeconds,
                    );
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                ),
              ),
            ) ??
            false;
      },
      openTarget: (target) => _openWebTarget(context, target),
      openCreditReview: (_) async {
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CreditReviewPage(productId: card.productId),
          ),
        );
      },
      openCertification: (step, productId) async {
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                CertificationHandoffPage(productId: productId, step: step),
          ),
        );
      },
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: EasyLoading.dismiss,
      showMessage: (message) => _showMessage(context, message),
      showLocationSettingsPrompt: (message) =>
          _showLocationSettingsPrompt(context, message),
    );
  }

  Future<void> _openWebTarget(BuildContext context, String target) async {
    if (ProductWebPage.validUri(target) == null) {
      await _showMessage(context, 'Unable to open the requested page.');
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: target)),
    );
  }

  Future<void> _openCustomerService(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductWebPage(
          url: customerServiceUrl(context.read<AppConfig>().webBaseUrl),
        ),
      ),
    );
  }

  Future<void> _showMessage(BuildContext context, String message) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showLocationSettingsPrompt(
    BuildContext context,
    String message,
  ) async {
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Allow Location Access'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _HomeStatusView extends StatelessWidget {
  const _HomeStatusView({this.message, this.onRetry});

  final String? message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: Center(
        child: message == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.homeCaption),
                  ),
                  SizedBox(height: context.r(16)),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
