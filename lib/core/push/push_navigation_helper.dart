import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../features/login/login_page.dart';
import '../../features/progress/order_list_page.dart';
import '../../features/progress/order_list_models.dart';
import '../../features/product/state/product_application_flow.dart';
import '../../features/product/certification/certification_handoff_page.dart';
import '../../features/product/credit_review/credit_review_page.dart';
import '../../features/product/web/product_web_page.dart';
import '../../features/product/data/product_repository.dart';
import '../../core/network/api_exception.dart';
import '../../core/report/report_service.dart';
import 'ios_notification_route_coordinator.dart';
import 'push_deep_link.dart';

typedef PushNavigationLogger = void Function(String message);
typedef TabNavigator = void Function(int index);

class PushNavigationHelper {
  const PushNavigationHelper._();

  static const _parser = PushDeepLinkParser();
  static PushNavigationLogger logger = _defaultLogger;
  static TabNavigator? tabNavigator;

  static void _defaultLogger(String message) {
    debugPrint('[PushNavigation] $message');
  }

  /// Navigate to the target specified in a push notification
  static Future<void> navigateToTarget(
    String rawTarget, {
    Object? arguments,
  }) async {
    debugPrint('[PushNavigation] ========================================');
    debugPrint('[PushNavigation] navigateToTarget called!');
    debugPrint('[PushNavigation] rawTarget: $rawTarget');
    debugPrint('[PushNavigation] arguments: $arguments');
    debugPrint('[PushNavigation] ========================================');

    final target = rawTarget.trim();
    if (target.isEmpty) {
      logger('Empty navigation target');
      return;
    }

    final link = _parser.parse(target, arguments: arguments);
    logger('Parsed link: kind=${link.kind}, alias=${link.alias}');

    await _dispatch(link);
  }

  static Future<void> _dispatch(PushDeepLink link) async {
    final context = _navigatorContext;
    if (context == null || !context.mounted) {
      logger('Navigator context not available');
      return;
    }

    try {
      switch (link.kind) {
        case PushDeepLinkKind.home:
          // Navigate to home tab
          _popToRoot(context);
          if (tabNavigator != null) {
            tabNavigator!(0);
            logger('Navigated to home tab');
          } else {
            logger('Tab navigator not configured');
          }
          break;

        case PushDeepLinkKind.mine:
          // Navigate to mine/profile tab
          _popToRoot(context);
          if (tabNavigator != null) {
            tabNavigator!(2);
            logger('Navigated to mine tab');
          } else {
            logger('Tab navigator not configured');
          }
          break;

        case PushDeepLinkKind.login:
          // Navigate to login page
          await _openLogin(context);
          break;

        case PushDeepLinkKind.order:
          // Navigate to order list
          final statusCode = link.orderStatus;
          final initialStatus = OrderListStatus.fromCode(statusCode);
          await _openOrderList(context, initialStatus);
          break;

        case PushDeepLinkKind.productDetail:
          // Load product detail and navigate based on status
          final productId = link.productId;
          if (productId.isEmpty) {
            logger('Product ID missing in link');
            await _showMessage('Unable to open product');
            return;
          }
          await _loadProductDetail(context, productId);
          break;

        case PushDeepLinkKind.admission:
          // Start full admission flow (apply for product)
          final productId = link.productId;
          if (productId.isEmpty) {
            logger('Product ID missing in link');
            await _showMessage('Unable to open product');
            return;
          }
          await _applyProduct(context, productId);
          break;

        case PushDeepLinkKind.creditReview:
          // Navigate to credit review page
          final productId = link.productId;
          if (productId.isEmpty) {
            logger('Product ID missing for credit review');
            await _showMessage('Unable to open credit review');
            return;
          }
          await _openCreditReview(context, productId);
          break;

        case PushDeepLinkKind.webView:
          // Open WebView with URL
          final url = link.uri?.toString() ?? '';
          if (url.isEmpty) {
            logger('WebView URL missing');
            return;
          }
          logger('WebView navigation not yet implemented: url=$url');
          break;

        case PushDeepLinkKind.unsupported:
          logger('Unsupported navigation target: ${link.alias}');
          break;
      }
    } catch (error) {
      logger('Navigation error: $error');
      await _showMessage('Navigation failed');
    }
  }

  static BuildContext? get _navigatorContext {
    return IosNotificationRouteCoordinator.navigatorKey.currentContext;
  }

  static void _popToRoot(BuildContext context) {
    final navigator = Navigator.of(context);
    while (navigator.canPop()) {
      navigator.pop();
    }
  }

  static Future<void> _openLogin(BuildContext context) async {
    try {
      final riskStartedAtSeconds = ReportService.nowSeconds();
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => LoginPage(
            onLoginSuccess: () async {
              try {
                await context.read<ReportService>().loginSucceeded(
                  riskStartedAtSeconds: riskStartedAtSeconds,
                );
              } catch (error) {
                logger('Login success reporting failed: $error');
              }
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ),
      );
      logger('Login page opened');
    } catch (error) {
      logger('Failed to open login page: $error');
    }
  }

  static Future<void> _openOrderList(
    BuildContext context,
    OrderListStatus initialStatus,
  ) async {
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => OrderListPage(
            initialStatus: initialStatus,
          ),
        ),
      );
      logger('Order list opened with status: ${initialStatus.code} (${initialStatus.label})');
    } catch (error) {
      logger('Failed to open order list: $error');
    }
  }

  static Future<void> _loadProductDetail(
    BuildContext context,
    String productId,
  ) async {
    try {
      await context.read<ProductApplicationFlow>().resumeAfterCertification(
        productId: productId,
        openTarget: (target) => _openWebTarget(context, target),
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
        dismissLoading: () => EasyLoading.dismiss(animation: false),
        showMessage: (message) => _showMessage(message),
      );
      logger('Product detail loaded and processed for productId: $productId');
    } catch (error) {
      logger('Failed to load product detail: $error');
    }
  }

  static Future<void> _openCreditReview(
    BuildContext context,
    String productId,
  ) async {
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CreditReviewPage(productId: productId),
        ),
      );
      logger('Credit review opened for productId: $productId');
    } catch (error) {
      logger('Failed to open credit review: $error');
    }
  }

  static Future<void> _applyProduct(
    BuildContext context,
    String productId,
  ) async {
    try {
      await context.read<ProductApplicationFlow>().apply(
        productId: productId,
        openLogin: (productId) async {
          if (!context.mounted) return false;
          final riskStartedAtSeconds = ReportService.nowSeconds();
          return await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => LoginPage(
                    onLoginSuccess: () async {
                      try {
                        await context.read<ReportService>().loginSucceeded(
                          riskStartedAtSeconds: riskStartedAtSeconds,
                        );
                      } catch (error) {
                        logger('Login success reporting failed: $error');
                      }
                      if (context.mounted) Navigator.of(context).pop(true);
                    },
                  ),
                ),
              ) ??
              false;
        },
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
        dismissLoading: () => EasyLoading.dismiss(animation: false),
        showMessage: (message) => _showMessage(message),
        showLocationSettingsPrompt: (message) =>
            _showLocationSettingsPrompt(context, message),
      );
      logger('Product application flow completed for productId: $productId');
    } catch (error) {
      logger('Failed to apply product: $error');
      await _showMessage('Unable to process product application');
    }
  }

  static Future<void> _openWebTarget(BuildContext context, String target) async {
    if (ProductWebPage.validUri(target) == null) {
      await _showMessage('Unable to open the requested page.');
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => ProductWebPage(url: target)),
    );
  }

  static Future<bool> _showLocationSettingsPrompt(
    BuildContext context,
    String message,
  ) async {
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Allow Location Access'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _showMessage(String message) async {
    await EasyLoading.showToast(
      message,
      duration: const Duration(seconds: 2),
    );
  }
}
