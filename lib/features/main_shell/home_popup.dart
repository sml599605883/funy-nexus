import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/navigation/external_url_bridge.dart';

import 'home_popup_data.dart';

typedef HomePopupExternalOpener = Future<bool> Function(String url);
typedef HomePopupInAppOpener = Future<void> Function(String url);

class HomePopup extends StatelessWidget {
  const HomePopup({
    required this.data,
    required this.externalOpener,
    this.inAppOpener,
    super.key,
  });

  static const cardKey = Key('home-popup-upgrade-card');
  static const updateButtonKey = Key('home-popup-upgrade-button');
  static const marketingImageKey = Key('home-popup-marketing-image');
  static const marketingCloseKey = Key('home-popup-marketing-close');
  static const marketingContentKey = Key('home-popup-marketing-content');
  static const marketingCloseGapKey = Key('home-popup-marketing-close-gap');

  final HomePopupData data;
  final HomePopupExternalOpener externalOpener;
  final HomePopupInAppOpener? inAppOpener;

  static Future<void> show(
    BuildContext context,
    HomePopupData data, {
    HomePopupExternalOpener? externalOpener,
    HomePopupInAppOpener? inAppOpener,
  }) async {
    if (!data.shouldShow) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: data.type == HomePopupType.marketing,
      barrierColor: AppColors.homePopupBarrier,
      useSafeArea: false,
      builder: (_) => HomePopup(
        data: data,
        externalOpener:
            externalOpener ??
            (url) => const ExternalUrlBridge().openHttpUrl(url),
        inAppOpener: inAppOpener,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data.type == HomePopupType.marketing) {
      return Material(
        color: Colors.transparent,
        child: _MarketingPopup(data: data, inAppOpener: inAppOpener),
      );
    }

    final scale = context.r(1);
    final message = data.message.isEmpty
        ? 'New version is now available'
        : data.message;
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              left: 16 * scale,
              right: 16 * scale,
              top: 303 * scale,
              height: 302 * scale,
              child: DecoratedBox(
                key: cardKey,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 12 * scale),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 20 * scale),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 214 * scale,
                            height: 72 * scale,
                            child: Image.asset(
                              AppAssets.homePopupUpgradeTitle,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.homePopupVersion,
                            borderRadius: BorderRadius.circular(11 * scale),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              16 * scale,
                              2 * scale,
                              15 * scale,
                              2 * scale,
                            ),
                            child: Text(
                              data.displayVersion,
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w700,
                                height: 17 / 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 38 * scale,
                          right: 46 * scale,
                        ),
                        child: Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16 * scale,
                            height: 19 / 16,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48 * scale,
                          child: GestureDetector(
                            key: updateButtonKey,
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              Navigator.of(context).pop();
                              await externalOpener(data.targetUrl);
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.loginButtonStart,
                                    AppColors.loginButtonEnd,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24 * scale),
                              ),
                              child: Center(
                                child: Text(
                                  'Update Now',
                                  style: TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w700,
                                    height: 17 / 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16 * scale,
              top: 208 * scale,
              width: 170 * scale,
              height: 244 * scale,
              child: IgnorePointer(
                child: Image.asset(
                  AppAssets.homePopupUpgradeRocket,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketingPopup extends StatelessWidget {
  const _MarketingPopup({required this.data, required this.inAppOpener});

  final HomePopupData data;
  final HomePopupInAppOpener? inAppOpener;

  @override
  Widget build(BuildContext context) {
    final popupWidth = MediaQuery.sizeOf(context).width - 32;
    return Center(
      child: SingleChildScrollView(
        key: HomePopup.marketingContentKey,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          width: popupWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                key: HomePopup.marketingImageKey,
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.of(context).pop();
                  final targetUrl = data.targetUrl.trim();
                  if (targetUrl.isNotEmpty) {
                    await inAppOpener?.call(targetUrl);
                  }
                },
                child: Image.network(
                  data.imageUrl,
                  width: popupWidth,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, error, stackTrace) =>
                      SizedBox(width: popupWidth),
                ),
              ),
              const SizedBox(key: HomePopup.marketingCloseGapKey, height: 16),
              GestureDetector(
                key: HomePopup.marketingCloseKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Image.asset(
                  AppAssets.mineAccountPanelClose,
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
