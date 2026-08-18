import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_contract.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_dispatcher.dart';
import 'package:fund_nexus/features/product/web/product_web_bridge_models.dart';

void main() {
  test('decodes DC bridge messages and preserves callback metadata', () {
    final request = ProductWebBridgeRequest.decode('''
      {"action":"${ProductWebBridgeContract.uploadRiskLoan}",
       "callbackId":"callback-1",
       "data":{"pesters":"product-1","readjusts":42}}
    ''');

    expect(request.action, ProductWebBridgeContract.uploadRiskLoan);
    expect(request.callbackId, 'callback-1');
    expect(request.data['pesters'], 'product-1');
    expect(request.data['readjusts'], 42);
    expect(request.expectsCallback, isTrue);
  });

  test('dispatches risk reporting with DC field names', () async {
    String? capturedProductId;
    String? capturedOrderNo;
    final dispatcher = ProductWebBridgeDispatcher(
      reportRisk: ({required productId, required orderNo}) async {
        capturedProductId = productId;
        capturedOrderNo = orderNo;
      },
    );
    final result = await dispatcher.dispatch(
      ProductWebBridgeRequest.decode('''
        {"action":"${ProductWebBridgeContract.uploadRiskLoan}",
         "data":{"pesters":"product-1","readjusts":42}}
      '''),
    );

    expect(result.code, 0);
    expect(capturedProductId, 'product-1');
    expect(capturedOrderNo, '42');
  });

  test('returns signed public params through the callback result', () async {
    final dispatcher = ProductWebBridgeDispatcher(
      buildPublicParams: (path) async => <String, Object?>{
        'path': path,
        'hoods': 'signature',
      },
    );
    final result = await dispatcher.dispatch(
      ProductWebBridgeRequest.decode('''
        {"action":"${ProductWebBridgeContract.publicParams}",
         "callbackId":"callback-2","data":"/viler/public"}
      '''),
    );

    expect(result.code, 0);
    expect(result.data, {'path': '/viler/public', 'hoods': 'signature'});
  });

  test('opens the DC Google Play target in the external browser', () async {
    String? openedUrl;
    final dispatcher = ProductWebBridgeDispatcher(
      openExternalUrl: (url) async {
        openedUrl = url;
        return true;
      },
    );

    final result = await dispatcher.dispatch(
      ProductWebBridgeRequest.decode('''
        {"action":"${ProductWebBridgeContract.openGooglePlay}",
         "data":"https://example.com/campaign"}
      '''),
    );

    expect(result.code, 0);
    expect(openedUrl, 'https://example.com/campaign');
  });

  test('rejects a non-web Google Play target', () async {
    final dispatcher = const ProductWebBridgeDispatcher();

    final result = await dispatcher.dispatch(
      ProductWebBridgeRequest.decode('''
        {"action":"${ProductWebBridgeContract.openGooglePlay}",
         "data":"itms-services://untrusted"}
      '''),
    );

    expect(result.code, -1);
  });

  test('does not invent unavailable retry/account API behavior', () async {
    final dispatcher = const ProductWebBridgeDispatcher();
    final retry = await dispatcher.dispatch(
      ProductWebBridgeRequest.decode('''
        {"action":"${ProductWebBridgeContract.retryOrder}",
         "data":{"readjusts":"order-1"}}
      '''),
    );
    final account = await dispatcher.dispatch(
      ProductWebBridgeRequest.decode('''
        {"action":"${ProductWebBridgeContract.changeAccount}",
         "data":{"pesters":"product-1","readjusts":"order-1"}}
      '''),
    );

    expect(retry.code, -1);
    expect(account.code, -1);
  });
}
