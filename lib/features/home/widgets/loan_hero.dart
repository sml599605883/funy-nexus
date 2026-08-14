import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';

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
          height: context.r(383),
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
                child: Row(
                  children: [
                    Expanded(
                      child: _LoanStat(label: loanTermLabel, value: loanTerm),
                    ),
                    SizedBox(width: context.r(35)),
                    Expanded(
                      child: _LoanStat(
                        label: interestRateLabel,
                        value: interestRate,
                      ),
                    ),
                  ],
                ),
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
            ],
          ),
        ),
      ),
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
