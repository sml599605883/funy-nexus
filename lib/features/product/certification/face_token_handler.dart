import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:fund_nexus/features/product/certification/identity_selection_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';

const _poorImageQualityTitle = 'Poor Image Quality';
const _poorImageQualityMessage =
    "The submitted ID photo didn't meet our quality standards. Please capture "
    'a new one with better focus and lighting, or upload an existing clear '
    'photo.';
const _tokenFailureFallback = 'Failed to get verification token';

Future<bool> handleFaceTokenResponse(
  BuildContext context, {
  required FaceLivenessToken token,
  required String productId,
}) async {
  if (token.resultCode == '200') return true;

  await EasyLoading.dismiss();
  if (!context.mounted) return false;

  if (token.resultCode == '400') {
    final uploadAnother = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_poorImageQualityTitle),
        content: const Text(_poorImageQualityMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Upload Another'),
          ),
        ],
      ),
    );
    if (uploadAnother == true && context.mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => IdentitySelectionPage(productId: productId),
        ),
      );
    }
    return false;
  }

  await EasyLoading.showError(
    token.errorMessage.isNotEmpty ? token.errorMessage : _tokenFailureFallback,
  );
  return false;
}
