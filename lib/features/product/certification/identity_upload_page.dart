import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

class IdentityUploadPage extends StatefulWidget {
  const IdentityUploadPage({
    required this.productId,
    required this.identityType,
    super.key,
  });

  final String productId;
  final String identityType;

  @override
  State<IdentityUploadPage> createState() => _IdentityUploadPageState();
}

class _IdentityUploadPageState extends State<IdentityUploadPage> {
  String? _guidance;

  @override
  void initState() {
    super.initState();
    _loadGuidance();
  }

  Future<void> _loadGuidance() async {
    try {
      final detail = await context.read<ProductGateway>().fetchProductDetail(
        widget.productId,
      );
      if (!mounted) return;
      setState(
        () => _guidance = detail.certificationCopy.identityUploadGuidance,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _guidance = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final guidance = _guidance;
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.identityUploadBackground, fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                _UploadHeader(onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: context.r(16)),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: context.r(16),
                            top: context.r(32),
                            right: context.r(172),
                          ),
                          child: SizedBox(
                            key: const Key('identityUploadGuidance'),
                            height: context.r(57),
                            width: double.infinity,
                            child: guidance == null
                                ? null
                                : _AdaptiveGuidance(text: guidance),
                          ),
                        ),
                        SizedBox(height: context.r(31)),
                        Image.asset(
                          AppAssets.identityUploadExamples,
                          key: const Key('identityUploadDemo'),
                          width: context.r(343),
                          height: context.r(420),
                          fit: BoxFit.fill,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.r(16),
            0,
            context.r(16),
            context.r(22),
          ),
          child: _UploadButton(
            onPressed: () =>
                debugPrint('Identity upload requested: ${widget.identityType}'),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveGuidance extends StatelessWidget {
  const _AdaptiveGuidance({required this.text});

  static const _maxLines = 3;
  static const _lineHeight = 19 / 16;

  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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

class _UploadHeader extends StatelessWidget {
  const _UploadHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.r(60),
      child: Row(
        children: [
          SizedBox(width: context.r(24)),
          SizedBox(
            width: context.r(24),
            height: context.r(24),
            child: IconButton(
              onPressed: onBack,
              icon: Image.asset(AppAssets.identityBackButton),
              padding: EdgeInsets.zero,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'ID Verification',
                style: TextStyle(
                  color: AppColors.identityTitle,
                  fontSize: context.r(17),
                  fontWeight: FontWeight.w600,
                  height: 24 / 17,
                ),
              ),
            ),
          ),
          SizedBox(width: context.r(48)),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('identityUploadButton'),
      width: double.infinity,
      height: context.r(52),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(24)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.identityUploadButtonShadow,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              AppColors.homeApplyButtonStart,
              AppColors.homeApplyButtonEnd,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(context.r(24)),
            onTap: onPressed,
            child: Center(
              child: Text(
                'Upload',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: context.r(16),
                  fontWeight: FontWeight.w700,
                  height: 19 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
