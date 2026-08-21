import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_contract.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_models.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

void main() {
  test('reads the product id only from Antimanagement URLs', () {
    expect(
      productWebRetentionProductId(
        'https://web.example.com/#/Antimanagement?pesters=product-9',
      ),
      'product-9',
    );
    expect(
      productWebRetentionProductId(
        'https://web.example.com/Antimanagement?pesters=product-10',
      ),
      'product-10',
    );
    expect(
      productWebRetentionProductId(
        'https://web.example.com/#/OtherPage?pesters=product-9',
      ),
      isEmpty,
    );
    expect(
      productWebRetentionProductId('https://web.example.com/#/Antimanagement'),
      isEmpty,
    );
  });

  test('uses Loading as the default and the loaded WebView title', () {
    expect(
      resolveProductWebTitle(pageTitle: null, fallback: 'Loading...'),
      'Loading...',
    );
    expect(
      productWebTitleFromJavaScriptResult(
        '"Loan status"',
        fallback: 'Loading...',
      ),
      'Loan status',
    );
    expect(
      productWebTitleFromJavaScriptResult(' ', fallback: 'Loading...'),
      'Loading...',
    );
  });

  test('allows only document schemes inside Product WebView', () {
    expect(isInlineProductWebViewScheme('https'), isTrue);
    expect(isInlineProductWebViewScheme('about'), isTrue);
    expect(isInlineProductWebViewScheme('tel'), isFalse);
    expect(isInlineProductWebViewScheme('gold'), isFalse);
  });

  test('closes the Flutter route only without WebView history', () {
    expect(shouldCloseProductWebView(canGoBack: true), isFalse);
    expect(shouldCloseProductWebView(canGoBack: false), isTrue);
  });

  test('disables the WebView context menu only on iOS', () {
    expect(shouldDisableProductWebViewContextMenu(TargetPlatform.iOS), isTrue);
    expect(
      shouldDisableProductWebViewContextMenu(TargetPlatform.android),
      isFalse,
    );
  });

  test('prevents iOS image long presses before document content loads', () {
    final scripts = productWebViewInitialUserScripts(TargetPlatform.iOS);

    expect(scripts, hasLength(1));
    expect(
      scripts!.single.injectionTime,
      UserScriptInjectionTime.AT_DOCUMENT_START,
    );
    expect(scripts.single.forMainFrameOnly, isFalse);
    expect(scripts.single.source, contains('-webkit-touch-callout: none'));
    expect(scripts.single.source, contains("target.closest('img')"));
    expect(productWebViewInitialUserScripts(TargetPlatform.android), isNull);
  });

  test('uses page history for same-document hash routes', () {
    expect(
      ProductWebViewBackHistory.shouldUsePageHistoryGo(
        WebHistory(
          currentIndex: 1,
          list: <WebHistoryItem>[
            WebHistoryItem(index: 0, url: WebUri('https://h5.example/#/A')),
            WebHistoryItem(index: 1, url: WebUri('https://h5.example/#/B')),
          ],
        ),
      ),
      isTrue,
    );
  });

  test('uses native history for cross-document routes', () {
    expect(
      ProductWebViewBackHistory.shouldUsePageHistoryGo(
        WebHistory(
          currentIndex: 1,
          list: <WebHistoryItem>[
            WebHistoryItem(index: 0, url: WebUri('https://h5.example/A')),
            WebHistoryItem(index: 1, url: WebUri('https://h5.example/B')),
          ],
        ),
      ),
      isFalse,
    );
  });

  test('uses controller only while it is still active', () {
    final controller = Object();
    expect(
      canUseProductWebViewController(
        mounted: false,
        activeController: controller,
        controller: controller,
      ),
      isFalse,
    );
    expect(
      canUseProductWebViewController(
        mounted: true,
        activeController: Object(),
        controller: controller,
      ),
      isFalse,
    );
    expect(
      canUseProductWebViewController(
        mounted: true,
        activeController: controller,
        controller: controller,
      ),
      isTrue,
    );
  });

  test('registers the native handler before initial document loading', () {
    final events = <String>[];
    final controller = Object();
    final gate = ProductWebViewBridgeGate(
      addHandler: (value) => events.add('add:${identical(value, controller)}'),
      removeHandler: (value) =>
          events.add('remove:${identical(value, controller)}'),
    );

    gate.attach(controller);
    gate.setForeground(false);
    gate.setForeground(true);
    gate.detach();

    expect(events, ['add:true', 'remove:true', 'add:true', 'remove:true']);
  });

  test('callback JavaScript forwards callbackId and result data only', () {
    final request = ProductWebBridgeRequest.decode({
      'action': ProductWebBridgeContract.publicParams,
      'callbackId': 'cb-7',
    });
    final script = productWebCallbackScript(
      request,
      const ProductWebBridgeResult.success({'signed': true}),
    );
    final payload = script!.split('handleMessage(').last;
    final json = payload.substring(0, payload.length - 2);

    expect(jsonDecode(json), {
      'callbackId': 'cb-7',
      'data': {'signed': true},
    });
  });

  test('only main-frame failures replace the whole page', () {
    expect(shouldShowProductWebViewLoadError(isForMainFrame: true), isTrue);
    expect(shouldShowProductWebViewLoadError(isForMainFrame: false), isFalse);
    expect(shouldShowProductWebViewLoadError(isForMainFrame: null), isFalse);
  });
}
