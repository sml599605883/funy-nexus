import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/json/json.dart';
import 'package:fund_nexus/features/product/certification/widgets/certification_retention_popup.dart';

typedef CertificationRetentionPresenter =
    Future<bool> Function({
      required BuildContext context,
      required String type,
      required String productId,
      required VoidCallback onExit,
    });

class CertificationRetentionGuard {
  CertificationRetentionGuard._();

  static CertificationRetentionPresenter presenter = _defaultPresenter;

  static void resetPresenter() => presenter = _defaultPresenter;

  static VoidCallback backHandler({
    required BuildContext context,
    required String type,
    required String productId,
    required VoidCallback onDefaultBack,
  }) {
    return () {
      unawaited(
        handleBack(
          context: context,
          type: type,
          productId: productId,
          onDefaultBack: onDefaultBack,
        ),
      );
    };
  }

  static Future<void> handleBack({
    required BuildContext context,
    required String type,
    required String productId,
    required VoidCallback onDefaultBack,
    CertificationRetentionPresenter? show,
  }) async {
    final normalizedType = type.trim();
    final normalizedProductId = productId.trim();
    if (normalizedType.isEmpty || normalizedProductId.isEmpty) {
      onDefaultBack();
      return;
    }
    final shown = await (show ?? presenter)(
      context: context,
      type: normalizedType,
      productId: normalizedProductId,
      onExit: onDefaultBack,
    );
    if (!shown) onDefaultBack();
  }

  static Future<bool> _defaultPresenter({
    required BuildContext context,
    required String type,
    required String productId,
    required VoidCallback onExit,
  }) async {
    try {
      final apiClient = context.read<ApiClient>();
      await EasyLoading.show(status: 'Loading...');
      final response = await apiClient.fetchCertificationRetention(
        type: type,
        productId: productId,
      );
      if (!context.mounted) {
        await EasyLoading.dismiss();
        return false;
      }
      final dialog = Json(response.data)['leapt'];
      final imageUrl = dialog['redepositing'].stringValue.trim();
      final continueText = dialog['scall'].stringValue.trim();
      final exitText = dialog['slipperinesses'].stringValue.trim();
      await EasyLoading.dismiss();
      if (imageUrl.isEmpty || !context.mounted) return false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: AppColors.mineDialogBarrier,
        builder: (_) => CertificationRetentionPopup(
          imageUrl: imageUrl,
          continueText: continueText.isEmpty ? 'Continue' : continueText,
          exitText: exitText.isEmpty ? 'Exit' : exitText,
          onExit: onExit,
        ),
      );
      return true;
    } catch (_) {
      await EasyLoading.dismiss();
      return false;
    }
  }
}
