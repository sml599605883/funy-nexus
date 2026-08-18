import 'product_web_bridge_contract.dart';
import 'product_web_bridge_models.dart';

typedef ProductWebRiskReporter =
    Future<void> Function({required String productId, required String orderNo});
typedef ProductWebUrlAction = Future<void> Function(String url);
typedef ProductWebExternalUrlAction = Future<bool> Function(String url);
typedef ProductWebParamsBuilder =
    Future<Map<String, Object?>> Function(String path);
typedef ProductWebRetryAction = Future<String> Function(String orderNo);
typedef ProductWebAccountAction =
    Future<String?> Function({
      required String productId,
      required String orderNo,
    });
typedef ProductWebAsyncAction = Future<void> Function();

class ProductWebBridgeDispatcher {
  const ProductWebBridgeDispatcher({
    this.reportRisk,
    this.openExternalUrl,
    this.openUrl,
    this.closePage,
    this.goHome,
    this.requestAppReview,
    this.buildPublicParams,
    this.retryOrder,
    this.changeAccount,
    this.reloadUrl,
  });

  final ProductWebRiskReporter? reportRisk;
  final ProductWebExternalUrlAction? openExternalUrl;
  final ProductWebUrlAction? openUrl;
  final ProductWebAsyncAction? closePage;
  final ProductWebAsyncAction? goHome;
  final ProductWebAsyncAction? requestAppReview;
  final ProductWebParamsBuilder? buildPublicParams;
  final ProductWebRetryAction? retryOrder;
  final ProductWebAccountAction? changeAccount;
  final ProductWebUrlAction? reloadUrl;

  Future<ProductWebBridgeResult> dispatch(
    ProductWebBridgeRequest request,
  ) async {
    try {
      switch (request.action) {
        case ProductWebBridgeContract.uploadRiskLoan:
          final productId = _value(request, 'pesters');
          if (productId.isEmpty) {
            return const ProductWebBridgeResult.failure('Missing productId');
          }
          await reportRisk?.call(
            productId: productId,
            orderNo: _value(request, 'readjusts'),
          );
          return const ProductWebBridgeResult.success();
        case ProductWebBridgeContract.openGooglePlay:
          final url = _value(request, 'appPkg', fallbackToRaw: true);
          final uri = Uri.tryParse(url);
          if (url.isEmpty ||
              uri == null ||
              uri.host.isEmpty ||
              (uri.scheme != 'http' && uri.scheme != 'https')) {
            return const ProductWebBridgeResult.failure('Invalid external url');
          }
          final opened = await openExternalUrl?.call(uri.toString()) ?? false;
          return opened
              ? const ProductWebBridgeResult.success()
              : const ProductWebBridgeResult.failure(
                  'Unable to open external url',
                );
        case ProductWebBridgeContract.openUrl:
          final url = _value(request, 'url', fallbackToRaw: true);
          if (url.isEmpty || Uri.tryParse(url)?.scheme.isEmpty != false) {
            return const ProductWebBridgeResult.failure('Invalid url');
          }
          await openUrl?.call(url);
          return const ProductWebBridgeResult.success();
        case ProductWebBridgeContract.close:
          await closePage?.call();
          return const ProductWebBridgeResult.success();
        case ProductWebBridgeContract.home:
          await goHome?.call();
          return const ProductWebBridgeResult.success();
        case ProductWebBridgeContract.grade:
          await requestAppReview?.call();
          return const ProductWebBridgeResult.success();
        case ProductWebBridgeContract.publicParams:
          final path = request.rawDataString;
          if (path.isEmpty) {
            return const ProductWebBridgeResult.failure('Missing path');
          }
          final params = await buildPublicParams?.call(path);
          if (params == null) {
            return const ProductWebBridgeResult.failure(
              'Public params are unavailable',
            );
          }
          return ProductWebBridgeResult.success(
            Map<String, dynamic>.from(params),
          );
        case ProductWebBridgeContract.retryOrder:
          final orderNo = _value(request, 'readjusts');
          if (orderNo.isEmpty || retryOrder == null) {
            return const ProductWebBridgeResult.failure('Missing orderNo');
          }
          final url = (await retryOrder!(orderNo)).trim();
          if (url.isEmpty) {
            return const ProductWebBridgeResult.failure(
              'Missing retry result url',
            );
          }
          await (reloadUrl ?? openUrl)?.call(url);
          return const ProductWebBridgeResult.success();
        case ProductWebBridgeContract.changeAccount:
          final productId = _value(request, 'pesters');
          final orderNo = _value(request, 'readjusts');
          if (productId.isEmpty || orderNo.isEmpty || changeAccount == null) {
            return const ProductWebBridgeResult.failure(
              'Missing account information',
            );
          }
          final url = await changeAccount!(
            productId: productId,
            orderNo: orderNo,
          );
          if (url != null && url.trim().isNotEmpty) {
            await (reloadUrl ?? openUrl)?.call(url.trim());
          }
          return const ProductWebBridgeResult.success();
        default:
          return ProductWebBridgeResult.failure(
            'Unsupported action: ${request.action}',
            code: -2,
          );
      }
    } catch (error) {
      final message = error.toString().trim();
      return ProductWebBridgeResult.failure(
        message.isEmpty ? 'Unable to complete action' : message,
      );
    }
  }

  String _value(
    ProductWebBridgeRequest request,
    String key, {
    bool fallbackToRaw = false,
  }) {
    final value = request.data[key]?.toString().trim() ?? '';
    return value.isNotEmpty || !fallbackToRaw ? value : request.rawDataString;
  }
}
