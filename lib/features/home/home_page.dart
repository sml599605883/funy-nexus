import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/navigation/customer_service_navigation.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/permissions/location_prompt_dialog.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/session/session_store.dart';
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
  const HomePage({this.onPullToRefresh, super.key});

  final Future<void> Function()? onPullToRefresh;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, AsyncState<HomeData>>(
      listener: (context, state) {
        if (state case AsyncFailure<HomeData>(
          :final previousData,
        ) when previousData != null) {
          unawaited(EasyLoading.showError('Unable to refresh home data'));
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
            onRefresh: onPullToRefresh ?? context.read<HomeCubit>().load,
            onApply: (card) => _apply(context, card),
            onApplyRecommendation: (item) =>
                _applyProduct(context, item.productId),
            onCustomerService: () => _openCustomerService(context),
            onPromoBannerTap: (banner) =>
                unawaited(_handleBannerTap(context, banner)),
          );
        }
        if (previousData != null) {
          if (state is AsyncLoading<HomeData>) {
            return Stack(
              children: [
                HomeContent(
                  data: previousData,
                  onRefresh: onPullToRefresh ?? context.read<HomeCubit>().load,
                  onApply: (card) => _apply(context, card),
                  onApplyRecommendation: (item) =>
                      _applyProduct(context, item.productId),
                  onCustomerService: () => _openCustomerService(context),
                  onPromoBannerTap: (banner) =>
                      unawaited(_handleBannerTap(context, banner)),
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
            onRefresh: onPullToRefresh ?? context.read<HomeCubit>().load,
            onApply: (card) => _apply(context, card),
            onApplyRecommendation: (item) =>
                _applyProduct(context, item.productId),
            onCustomerService: () => _openCustomerService(context),
            onPromoBannerTap: (banner) =>
                unawaited(_handleBannerTap(context, banner)),
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

  Future<void> _apply(BuildContext context, HomeCardData card) =>
      _applyProduct(context, card.productId);

  Future<void> _applyProduct(BuildContext context, String productId) {
    return context.read<ProductApplicationFlow>().apply(
      productId: productId,
      openLogin: (_) => _openLogin(context),
      openTarget: (target) => _openWebTarget(context, target),
      openCreditReview: (_) async {
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CreditReviewPage(productId: productId),
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
      // Admission navigation should start in the same frame the request ends;
      // waiting for EasyLoading's exit animation creates a visible blank gap.
      dismissLoading: () => EasyLoading.dismiss(animation: false),
      showMessage: (message) => _showMessage(context, message),
      showLocationSettingsPrompt: (prompt) =>
          showLocationPromptDialog(context, prompt),
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

  Future<void> _handleBannerTap(
    BuildContext context,
    HomeBannerData banner,
  ) async {
    final target = banner.target.trim();
    if (target.isEmpty) return;
    await _reportBannerClick(context, banner.id);
    if (!context.mounted) return;
    await _openWebTarget(context, target);
  }

  /// Reporting is best effort: the documented scene requires a signed-in
  /// session with a non-empty target, and a failed upload must never block
  /// the banner destination.
  Future<void> _reportBannerClick(BuildContext context, String bannerId) async {
    final id = bannerId.trim();
    if (id.isEmpty) return;
    if (!context.read<SessionStore>().isAuthenticated) return;
    try {
      await context.read<ApiClient>().uploadBannerClick(bannerConfigId: id);
    } catch (_) {
      // Intentionally ignored.
    }
  }

  Future<void> _openCustomerService(BuildContext context) async {
    if (!context.read<SessionStore>().isAuthenticated) {
      await _openLogin(context);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductWebPage(
          url: customerServiceUrl(context.read<AppConfig>().webBaseUrl),
        ),
      ),
    );
  }

  Future<bool> _openLogin(BuildContext context) async {
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
  }

  Future<void> _showMessage(BuildContext context, String message) async {
    if (!context.mounted) return;
    await EasyLoading.showError(message);
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
