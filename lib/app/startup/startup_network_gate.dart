import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_client.dart';

typedef StartupNetworkProbe = Future<bool> Function();
typedef StartupNetworkReadyBuilder = Widget Function();

class StartupNetworkGate extends StatefulWidget {
  const StartupNetworkGate({
    required this.probe,
    required this.readyBuilder,
    this.retryOnResume = true,
    super.key,
  });

  final StartupNetworkProbe probe;
  final StartupNetworkReadyBuilder readyBuilder;
  final bool retryOnResume;

  @override
  State<StartupNetworkGate> createState() => _StartupNetworkGateState();
}

class _StartupNetworkGateState extends State<StartupNetworkGate>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.retryOnResume && state == AppLifecycleState.resumed && _failed) {
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (_checking || _ready) return;
    setState(() {
      _checking = true;
      _failed = false;
    });
    try {
      final available = await widget.probe();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _ready = available;
        _failed = !available;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.readyBuilder();
    return _NetworkUnavailablePage(checking: _checking, onRetry: _check);
  }
}

class _NetworkUnavailablePage extends StatelessWidget {
  const _NetworkUnavailablePage({
    required this.checking,
    required this.onRetry,
  });

  final bool checking;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [AppColors.homeHeaderEnd, AppColors.homeHeaderStart],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const designSize = Size(375, 812);
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: designSize.width,
                      height: designSize.height,
                      child: _NetworkUnavailableContent(
                        checking: checking,
                        onRetry: onRetry,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NetworkUnavailableContent extends StatelessWidget {
  const _NetworkUnavailableContent({
    required this.checking,
    required this.onRetry,
  });

  final bool checking;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 300,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              key: const Key('startup-network-illustration'),
              width: 138,
              height: 102,
              child: Image.asset(
                AppAssets.networkErrorIllustration,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const Positioned(
          top: 414,
          left: 0,
          right: 0,
          child: SizedBox(
            width: 244,
            height: 36,
            child: Center(
              child: Text(
                'Network error, please try again later or\ncontact our customer service',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Helvetica',
                  fontWeight: FontWeight.normal,
                  height: 18 / 14,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 470,
          left: 16,
          right: 16,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment(0.11, 0),
                end: Alignment(0.69, 1),
                colors: [AppColors.loginButtonStart, AppColors.loginButtonEnd],
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.loginButtonShadow,
                  offset: Offset(0, 3),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Semantics(
              button: true,
              label: 'Try Again',
              child: TextButton(
                key: const Key('startup-network-retry'),
                onPressed: checking ? null : onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  checking ? 'Checking...' : 'Try Again',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 14,
                    fontFamily: 'Helvetica-Bold',
                    fontWeight: FontWeight.w700,
                    height: 17 / 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> probeApiTransport(ApiClient client) => client.probeTransport();
