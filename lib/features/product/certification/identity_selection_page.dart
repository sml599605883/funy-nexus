import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/core/report/report_service.dart';
import 'package:fund_nexus/core/report/risk_report_scene.dart';
import 'package:fund_nexus/features/product/certification/identity_upload_page.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

class IdentitySelectionPage extends StatefulWidget {
  const IdentitySelectionPage({required this.productId, super.key});

  final String productId;

  @override
  State<IdentitySelectionPage> createState() => _IdentitySelectionPageState();
}

class _IdentitySelectionPageState extends State<IdentitySelectionPage> {
  ProductIdentityData? _identityData;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadIdentityOptions();
  }

  Future<void> _loadIdentityOptions() async {
    setState(() {
      _error = null;
      _identityData = null;
    });
    try {
      final data = await context.read<ProductGateway>().fetchIdentityOptions(
        widget.productId,
      );
      if (!mounted) return;
      setState(() => _identityData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _identityData;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.identityVerificationBackground,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Column(
              children: [
                _IdentityHeader(onBack: () => Navigator.of(context).maybePop()),
                SizedBox(height: context.r(110)),
                Expanded(
                  child: _IdentityBody(
                    data: data,
                    error: _error,
                    onRetry: _loadIdentityOptions,
                    productId: widget.productId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.onBack});

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

class _IdentityBody extends StatelessWidget {
  const _IdentityBody({
    required this.data,
    required this.error,
    required this.onRetry,
    required this.productId,
  });

  final ProductIdentityData? data;
  final Object? error;
  final Future<void> Function() onRetry;
  final String productId;

  @override
  Widget build(BuildContext context) {
    if (data == null && error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return _IdentityFeedback(
        message: 'Unable to load ID types.',
        onRetry: onRetry,
      );
    }
    if (data!.groups.isEmpty) {
      return _IdentityFeedback(
        message: 'No ID types are available.',
        onRetry: onRetry,
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        context.r(16),
        0,
        context.r(16),
        context.r(18),
      ),
      child: Column(
        children: [
          _IdentitySection(
            title: 'Recommended ID Type',
            types: data!.recommendedTypes,
            productId: productId,
          ),
          if (data!.otherTypes.isNotEmpty) ...[
            SizedBox(height: context.r(12)),
            _IdentitySection(
              title: 'Other Options',
              types: data!.otherTypes,
              productId: productId,
            ),
          ],
        ],
      ),
    );
  }
}

class _IdentityFeedback extends StatelessWidget {
  const _IdentityFeedback({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: AppColors.identityTitle)),
          SizedBox(height: context.r(16)),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({
    required this.title,
    required this.types,
    required this.productId,
  });

  final String title;
  final List<String> types;
  final String productId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.identitySectionSurface,
            AppColors.identitySectionGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      padding: EdgeInsets.fromLTRB(
        context.r(12),
        context.r(12),
        context.r(12),
        context.r(12),
      ),
      child: Column(
        children: [
          _SectionTitle(title: title),
          SizedBox(height: context.r(18)),
          Container(
            decoration: BoxDecoration(
              color: AppColors.identitySectionSurface,
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
            padding: EdgeInsets.symmetric(horizontal: context.r(16)),
            child: Column(
              children: [
                for (var index = 0; index < types.length; index++) ...[
                  _IdentityTypeRow(type: types[index], productId: productId),
                  if (index != types.length - 1)
                    _DashedDivider(color: AppColors.identityDivider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('identityDashedDivider'),
      height: context.r(1),
      width: double.infinity,
      child: CustomPaint(painter: _DashedDividerPainter(color)),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 8.0;
    const dashGap = 8.0;
    for (var start = 0.0; start < size.width; start += dashWidth + dashGap) {
      canvas.drawLine(
        Offset(start, size.height / 2),
        Offset(
          (start + dashWidth).clamp(0, size.width).toDouble(),
          size.height / 2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          AppAssets.identitySectionDecorationLeading,
          width: context.r(19),
          height: context.r(6),
        ),
        SizedBox(width: context.r(16)),
        Text(
          title,
          style: TextStyle(
            color: AppColors.identityTitle,
            fontSize: context.r(16),
            fontWeight: FontWeight.w700,
            height: 19 / 16,
          ),
        ),
        SizedBox(width: context.r(16)),
        Image.asset(
          AppAssets.identitySectionDecorationTrailing,
          width: context.r(19),
          height: context.r(6),
        ),
      ],
    );
  }
}

class _IdentityTypeRow extends StatelessWidget {
  const _IdentityTypeRow({required this.type, required this.productId});

  final String type;
  final String productId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: type,
      child: InkWell(
        onTap: () {
          RiskReportScene.report(
            context.read<ReportService?>(),
            productId: productId,
            sceneType: '2',
          );
          unawaited(
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => IdentityUploadPage(
                  productId: productId,
                  identityType: type,
                  promptMessage: context
                      .read<SessionStore>()
                      .productDetailIdentityGuidance,
                ),
              ),
            ),
          );
        },
        child: SizedBox(
          height: context.r(50),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.identityItemText,
                    fontSize: context.r(15),
                    height: 18 / 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.identityItemText,
                size: context.r(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
