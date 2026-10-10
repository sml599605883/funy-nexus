import 'package:flutter/material.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/features/mine/widgets/mine_menu_item.dart';
import 'package:fund_nexus/features/mine/widgets/mine_section_title.dart';

class MineBody extends StatelessWidget {
  const MineBody({
    required this.onAccountTap,
    this.onCustomerService,
    this.onPrivacyPolicy,
    this.onWebsiteTap,
    this.appVersion,
    super.key,
  });

  final VoidCallback onAccountTap;
  final VoidCallback? onCustomerService;
  final VoidCallback? onPrivacyPolicy;
  final VoidCallback? onWebsiteTap;
  final String? appVersion;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(12)),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.r(16),
          context.r(100),
          context.r(16),
          context.r(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MineSectionTitle(label: 'Customer Service'),
            SizedBox(height: context.r(12)),
            MineMenuItem(
              key: const Key('mine-customer-service'),
              iconAsset: AppAssets.mineCustomerService,
              label: 'Smart customer service',
              onTap: onCustomerService,
            ),
            SizedBox(height: context.r(16)),
            const MineSectionTitle(label: 'About Us'),
            SizedBox(height: context.r(12)),
            MineMenuItem(
              key: const Key('mine-website'),
              iconAsset: AppAssets.mineWebsite,
              label: 'Website',
              onTap: onWebsiteTap,
            ),
            SizedBox(height: context.r(8)),
            MineMenuItem(
              key: const Key('mine-app-version'),
              iconAsset: AppAssets.mineAppVersion,
              label: 'APP Version',
              trailingLabel: appVersion == null ? null : 'v$appVersion',
              showChevron: false,
            ),
            SizedBox(height: context.r(8)),
            MineMenuItem(
              key: Key('mine-privacy-agreement'),
              iconAsset: AppAssets.minePrivacyAgreement,
              label: 'Privacy Agreement',
              onTap: onPrivacyPolicy,
            ),
            SizedBox(height: context.r(8)),
            MineMenuItem(
              key: const Key('mine-account'),
              iconAsset: AppAssets.mineAccount,
              label: 'Account',
              onTap: onAccountTap,
            ),
          ],
        ),
      ),
    );
  }
}
