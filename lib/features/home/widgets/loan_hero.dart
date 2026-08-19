import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';

const _creditProgressDesignWidth = 343.0;
const _creditProgressDesignHeight = 137.0;

double _creditProgressWidth(BuildContext context) =>
    math.max(0.0, MediaQuery.sizeOf(context).width - context.r(32));

double _creditProgressHeight(BuildContext context) =>
    _creditProgressWidth(context) /
    _creditProgressDesignWidth *
    _creditProgressDesignHeight;

class LoanHero extends StatelessWidget {
  const LoanHero({
    required this.productName,
    required this.productLogo,
    required this.amount,
    required this.amountLabel,
    required this.loanTerm,
    required this.loanTermLabel,
    required this.interestRate,
    required this.interestRateLabel,
    required this.description,
    required this.actionText,
    this.certificationProgress = const [],
    this.loanTermRows = const [],
    this.onApply,
    super.key,
  });

  final String productName;
  final String productLogo;
  final String amount;
  final String amountLabel;
  final String loanTerm;
  final String loanTermLabel;
  final String interestRate;
  final String interestRateLabel;
  final String description;
  final String actionText;
  final List<HomeCardProgressItem> certificationProgress;
  final List<HomeCardLoanTermRow> loanTermRows;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onApply,
        child: Container(
          key: const Key('home-loan-hero'),
          width: context.r(375),
          height: certificationProgress.isEmpty
              ? context.r(383)
              : context.r(383 + 39) + _creditProgressHeight(context),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.homeLoanHero),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: context.r(30)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.r(40)),
                child: _ProductIdentity(
                  productName: productName,
                  productLogo: productLogo,
                ),
              ),
              SizedBox(height: context.r(50)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.r(40)),
                child: _Amount(amount: amount, label: amountLabel),
              ),
              SizedBox(height: context.r(30)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.r(52)),
                child: loanTermRows.isEmpty
                    ? Row(
                        children: [
                          Expanded(
                            child: _LoanStat(
                              label: loanTermLabel,
                              value: loanTerm,
                            ),
                          ),
                          SizedBox(width: context.r(35)),
                          Expanded(
                            child: _LoanStat(
                              label: interestRateLabel,
                              value: interestRate,
                            ),
                          ),
                        ],
                      )
                    : _LoanTermStats(rows: loanTermRows),
              ),
              SizedBox(height: context.r(28)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.r(16)),
                child: SizedBox(
                  height: context.r(17),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      description,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.homeAmount,
                        fontSize: context.r(14),
                        fontWeight: FontWeight.w700,
                        height: 17 / 14,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.r(12)),
              _ApplyButton(text: actionText),
              if (certificationProgress.isNotEmpty) ...[
                SizedBox(height: context.r(39)),
                _CreditActivationProgress(items: certificationProgress),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditActivationProgress extends StatelessWidget {
  const _CreditActivationProgress({required this.items});

  final List<HomeCardProgressItem> items;

  @override
  Widget build(BuildContext context) {
    final width = _creditProgressWidth(context);
    final scale = width / _creditProgressDesignWidth;
    double metric(double value) => value * scale;
    final contentWidth = width - metric(48);
    final itemCount = items.length;
    final minimumGap = metric(4);
    final tileWidth = math.min(
      metric(46),
      (contentWidth - minimumGap * (itemCount - 1)) / itemCount,
    );
    final gapWidth = itemCount == 1
        ? 0.0
        : (contentWidth - tileWidth * itemCount) / (itemCount - 1);
    final activeCount = items.where((item) => item.selected > 0).length;

    return SizedBox(
      key: const Key('home-credit-activation-progress'),
      width: width,
      height: _creditProgressHeight(context),
      child: DecoratedBox(
        key: const Key('home-credit-activation-progress-background'),
        decoration: const BoxDecoration(
          color: AppColors.homeCreditProgressPanel,
          image: DecorationImage(
            image: AssetImage(AppAssets.homeCreditActivationProgress),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            metric(24),
            metric(62),
            metric(24),
            metric(24),
          ),
          child: Column(
            children: [
              SizedBox(
                height: metric(34),
                child: Row(
                  mainAxisAlignment: itemCount == 1
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    for (var index = 0; index < itemCount; index++) ...[
                      _CreditProgressTile(
                        item: items[index],
                        width: tileWidth,
                        index: index,
                        scale: scale,
                      ),
                      if (index < itemCount - 1) SizedBox(width: gapWidth),
                    ],
                  ],
                ),
              ),
              SizedBox(height: metric(8)),
              _CreditProgressTrack(
                activeFraction: activeCount / itemCount,
                scale: scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditProgressTile extends StatelessWidget {
  const _CreditProgressTile({
    required this.item,
    required this.width,
    required this.index,
    required this.scale,
  });

  final HomeCardProgressItem item;
  final double width;
  final int index;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final active = item.selected > 0;
    return Container(
      key: Key(
        'home-credit-activation-step-${active ? 'active' : 'inactive'}-$index',
      ),
      width: width,
      height: 34 * scale,
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: AppColors.homeCreditProgressTile,
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 12 * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.amount,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.homeCreditProgressAmount,
                  fontSize: 10 * scale,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  height: 12 / 10,
                ),
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.homeCreditProgressLabel,
                fontSize: 8 * scale,
                height: 10 / 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditProgressTrack extends StatelessWidget {
  const _CreditProgressTrack({
    required this.activeFraction,
    required this.scale,
  });

  final double activeFraction;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4 * scale),
      child: SizedBox(
        key: const Key('home-credit-activation-track'),
        width: double.infinity,
        height: 8 * scale,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.homeCreditProgressTrack),
            ),
            if (activeFraction > 0)
              FractionallySizedBox(
                widthFactor: activeFraction,
                child: const ColoredBox(
                  color: AppColors.homeCreditProgressActive,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoanTermStats extends StatelessWidget {
  const _LoanTermStats({required this.rows});

  final List<HomeCardLoanTermRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.length > 1 ? [rows.first, rows.last] : rows;
    return Row(
      key: const Key('home-loan-term-rows'),
      children: [
        for (var index = 0; index < visibleRows.length; index++) ...[
          if (index > 0) ...[
            SizedBox(width: context.r(35)),
            Container(
              width: context.r(1),
              height: context.r(26),
              color: AppColors.homeTermDivider,
            ),
            SizedBox(width: context.r(35)),
          ],
          Expanded(
            child: _LoanStat(
              label: '${visibleRows[index].period} ${visibleRows[index].label}'
                  .trim(),
              value: visibleRows[index].interestRate,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductIdentity extends StatelessWidget {
  const _ProductIdentity({
    required this.productName,
    required this.productLogo,
  });

  final String productName;
  final String productLogo;

  @override
  Widget build(BuildContext context) {
    final name = productName.trim();

    return SizedBox(
      key: const Key('home-product-identity'),
      width: double.infinity,
      height: context.r(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final nameMaxWidth = (constraints.maxWidth - context.r(32)).clamp(
            0.0,
            double.infinity,
          );

          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProductLogo(imageUrl: productLogo),
                if (name.isNotEmpty) ...[
                  SizedBox(width: context.r(8)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: nameMaxWidth),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: context.r(16),
                        fontWeight: FontWeight.w700,
                        height: 19 / 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductLogo extends StatelessWidget {
  const _ProductLogo({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.surface,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.homeCaption,
        size: context.r(16),
      ),
    );
    final url = imageUrl.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(2)),
      child: SizedBox(
        key: const Key('home-product-logo'),
        width: context.r(24),
        height: context.r(24),
        child: url.isEmpty
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.amount, required this.label});

  final String amount;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.homeAmount,
              fontSize: context.r(36),
              fontWeight: FontWeight.w700,
              height: 43 / 36,
            ),
          ),
        ),
        SizedBox(height: context.r(4)),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: context.r(12),
            height: 17 / 12,
          ),
        ),
      ],
    );
  }
}

class _LoanStat extends StatelessWidget {
  const _LoanStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.homeCaption,
            fontSize: context.r(10),
            height: 12 / 10,
          ),
        ),
        SizedBox(height: context.r(8)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.homeValue,
              fontSize: context.r(15),
              fontWeight: FontWeight.w700,
              height: 18 / 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-apply-button'),
      width: context.r(307),
      height: context.r(44),
      padding: EdgeInsets.all(context.r(4)),
      decoration: BoxDecoration(
        color: AppColors.homeApplyTrack,
        borderRadius: BorderRadius.circular(context.r(24)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(24)),
          gradient: const LinearGradient(
            colors: [
              AppColors.homeApplyButtonStart,
              AppColors.homeApplyButtonEnd,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.r(16)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.surface,
                  fontFamily: 'HiraMinProN-W6',
                  fontSize: context.r(18),
                  height: 27 / 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
