import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/core/navigation/external_url_bridge.dart';
import 'package:fund_nexus/core/review/app_review_bridge.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_contract.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_dispatcher.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_models.dart';

class ProductWebPage extends StatefulWidget {
  const ProductWebPage({required this.url, super.key});

  final String url;

  static Uri? validUri(String value) => productWebUri(value);

  @override
  State<ProductWebPage> createState() => _ProductWebPageState();
}

class _ProductWebPageState extends State<ProductWebPage> {
  late final WebViewController _controller;
  late final ProductWebBridgeDispatcher _bridge;
  var _loading = true;
  var _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _bridge = ProductWebBridgeDispatcher(
      reportRisk: ({required productId, required orderNo}) async {
        await context.read<ReportService>().reportRisk(
          productId: productId,
          orderNo: orderNo,
          sceneType: '10',
          startTimeSeconds: ReportService.nowSeconds(),
        );
      },
      openExternalUrl: (url) => const ExternalUrlBridge().openHttpUrl(url),
      openUrl: _openUrl,
      closePage: _closePage,
      goHome: _goHome,
      requestAppReview: _requestAppReview,
      buildPublicParams: (path) =>
          context.read<ApiClient>().buildSignedQuery(path: path),
      reloadUrl: _loadUrl,
    );
    final uri = ProductWebPage.validUri(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        ProductWebBridgeContract.handler,
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _loadFailed = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme.isEmpty) {
              return NavigationDecision.prevent;
            }
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }
            _openUrl(request.url);
            return NavigationDecision.prevent;
          },
        ),
      );
    if (uri != null) {
      _controller.loadRequest(uri);
    }
  }

  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    if (!mounted) return;
    final request = ProductWebBridgeRequest.decode(message.message);
    final result = await _bridge.dispatch(request);
    if (!request.expectsCallback || !mounted) return;
    final payload = jsonEncode(<String, Object?>{
      'callbackId': request.callbackId,
      'data': result.data,
    });
    await _controller.runJavaScript(
      'window.${ProductWebBridgeContract.handler}.handleMessage($payload);',
    );
  }

  Future<void> _openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme.isEmpty) {
      await _showMessage('Unable to open the requested link.');
      return;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: rawUrl)),
      );
      return;
    }
    if (uri.scheme == 'gold') {
      await _showMessage('This in-app link is not supported yet.');
      return;
    }
    await _showMessage('Unable to open the requested link.');
  }

  Future<void> _loadUrl(String rawUrl) async {
    final uri = ProductWebPage.validUri(rawUrl);
    if (uri == null) {
      throw ArgumentError.value(rawUrl, 'rawUrl', 'Invalid web URL');
    }
    await _controller.loadRequest(uri);
  }

  Future<void> _closePage() async {
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _requestAppReview() async {
    await const AppReviewBridge().requestReview();
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final uri = ProductWebPage.validUri(widget.url);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan application'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(CupertinoIcons.back),
          onPressed: _closePage,
        ),
      ),
      body: uri == null
          ? const Center(child: Text('Unable to open this page.'))
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const LinearProgressIndicator(),
                if (_loadFailed)
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadFailed = false;
                        });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
              ],
            ),
    );
  }
}
