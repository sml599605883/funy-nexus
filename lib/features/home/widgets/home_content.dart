import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/widgets/loan_hero.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({required this.data, this.onRefresh, super.key});

  final HomeData data;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final card = data.primaryCard;
    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      child: Column(
        children: [
          const _HomeHeader(),
          if (card != null)
            LoanHero(
              productName: card.productName,
              productLogo: card.productLogo,
              amount: card.amount,
              amountLabel: card.amountLabel,
              loanTerm: card.loanTerm,
              loanTermLabel: card.loanTermLabel,
              interestRate: card.interestRate,
              interestRateLabel: card.interestRateLabel,
              description: card.description,
              actionText: card.actionText,
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.r(16)),
            child: _PromoBanner(banner: data.banner),
          ),
          SizedBox(height: context.r(133)),
        ],
      ),
    );

    return ColoredBox(
      color: AppColors.homeBackground,
      child: onRefresh == null
          ? scrollView
          : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.banner});

  final HomeBannerData? banner;

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner?.imageUrl.trim() ?? '';
    final fallbackImage = Image.asset(
      AppAssets.homePromoBanner,
      fit: BoxFit.cover,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(8)),
      child: SizedBox(
        key: const Key('home-promo-banner'),
        width: context.r(343),
        height: context.r(120),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl.isEmpty
                  ? fallbackImage
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallbackImage,
                    ),
            ),
            if (imageUrl.isEmpty)
              Positioned(
                left: context.r(11),
                top: context.r(28),
                child: SizedBox(
                  width: context.r(197),
                  height: context.r(72),
                  child: Text(
                    'Effortless borrowing here, a worry - free life so near!',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontFamily: 'InaiMathi',
                      fontSize: context.r(22),
                      fontWeight: FontWeight.w700,
                      height: 24 / 22,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-header'),
      width: double.infinity,
      height: context.r(88),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.homeHeaderStart, AppColors.homeHeaderEnd],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: context.r(50),
            child: Text(
              'Maya Agad',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: context.r(17),
                fontWeight: FontWeight.w600,
                height: 24 / 17,
              ),
            ),
          ),
          Positioned(
            right: context.r(18),
            top: context.r(51),
            child: Image.asset(
              AppAssets.homeChatIcon,
              key: const Key('home-chat-icon'),
              width: context.r(20),
              height: context.r(18),
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
