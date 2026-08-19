import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/core/navigation/external_url_bridge.dart';
import 'package:fund_nexus/core/review/app_review_bridge.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_guard.dart';
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

String resolveProductWebTitle({
  required String? pageTitle,
  required String fallback,
}) {
  final value = pageTitle?.trim() ?? '';
  return value.isNotEmpty ? value : fallback.trim();
}

String productWebTitleFromJavaScriptResult(
  Object? result, {
  required String fallback,
}) {
  var value = result?.toString() ?? '';
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is String) value = decoded;
    } on FormatException {
      // Keep the raw result when the platform returns an unquoted title.
    }
  }
  return resolveProductWebTitle(pageTitle: value, fallback: fallback);
}

const productWebTitleChannel = 'ProductWebTitle';

const productWebTitleObserverScript = r'''
(() => {
  const channel = window.ProductWebTitle;
  if (!channel || typeof channel.postMessage !== 'function') return;

  const observerKey = '__fundNexusTitleObserver';
  window[observerKey]?.disconnect?.();

  let lastTitle;
  const sendTitle = () => {
    const title = document.title || '';
    if (title === lastTitle) return;
    lastTitle = title;
    channel.postMessage(title);
  };

  const observer = new MutationObserver(sendTitle);
  observer.observe(document.documentElement, {
    childList: true,
    characterData: true,
    subtree: true,
  });
  window[observerKey] = observer;
  sendTitle();
})();
''';

String productWebRetentionProductId(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return '';
  final fragmentUri = Uri.tryParse(uri.fragment);
  final directRetention = uri.pathSegments.contains('Antimanagement');
  final fragmentRetention =
      fragmentUri?.pathSegments.contains('Antimanagement') == true;
  if (!directRetention && !fragmentRetention) return '';
  final directProductId = uri.queryParameters['pesters']?.trim() ?? '';
  if (directProductId.isNotEmpty) return directProductId;
  return fragmentUri?.queryParameters['pesters']?.trim() ?? '';
}

class _ProductWebPageState extends State<ProductWebPage> {
  late final WebViewController _controller;
  late final ProductWebBridgeDispatcher _bridge;
  var _loading = true;
  var _title = 'Loading...';
  var _loadGeneration = 0;
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
      ..addJavaScriptChannel(
        productWebTitleChannel,
        onMessageReceived: _onTitleMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              _loadGeneration++;
              setState(() {
                _loading = true;
                _title = 'Loading...';
              });
            }
          },
          onPageFinished: (_) async {
            final generation = _loadGeneration;
            Object? titleResult;
            try {
              titleResult = await _controller.runJavaScriptReturningResult(
                'document.title',
              );
            } on Object {
              // Keep the loading title when the document title cannot be read.
            }
            try {
              await _controller.runJavaScript(productWebTitleObserverScript);
            } on Object {
              // A later page load can still provide the title.
            }
            if (mounted && generation == _loadGeneration) {
              setState(() {
                _loading = false;
                _title = productWebTitleFromJavaScriptResult(
                  titleResult,
                  fallback: _title,
                );
              });
            }
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

  void _onTitleMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final title = message.message.trim();
    if (title.isEmpty || title == _title) return;
    setState(() => _title = title);
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

  Future<void> _handleBack() async {
    final currentUrl = await _controller.currentUrl() ?? widget.url;
    if (!mounted) return;
    final productId = productWebRetentionProductId(currentUrl);
    if (productId.isEmpty) {
      await _closePage();
      return;
    }
    await CertificationRetentionGuard.handleBack(
      context: context,
      type: '5',
      productId: productId,
      onDefaultBack: _closePage,
    );
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(CupertinoIcons.back),
            onPressed: _handleBack,
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
      ),
    );
  }
}
