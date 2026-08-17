import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

class CertificationGuidance extends StatelessWidget {
  const CertificationGuidance({required this.text, this.width, super.key});

  static const _maxLines = 3;
  static const _lineHeight = 19 / 16;

  final String text;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width == null ? null : context.r(width!),
      height: context.r(57),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = _largestFittingFontSize(
            text: text,
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            minFontSize: context.r(12),
            maxFontSize: context.r(28),
          );
          return Text(
            text,
            maxLines: _maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.identityUploadGuidance,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: _lineHeight,
            ),
          );
        },
      ),
    );
  }

  static double _largestFittingFontSize({
    required String text,
    required double maxWidth,
    required double maxHeight,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required double minFontSize,
    required double maxFontSize,
  }) {
    const step = 0.5;
    for (
      var fontSize = maxFontSize;
      fontSize >= minFontSize;
      fontSize -= step
    ) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: _lineHeight,
          ),
        ),
        maxLines: _maxLines,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: maxWidth);
      if (!painter.didExceedMaxLines && painter.height <= maxHeight) {
        return fontSize;
      }
    }
    return minFontSize;
  }
}

class CertificationPageHeader extends StatelessWidget {
  const CertificationPageHeader({
    required this.title,
    this.onBack,
    this.backButtonKey,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final Key? backButtonKey;

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    if (back == null) {
      return SizedBox(
        height: context.r(60),
        child: Center(child: _Title(text: title)),
      );
    }
    return SizedBox(
      height: context.r(60),
      child: Row(
        children: [
          SizedBox(width: context.r(24)),
          SizedBox(
            width: context.r(24),
            height: context.r(24),
            child: IconButton(
              key: backButtonKey,
              onPressed: back,
              icon: Image.asset(AppAssets.identityBackButton),
              padding: EdgeInsets.zero,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          Expanded(
            child: Center(child: _Title(text: title)),
          ),
          SizedBox(width: context.r(48)),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.identityTitle,
        fontSize: context.r(17),
        fontWeight: FontWeight.w600,
        height: 24 / 17,
      ),
    );
  }
}
