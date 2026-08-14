import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';
import 'package:fund_nexus/features/home/widgets/loan_hero.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    required this.data,
    this.onRefresh,
    this.onApply,
    super.key,
  });

  final HomeData data;
  final Future<void> Function()? onRefresh;
  final ValueChanged<HomeCardData>? onApply;

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
              onApply: () => onApply?.call(card),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.r(16)),
            child: _PromoBanner(banners: data.promoBanners),
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

class _PromoBanner extends StatefulWidget {
  const _PromoBanner({required this.banners});

  final List<HomeBannerData> banners;

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  static const _autoPlayInterval = Duration(seconds: 3);
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  List<HomeBannerData> get _banners => widget.banners;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _configureAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _PromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != _banners.length) {
      _currentPage = 0;
      _configureAutoPlay();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _configureAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_banners.length < 2) return;
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(8)),
      child: SizedBox(
        key: const Key('home-promo-banner'),
        width: context.r(343),
        height: context.r(120),
        child: Stack(
          children: [
            Positioned.fill(
              child: _banners.isEmpty
                  ? const _PromoBannerPage()
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _banners.length,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      itemBuilder: (_, index) => _PromoBannerPage(
                        key: Key('home-promo-banner-image-$index'),
                        imageUrl: _banners[index].imageUrl,
                      ),
                    ),
            ),
            if (_banners.length > 1)
              Positioned(
                bottom: context.r(8),
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _banners.length,
                    (index) => Container(
                      width: context.r(6),
                      height: context.r(6),
                      margin: EdgeInsets.symmetric(horizontal: context.r(3)),
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? AppColors.surface
                            : AppColors.surface.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
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

class _PromoBannerPage extends StatelessWidget {
  const _PromoBannerPage({super.key, this.imageUrl = ''});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(child: _PromoBannerImage(imageUrl: imageUrl)),
        if (!hasImage)
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
    );
  }
}

class _PromoBannerImage extends StatelessWidget {
  const _PromoBannerImage({this.imageUrl = ''});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallbackImage = Image.asset(
      AppAssets.homePromoBanner,
      fit: BoxFit.cover,
    );
    final resolvedImageUrl = imageUrl.trim();
    if (resolvedImageUrl.isEmpty) return fallbackImage;
    return Image.network(
      resolvedImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallbackImage,
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
