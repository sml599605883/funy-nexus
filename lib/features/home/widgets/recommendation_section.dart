import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({required this.items, this.onApply, super.key});

  final List<HomeRecommendationData> items;
  final ValueChanged<HomeRecommendationData>? onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('home-recommendation-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Image.asset(
              AppAssets.mineSectionTitleMarker,
              key: const Key('home-recommendation-title-marker'),
              width: context.r(22),
              height: context.r(22),
            ),
            SizedBox(width: context.r(4)),
            Text(
              'Recommendation',
              style: TextStyle(
                color: AppColors.homeValue,
                fontSize: context.r(16),
                fontWeight: FontWeight.w700,
                height: 19 / 16,
              ),
            ),
          ],
        ),
        SizedBox(height: context.r(12)),
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) SizedBox(height: context.r(12)),
          _RecommendationCard(item: items[index], onApply: onApply),
        ],
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onApply});

  final HomeRecommendationData item;
  final ValueChanged<HomeRecommendationData>? onApply;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.productName} recommendation',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onApply?.call(item),
        child: Container(
          key: Key('home-recommendation-card-${item.productId}'),
          height: context.r(143),
          padding: EdgeInsets.fromLTRB(
            context.r(12),
            context.r(4),
            context.r(12),
            context.r(8),
          ),
          decoration: BoxDecoration(
            color: AppColors.homeRecommendationSurface,
            borderRadius: BorderRadius.circular(context.r(12)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.homeRecommendationShadow,
                offset: Offset(0, 4),
                blurRadius: 9,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: context.r(26),
                child: _ProductStrip(item: item),
              ),
              Positioned(
                top: context.r(34),
                left: 0,
                right: context.r(144),
                child: _RecommendationAmount(item: item),
              ),
              Positioned(
                top: context.r(21),
                right: 0,
                width: context.r(132),
                child: _RecommendationApply(item: item),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: context.r(34),
                child: Container(
                  height: context.r(1),
                  color: AppColors.homeTermDivider,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _RecommendationTerms(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStrip extends StatelessWidget {
  const _ProductStrip({required this.item});

  final HomeRecommendationData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.r(8)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(4)),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.homeRecommendationStripStart,
            AppColors.homeRecommendationSurface,
          ],
        ),
      ),
      child: Row(
        children: [
          _ProductLogo(imageUrl: item.productLogo),
          SizedBox(width: context.r(4)),
          Expanded(
            child: Text(
              item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: context.r(10),
                height: 16 / 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductLogo extends StatelessWidget {
  const _ProductLogo({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.homeValue,
        borderRadius: BorderRadius.circular(context.r(2)),
      ),
      child: Text(
        'Cash',
        style: TextStyle(
          color: AppColors.surface,
          fontSize: context.r(4),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final url = imageUrl.trim();
    return SizedBox(
      key: const Key('home-recommendation-product-logo'),
      width: context.r(14),
      height: context.r(14),
      child: url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}

class _RecommendationAmount extends StatelessWidget {
  const _RecommendationAmount({required this.item});

  final HomeRecommendationData item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: context.r(30),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.amount,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.homeValue,
                fontSize: context.r(24),
                fontWeight: FontWeight.w700,
                height: 29 / 24,
              ),
            ),
          ),
        ),
        SizedBox(height: context.r(4)),
        SizedBox(
          height: context.r(14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.amountLabel,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.homeCaption,
                fontSize: context.r(12),
                height: 14 / 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationApply extends StatelessWidget {
  const _RecommendationApply({required this.item});

  final HomeRecommendationData item;

  @override
  Widget build(BuildContext context) {
    final actionText = item.actionText.isEmpty ? 'Apply Now' : item.actionText;
    return SizedBox(
      height: context.r(62),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: context.r(20),
            left: 0,
            right: 0,
            height: context.r(36),
            child: Container(
              key: Key('home-recommendation-apply-${item.productId}'),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(24)),
                gradient: _buttonGradient(item.buttonState),
              ),
              child: Text(
                actionText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: context.r(18),
                  fontWeight: FontWeight.w700,
                  height: 27 / 18,
                ),
              ),
            ),
          ),
          if (item.highlights.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              width: context.r(128),
              height: context.r(26),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: context.r(6)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(context.r(15)),
                    topRight: Radius.circular(context.r(24)),
                    bottomRight: Radius.circular(context.r(24)),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.homeRecommendationBadgeStart,
                      AppColors.homeRecommendationBadgeEnd,
                    ],
                  ),
                ),
                child: Text(
                  item.highlights.join(' / '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: context.r(9),
                    height: 11 / 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  LinearGradient _buttonGradient(int state) {
    return switch (state) {
      -1 => const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          AppColors.homeRecommendationDisabledStart,
          AppColors.homeRecommendationDisabledEnd,
        ],
      ),
      0 => const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          AppColors.homeRecommendationAttentionStart,
          AppColors.homeRecommendationAttentionEnd,
        ],
      ),
      _ => const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [AppColors.homeApplyButtonStart, AppColors.homeApplyButtonEnd],
      ),
    };
  }
}

class _RecommendationTerms extends StatelessWidget {
  const _RecommendationTerms({required this.item});

  final HomeRecommendationData item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RecommendationTerm(
          label: item.interestRateLabel,
          value: item.interestRate,
        ),
        SizedBox(height: context.r(10)),
        _RecommendationTerm(label: item.loanTermLabel, value: item.loanTerm),
      ],
    );
  }
}

class _RecommendationTerm extends StatelessWidget {
  const _RecommendationTerm({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.r(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.homeRecommendationMuted,
                fontSize: context.r(10),
                height: 12 / 10,
              ),
            ),
          ),
          SizedBox(width: context.r(8)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: context.r(10),
                  height: 12 / 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
