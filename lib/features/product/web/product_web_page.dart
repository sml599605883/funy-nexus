import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fund_nexus/core/navigation/external_url_bridge.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/review/app_review_bridge.dart';
import 'package:fund_nexus/features/product/account/account_list_page.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_guard.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_contract.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_dispatcher.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_models.dart';

bool isInlineProductWebViewScheme(String scheme) =>
    switch (scheme.toLowerCase()) {
      'http' || 'https' || 'about' || 'data' || 'javascript' || 'file' => true,
      _ => false,
    };

bool shouldCloseProductWebView({required bool canGoBack}) => !canGoBack;

bool shouldDisableProductWebViewContextMenu(TargetPlatform platform) =>
    platform == TargetPlatform.iOS;

const String productIosImageLongPressPreventionScript = r'''
(() => {
  const style = document.createElement('style');
  style.textContent = `
    img {
      -webkit-touch-callout: none !important;
      -webkit-user-select: none !important;
      user-select: none !important;
    }
  `;
  (document.head || document.documentElement).appendChild(style);
  document.addEventListener('contextmenu', (event) => {
    const target = event.target;
    if (target instanceof Element && target.closest('img')) {
      event.preventDefault();
    }
  }, true);
})();
''';

UnmodifiableListView<UserScript>? productWebViewInitialUserScripts(
  TargetPlatform platform,
) {
  if (platform != TargetPlatform.iOS) return null;
  return UnmodifiableListView<UserScript>([
    UserScript(
      source: productIosImageLongPressPreventionScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      forMainFrameOnly: false,
    ),
  ]);
}

class ProductWebViewBackHistory {
  ProductWebViewBackHistory._();

  static bool shouldUsePageHistoryGo(WebHistory? history) {
    final currentIndex = history?.currentIndex;
    final items = history?.list;
    if (currentIndex == null ||
        items == null ||
        currentIndex <= 0 ||
        currentIndex >= items.length) {
      return false;
    }
    final current = Uri.tryParse(items[currentIndex].url?.toString() ?? '');
    final previous = Uri.tryParse(
      items[currentIndex - 1].url?.toString() ?? '',
    );
    if (current == null || previous == null) return false;
    return current.fragment.isNotEmpty &&
        previous.fragment.isNotEmpty &&
        current.removeFragment() == previous.removeFragment();
  }
}

bool shouldShowProductWebViewLoadError({required bool? isForMainFrame}) =>
    isForMainFrame == true;

bool canUseProductWebViewController({
  required bool mounted,
  required Object? activeController,
  required Object? controller,
}) =>
    mounted &&
    activeController != null &&
    identical(activeController, controller);

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

String? productWebCallbackScript(
  ProductWebBridgeRequest request,
  ProductWebBridgeResult result,
) {
  if (!request.expectsCallback) return null;
  final payload = jsonEncode(<String, Object?>{
    'callbackId': request.callbackId,
    'data': result.data,
  });
  return 'window.${ProductWebBridgeContract.handler}.handleMessage($payload);';
}

class ProductWebViewBridgeGate {
  ProductWebViewBridgeGate({
    required this.addHandler,
    required this.removeHandler,
  });

  final void Function(Object controller) addHandler;
  final void Function(Object controller) removeHandler;
  Object? _controller;
  bool _foreground = true;
  bool _registered = false;

  void attach(Object controller) {
    detach();
    _controller = controller;
    _sync();
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _sync();
  }

  void detach() {
    final controller = _controller;
    if (controller != null && _registered) removeHandler(controller);
    _registered = false;
    _controller = null;
  }

  void _sync() {
    final controller = _controller;
    if (controller == null || _foreground == _registered) return;
    if (_foreground) {
      addHandler(controller);
      _registered = true;
    } else {
      removeHandler(controller);
      _registered = false;
    }
  }
}

class ProductWebPage extends StatefulWidget {
  const ProductWebPage({required this.url, super.key});

  final String url;

  static Uri? validUri(String value) => productWebUri(value);

  @override
  State<ProductWebPage> createState() => _ProductWebPageState();
}

class _ProductWebPageState extends State<ProductWebPage>
    with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  late final ProductWebBridgeDispatcher _bridge;
  late final ProductWebViewBridgeGate _bridgeGate;
  var _loading = true;
  var _title = 'Loading...';
  var _loadFailed = false;
  var _isLeaving = false;

  Uri? get _initialUri {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bridgeGate = ProductWebViewBridgeGate(
      addHandler: (value) {
        (value as InAppWebViewController).addJavaScriptHandler(
          handlerName: ProductWebBridgeContract.handler,
          callback: _handleBridgeCall,
        );
      },
      removeHandler: (value) {
        (value as InAppWebViewController).removeJavaScriptHandler(
          handlerName: ProductWebBridgeContract.handler,
        );
      },
    );
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
      retryOrder: (orderNo) async {
        final response = await context.read<ApiClient>().retryProgressOrder(
          orderNumber: orderNo,
        );
        return response.data['topical'].stringValue.trim();
      },
      changeAccount: ({required productId, required orderNo}) async {
        if (!mounted) return null;
        unawaited(
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => AccountListPage(
                productId: productId,
                orderNumber: orderNo,
                onCompleted: _replaceAccountChangeFlow,
              ),
            ),
          ),
        );
        return null;
      },
      reloadUrl: _loadUrl,
      showLoading: () => EasyLoading.show(status: 'Loading...'),
      dismissLoading: () => EasyLoading.dismiss(animation: false),
      showError: _showMessage,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _bridgeGate.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    _bridgeGate.detach();
    _controller = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<dynamic> _handleBridgeCall(List<dynamic> arguments) async {
    final controller = _controller;
    if (!canUseProductWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return const ProductWebBridgeResult.failure(
        'WebView is inactive',
      ).toJson();
    }
    final request = ProductWebBridgeRequest.decode(
      arguments.isEmpty ? null : arguments.first,
    );
    final result = await _bridge.dispatch(request);
    final script = productWebCallbackScript(request, result);
    if (script != null &&
        canUseProductWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      await controller!.evaluateJavascript(source: script);
    }
    return result.toJson();
  }

  Future<void> _handleBack() async {
    final controller = _controller;
    var canGoBack = false;
    var currentUrl = widget.url;
    if (controller != null &&
        canUseProductWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      canGoBack = await controller.canGoBack();
      if (!mounted || !identical(_controller, controller)) return;
      currentUrl = (await controller.getUrl())?.toString() ?? currentUrl;
      if (!mounted || !identical(_controller, controller)) return;
    }
    final productId = productWebRetentionProductId(currentUrl);
    if (productId.isNotEmpty) {
      await CertificationRetentionGuard.handleBack(
        context: context,
        type: '5',
        productId: productId,
        onDefaultBack: () {
          unawaited(
            _completeBack(controller: controller, canGoBack: canGoBack),
          );
        },
      );
      return;
    }
    await _completeBack(controller: controller, canGoBack: canGoBack);
  }

  Future<void> _completeBack({
    required InAppWebViewController? controller,
    required bool canGoBack,
  }) async {
    if (!shouldCloseProductWebView(canGoBack: canGoBack) &&
        controller != null) {
      await _goBackOneHistoryEntry(controller);
      return;
    }
    _popRoute();
  }

  Future<void> _goBackOneHistoryEntry(InAppWebViewController controller) async {
    if (!canUseProductWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return;
    }
    final history = await controller.getCopyBackForwardList();
    if (!canUseProductWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return;
    }
    if (ProductWebViewBackHistory.shouldUsePageHistoryGo(history)) {
      await controller.evaluateJavascript(source: 'window.history.go(-1);');
    } else {
      await controller.goBack();
    }
  }

  Future<NavigationActionPolicy> _handleNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final uri = action.request.url;
    if (uri == null) return NavigationActionPolicy.CANCEL;
    if (isInlineProductWebViewScheme(uri.scheme)) {
      return NavigationActionPolicy.ALLOW;
    }
    await _openUrl(uri.toString());
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme.isEmpty) {
      await _showMessage('Unable to open the requested link.');
      return;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: rawUrl)),
      );
      return;
    }
    final opened = await const ExternalUrlBridge().openUri(uri);
    if (!opened) await _showMessage('Unable to open the requested link.');
  }

  Future<void> _loadUrl(String rawUrl) async {
    final uri = ProductWebPage.validUri(rawUrl);
    final controller = _controller;
    if (uri == null ||
        !canUseProductWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      return;
    }
    final currentUri = await controller!.getUrl();
    if (!canUseProductWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return;
    }
    if (currentUri?.toString().trim() == uri.toString()) {
      await controller.reload();
    } else {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
    }
  }

  Future<void> _replaceAccountChangeFlow(String rawUrl) async {
    final uri = ProductWebPage.validUri(rawUrl);
    if (uri == null || !mounted) return;
    // The account list is pushed above this WebView. Replace both routes so
    // the user cannot return to the stale account-change flow.
    unawaited(
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProductWebPage(url: uri.toString()),
        ),
        (route) => route.isFirst,
      ),
    );
  }

  Future<void> _retry() async {
    final uri = _initialUri;
    final controller = _controller;
    if (uri == null || controller == null) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  Future<void> _closePage() async {
    _popRoute();
  }

  void _popRoute() {
    if (!mounted || _isLeaving) return;
    setState(() => _isLeaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _goHome() async {
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
    final uri = _initialUri;
    return PopScope(
      canPop: _isLeaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLeaving) unawaited(_handleBack());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(CupertinoIcons.back),
            onPressed: _isLeaving ? null : _handleBack,
          ),
        ),
        body: uri == null
            ? const Center(child: Text('Unable to open this page.'))
            : _loadFailed
            ? Center(
                child: FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              )
            : Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
                    initialUserScripts: productWebViewInitialUserScripts(
                      defaultTargetPlatform,
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useShouldOverrideUrlLoading: true,
                      useHybridComposition: true,
                      isInspectable: kDebugMode,
                      disableContextMenu:
                          shouldDisableProductWebViewContextMenu(
                            defaultTargetPlatform,
                          ),
                      allowsLinkPreview:
                          !shouldDisableProductWebViewContextMenu(
                            defaultTargetPlatform,
                          ),
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                      _bridgeGate.attach(controller);
                    },
                    shouldOverrideUrlLoading: _handleNavigation,
                    onPermissionRequest: (controller, request) async =>
                        PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.DENY,
                        ),
                    onLoadStart: (controller, url) {
                      if (mounted) {
                        setState(() {
                          _loading = true;
                          _loadFailed = false;
                        });
                      }
                    },
                    onLoadStop: (controller, url) async {
                      if (!mounted) return;
                      final title = await controller.getTitle();
                      if (!mounted) return;
                      setState(() {
                        _loading = false;
                        _title = resolveProductWebTitle(
                          pageTitle: title,
                          fallback: _title,
                        );
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      if (mounted) setState(() => _loading = progress < 100);
                    },
                    onReceivedError: (controller, request, error) {
                      if (mounted &&
                          shouldShowProductWebViewLoadError(
                            isForMainFrame: request.isForMainFrame,
                          )) {
                        setState(() {
                          _loading = false;
                          _loadFailed = true;
                        });
                      }
                    },
                    onTitleChanged: (controller, title) {
                      final value = title?.trim() ?? '';
                      if (mounted && value.isNotEmpty) {
                        setState(() => _title = value);
                      }
                    },
                  ),
                  if (_loading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
      ),
    );
  }
}
