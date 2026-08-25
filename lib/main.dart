import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fund_nexus/app/app.dart';
import 'package:fund_nexus/app/startup/startup_network_gate.dart';
import 'package:fund_nexus/core/config/app_config.dart';
import 'package:fund_nexus/core/device/device_metadata_store.dart';
import 'package:fund_nexus/core/device/device_name_sync.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_crypto.dart';
import 'package:fund_nexus/core/network/api_public_params.dart';
import 'package:fund_nexus/core/network/capture_proxy.dart';
import 'package:fund_nexus/core/push/ios_notification_route_coordinator.dart';
import 'package:fund_nexus/core/push/push_navigation_helper.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/session/session_expiry_coordinator.dart';
import 'package:fund_nexus/core/report/report_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure and start notification routing with custom navigation handler
  IosNotificationRouteCoordinator.configure(
    openRoute: PushNavigationHelper.navigateToTarget,
  );
  IosNotificationRouteCoordinator.instance.start();

  final config = AppConfig.fromEnvironment();
  final systemProxy = config.captureProxyHost.trim().isEmpty
      ? await CaptureProxyDiscovery.systemSettings()
      : null;
  final sessionStore = SessionStore.persistent();
  final deviceMetadataStore = DeviceMetadataStore.persistent();
  await sessionStore.restore();
  final sessionExpiryCoordinator = SessionExpiryCoordinator(
    sessionStore: sessionStore,
  );
  final publicParamsProvider = DeviceApiPublicParamsProvider(
    source: PluginIosPlatformMetadataSource(),
    metadataStore: deviceMetadataStore,
  );
  final apiClient = ApiClient.create(
    config: config,
    sessionStore: sessionStore,
    publicParamsProvider: publicParamsProvider,
    sessionExpiryCoordinator: sessionExpiryCoordinator,
    captureProxyHost: systemProxy?.host,
    captureProxyPort: systemProxy?.port,
  );
  final apiCrypto = ApiCrypto(
    key: config.encryptionKey,
    iv: config.encryptionIv,
  );
  final reportService = ReportService(
    apiClient: apiClient,
    sessionStore: sessionStore,
    apiCrypto: apiCrypto,
    deviceMetadataStore: deviceMetadataStore,
  );

  runApp(
    StartupNetworkGate(
      probe: () async {
        final available = await probeApiTransport(apiClient);
        if (available) {
          await DeviceNameSync(
            apiClient: apiClient,
            publicParamsProvider: publicParamsProvider,
            metadataStore: deviceMetadataStore,
          ).sync();
        }
        return available;
      },
      readyBuilder: () => FundNexusApp(
        apiClient: apiClient,
        apiCrypto: apiCrypto,
        config: config,
        sessionStore: sessionStore,
        sessionExpiryCoordinator: sessionExpiryCoordinator,
        reportService: reportService,
      ),
    ),
  );
}
