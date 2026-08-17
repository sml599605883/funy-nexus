import 'package:flutter/material.dart';
import 'package:fund_nexus/features/mine/account_session_coordinator.dart';
import 'package:fund_nexus/features/mine/widgets/green_action_panel_dialog.dart';

class AccountPanelDialog extends StatelessWidget {
  const AccountPanelDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return GreenActionPanelDialog(
      dialogKey: const Key('mine-account-panel'),
      firstActionKey: const Key('mine-account-log-out'),
      secondActionKey: const Key('mine-account-delete'),
      closeKey: const Key('mine-account-panel-close'),
      firstLabel: 'Log out',
      secondLabel: 'Delete Account',
      closeSemanticLabel: 'Close account panel',
      onFirstPressed: () => Navigator.of(context).pop(AccountExitAction.logOut),
      onSecondPressed: () =>
          Navigator.of(context).pop(AccountExitAction.deleteAccount),
    );
  }
}
