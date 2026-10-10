import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/navigation/app_route_observer.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/state/credit_review_polling_coordinator.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class CreditReviewPage extends StatefulWidget {
  const CreditReviewPage({required this.productId, super.key});

  final String productId;

  @override
  State<CreditReviewPage> createState() => _CreditReviewPageState();
}

class _CreditReviewPageState extends State<CreditReviewPage> with RouteAware {
  static final Random _random = Random();

  Timer? _progressTimer;
  var _progress = 0;
  var _started = false;
  PageRoute<dynamic>? _route;
  CreditReviewPollingCoordinator? _coordinator;

  @override
  void initState() {
    super.initState();
    _scheduleProgressUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && !identical(route, _route)) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
    if (_started) return;
    _started = true;
    final coordinator = context.read<CreditReviewPollingCoordinator>();
    _coordinator = coordinator;
    coordinator
      ..attachForegroundHandler(_resumeAdmission)
      ..start(widget.productId);
  }

  @override
  void didPushNext() {
    _coordinator?.detachForegroundHandler(_resumeAdmission);
  }

  @override
  void didPopNext() {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    coordinator.attachForegroundHandler(_resumeAdmission);
    if (!coordinator.isRunning) {
      coordinator.start(widget.productId);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    appRouteObserver.unsubscribe(this);
    _coordinator?.detachForegroundHandler(_resumeAdmission);
    super.dispose();
  }

  Future<void> _resumeAdmission(String productId) {
    return context.read<ProductApplicationFlow>().resumeAfterCreditReview(
      productId: productId,
      openTarget: _openTarget,
      openCreditReview: _continueAfterApproval,
      openCertification: _openCertification,
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: () => EasyLoading.dismiss(animation: false),
      showMessage: _showMessage,
    );
  }

  // The review is already approved when this runs, so an admission response
  // that still points at the review page means the backend has not caught up.
  // Continue with the product detail instead of polling again, which would be
  // approved instantly and spin without ever leaving this page.
  Future<void> _continueAfterApproval(String _) async {
    if (!mounted) return;
    await context.read<ProductApplicationFlow>().resumeAfterCertification(
      productId: widget.productId,
      openTarget: _openTarget,
      openCertification: _openCertification,
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: () => EasyLoading.dismiss(animation: false),
      showMessage: _showMessage,
    );
  }

  void _scheduleProgressUpdate() {
    if (_progress >= 99) return;
    _progressTimer = Timer(
      Duration(seconds: _random.nextInt(3) + 1),
      _advanceProgress,
    );
  }

  void _advanceProgress() {
    if (!mounted) return;
    setState(() {
      _progress = min(99, _progress + _random.nextInt(11) + 5);
    });
    _scheduleProgressUpdate();
  }

  Future<void> _openTarget(String target) async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: target)),
    );
  }

  Future<void> _openCertification(String step, String productId) async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            CertificationHandoffPage(productId: productId, step: step),
      ),
    );
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    await EasyLoading.showError(message);
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.r(1);
    final contentWidth = context.r(279);
    final progressWidth = context.r(287);
    final progressInnerWidth = max(0, progressWidth - context.r(4)).toDouble();

    return Scaffold(
      backgroundColor: AppColors.recreditBackground,
      body: Stack(
        children: [
          ListView(
            key: const Key('credit-review-scroll'),
            padding: EdgeInsets.only(top: context.r(290)),
            children: [
              Column(
                children: [
                  Image.asset(
                    AppAssets.recreditIllustration,
                    key: const Key('credit-review-illustration'),
                    width: context.r(120),
                    height: context.r(102),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: context.r(18)),
                  SizedBox(
                    width: contentWidth,
                    height: context.r(36),
                    child: _CreditReviewMessage(scale: scale),
                  ),
                  SizedBox(height: context.r(11)),
                  _CreditReviewProgress(
                    progress: _progress,
                    width: progressWidth,
                    innerWidth: progressInnerWidth,
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: context.r(16),
                  top: context.r(12),
                ),
                child: IconButton(
                  key: const Key('credit-review-back'),
                  onPressed: _goBack,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: context.r(24),
                    height: context.r(24),
                  ),
                  icon: Image.asset(
                    AppAssets.identityBackButton,
                    width: context.r(24),
                    height: context.r(24),
                  ),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditReviewMessage extends StatelessWidget {
  const _CreditReviewMessage({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.recreditText,
      fontFamily: 'Helvetica',
      fontSize: 14 * scale,
      fontWeight: FontWeight.w400,
      height: 18 / 14,
    );
    return Column(
      children: [
        RichText(
          maxLines: 1,
          textAlign: TextAlign.center,
          text: TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'Calculating your credit limit, just '),
              TextSpan(
                text: '30 seconds',
                style: style.copyWith(color: AppColors.recreditProgress),
              ),
            ],
          ),
        ),
        Text('Please wait patiently', maxLines: 1, style: style),
      ],
    );
  }
}

class _CreditReviewProgress extends StatelessWidget {
  const _CreditReviewProgress({
    required this.progress,
    required this.width,
    required this.innerWidth,
  });

  final int progress;
  final double width;
  final double innerWidth;

  @override
  Widget build(BuildContext context) {
    final scale = context.r(1);
    return SizedBox(
      key: const Key('credit-review-progress-section'),
      width: width,
      height: 42 * scale,
      child: Column(
        children: [
          SizedBox(
            key: const Key('credit-review-progress-bar'),
            width: width,
            height: 12 * scale,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.recreditProgressTrack,
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2 * scale),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4 * scale),
                    child: SizedBox(
                      width: innerWidth * progress / 100,
                      height: 8 * scale,
                      child: const ColoredBox(
                        color: AppColors.recreditProgress,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            '$progress%',
            key: const Key('credit-review-progress-label'),
            style: TextStyle(
              color: AppColors.recreditProgress,
              fontFamily: 'PingFangSC-Medium',
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
