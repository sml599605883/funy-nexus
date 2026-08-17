import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/features/product/certification/certification_handoff_page.dart';
import 'package:fund_nexus/features/product/state/product_application_flow.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class IdentityUploadContinuationPage extends StatefulWidget {
  const IdentityUploadContinuationPage({
    required this.flow,
    required this.productId,
    super.key,
  });

  final ProductApplicationFlow flow;
  final String productId;

  @override
  State<IdentityUploadContinuationPage> createState() =>
      _IdentityUploadContinuationPageState();
}

class _IdentityUploadContinuationPageState
    extends State<IdentityUploadContinuationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
  }

  Future<void> _continue() async {
    await widget.flow.resumeAfterCertification(
      productId: widget.productId,
      openTarget: (target) async {
        if (!mounted) return;
        await _replaceCertificationFlow(
          MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: target)),
        );
      },
      openCertification: (step, productId) async {
        if (!mounted) return;
        await _replaceCertificationFlow(
          MaterialPageRoute<void>(
            builder: (_) =>
                CertificationHandoffPage(productId: productId, step: step),
          ),
        );
      },
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: EasyLoading.dismiss,
      showMessage: (message) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Future<void> _replaceCertificationFlow(Route<void> route) {
    return Navigator.of(
      context,
    ).pushAndRemoveUntil<void>(route, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
