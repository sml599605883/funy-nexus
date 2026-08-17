import 'package:flutter/material.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/widgets/green_action_panel_dialog.dart';

import 'package:fund_nexus/features/product/certification/identity_upload_method.dart';

Future<IdentityUploadMethod?> showIdentityUploadMethodPanel(
  BuildContext context,
) {
  return showDialog<IdentityUploadMethod>(
    context: context,
    barrierColor: AppColors.mineDialogBarrier,
    builder: (_) => GreenActionPanelDialog(
      dialogKey: const Key('identityUploadMethodPanel'),
      firstActionKey: const Key('identityUploadCamera'),
      secondActionKey: const Key('identityUploadAlbum'),
      closeKey: const Key('identityUploadMethodPanelClose'),
      firstLabel: 'Camera',
      secondLabel: 'Album',
      closeSemanticLabel: 'Close upload methods',
      onFirstPressed: () =>
          Navigator.of(context).pop(IdentityUploadMethod.camera),
      onSecondPressed: () =>
          Navigator.of(context).pop(IdentityUploadMethod.album),
    ),
  );
}
