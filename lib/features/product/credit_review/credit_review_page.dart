import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class CreditReviewPage extends StatefulWidget {
  const CreditReviewPage({required this.productId, super.key});

  final String productId;

  @override
  State<CreditReviewPage> createState() => _CreditReviewPageState();
}

class _CreditReviewPageState extends State<CreditReviewPage> {
  static const _pollInterval = Duration(seconds: 10);
  Timer? _timer;
  var _checking = true;
  var _finished = false;
  var _pollInFlight = false;

  @override
  void initState() {
    super.initState();
    _checkCredit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkCredit() async {
    if (_finished || _pollInFlight) return;
    _pollInFlight = true;
    try {
      final review = await context.read<ProductGateway>().fetchCreditReview();
      if (!mounted || _finished) return;
      if (review.isApproved) {
        _finished = true;
        await context.read<ProductApplicationFlow>().resumeAfterCreditReview(
          productId: widget.productId,
          openTarget: _openTarget,
          openCreditReview: _resumeReview,
          openCertification: _openCertification,
          showLoading: () => EasyLoading.show(status: 'Loading...'),
          dismissLoading: () => EasyLoading.dismiss(animation: false),
          showMessage: _showMessage,
        );
        return;
      }
    } catch (_) {
      // A transient polling failure retries on the next scheduled attempt.
    } finally {
      _pollInFlight = false;
    }
    if (!mounted || _finished) return;
    setState(() => _checking = false);
    _timer?.cancel();
    _scheduleNextCheck();
  }

  Future<void> _resumeReview(String _) async {
    if (!mounted) return;
    _finished = false;
    setState(() => _checking = false);
    _scheduleNextCheck();
  }

  void _scheduleNextCheck() {
    _timer?.cancel();
    _timer = Timer(_pollInterval, _checkCredit);
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application review')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _checking ? 'Checking your application...' : 'Still reviewing',
            ),
          ],
        ),
      ),
    );
  }
}
