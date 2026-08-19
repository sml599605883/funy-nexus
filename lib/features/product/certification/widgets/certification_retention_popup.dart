import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class CertificationRetentionPopup extends StatelessWidget {
  const CertificationRetentionPopup({
    required this.imageUrl,
    required this.continueText,
    required this.exitText,
    required this.onExit,
    this.imageProvider,
    super.key,
  });

  static const cardKey = Key('certificationRetentionCard');
  static const continueButtonKey = Key('certificationRetentionContinue');
  static const exitButtonKey = Key('certificationRetentionExit');
  static const _designWidth = 295.0;
  static const _designHeight = 260.0;

  final String imageUrl;
  final String continueText;
  final String exitText;
  final VoidCallback onExit;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    final width = math.min(
      context.r(_designWidth),
      MediaQuery.sizeOf(context).width - context.r(32),
    );
    final scale = width / context.r(_designWidth);
    return Center(
      child: SizedBox(
        key: cardKey,
        width: width,
        height: context.r(_designHeight) * scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: imageProvider ?? NetworkImage(imageUrl),
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            Positioned(
              left: context.r(24) * scale,
              top: context.r(160) * scale,
              width: context.r(247) * scale,
              height: context.r(40) * scale,
              child: GestureDetector(
                key: continueButtonKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.mineRetentionContinueStart,
                        AppColors.mineRetentionContinueEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(context.r(20) * scale),
                  ),
                  child: Center(
                    child: Text(
                      continueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mineRetentionContinueText,
                        fontSize: context.r(15) * scale,
                        fontWeight: FontWeight.w700,
                        height: 18 / 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: context.r(24) * scale,
              top: context.r(212) * scale,
              width: context.r(247) * scale,
              height: context.r(18) * scale,
              child: GestureDetector(
                key: exitButtonKey,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pop();
                  onExit();
                },
                child: Center(
                  child: Text(
                    exitText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mineRetentionExitText,
                      fontSize: context.r(15) * scale,
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
