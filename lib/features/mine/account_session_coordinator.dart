import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/session/session_store.dart';

enum AccountExitAction { logOut, deleteAccount }

class AccountSessionCoordinator {
  const AccountSessionCoordinator({
    required this.apiClient,
    required this.sessionStore,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  Future<void> execute(AccountExitAction action) async {
    if (action == AccountExitAction.logOut) {
      await apiClient.logout();
    } else {
      await apiClient.deleteAccount();
    }
    await sessionStore.clear();
  }
}
