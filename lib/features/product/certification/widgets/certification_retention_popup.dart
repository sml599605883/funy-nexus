import 'package:flutter/material.dart';
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
  static const _designWidth = 375.0;
  static const _designHeight = 500.0;
  static const _sourceContentHeight = 260.0;

  final String imageUrl;
  final String continueText;
  final String exitText;
  final VoidCallback onExit;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / _designWidth;
        final verticalScale = _designHeight / _sourceContentHeight;
        return Center(
          child: SizedBox(
            key: cardKey,
            width: width,
            height: width * (_designHeight / _designWidth),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: imageProvider ?? NetworkImage(imageUrl),
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                Positioned(
                  left: 64 * scale,
                  right: 64 * scale,
                  top: 307 * scale,
                  height: 40 * scale,
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
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                      child: Center(
                        child: Text(
                          continueText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.mineRetentionContinueText,
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w700,
                            height: 18 / 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 64 * scale,
                  right: 64 * scale,
                  top: 359 * scale,
                  height: 18 * scale,
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
                          fontSize: 15 * scale,
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
      },
    );
  }
}
