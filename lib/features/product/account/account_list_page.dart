import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/app/resources/app_assets.dart';
import 'package:fund_nexus/app/theme/app_colors.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_exception.dart';
import 'package:fund_nexus/features/product/account/account_list_data.dart';
import 'package:fund_nexus/features/product/certification/bind_card_page.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

class AccountListPage extends StatefulWidget {
  const AccountListPage({
    required this.productId,
    required this.orderNumber,
    this.onCompleted,
    super.key,
  });
  final String productId;
  final String orderNumber;
  final Future<void> Function(String url)? onCompleted;

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  List<AccountListSection> _sections = const [];
  AccountListItem? _selected;
  String _error = '';
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accountListBackgroundEnd,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: context.r(60),
              child: NavigationToolbar(
                leading: IconButton(
                  key: const Key('accountListBack'),
                  icon: Icon(Icons.arrow_back_ios_new, size: context.r(18)),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                middle: Text(
                  'Loan Confirmation',
                  style: TextStyle(
                    fontSize: context.r(17),
                    fontWeight: FontWeight.w600,
                    height: 24 / 17,
                  ),
                ),
              ),
            ),
            Expanded(child: _content()),
          ],
        ),
      ),
      bottomNavigationBar: _bottomActions(),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('accountListLoading')),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error),
            SizedBox(height: context.r(16)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accountListAccent,
            AppColors.accountListBackgroundEnd,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.r(16)),
        child: Column(
          key: const Key('accountListContent'),
          children: [
            for (final section in _sections)
              _AccountSection(
                section: section,
                selected: _selected,
                onSelected: (item) => setState(() => _selected = item),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions() => SafeArea(
    top: false,
    minimum: EdgeInsets.only(bottom: context.r(8)),
    child: Container(
      padding: EdgeInsets.fromLTRB(
        context.r(16),
        context.r(16),
        context.r(16),
        context.r(8),
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.accountListFooterShadow,
            offset: Offset(0, -5),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AddMethod(onTap: _addMethod),
          SizedBox(height: context.r(16)),
          SizedBox(
            width: double.infinity,
            height: context.r(52),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.loginButtonStart,
                    AppColors.loginButtonEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(context.r(26)),
              ),
              child: TextButton(
                key: const Key('accountListConfirm'),
                onPressed: _selected == null || _submitting ? null : _confirm,
                child: Text(
                  _submitting ? 'Loading...' : 'Confirm',
                  style: TextStyle(
                    color: AppColors.accountListConfirmText,
                    fontSize: context.r(16),
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _load() async {
    final apiClient = context.read<ApiClient>();
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await apiClient.fetchProgressAccounts(
        productId: widget.productId,
      );
      final sections = parseAccountListSections(response.data);
      AccountListItem? main;
      for (final section in sections) {
        for (final item in section.accounts) {
          if (item.isMain) {
            main = item;
            break;
          }
        }
        if (main != null) break;
      }
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _selected = main;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error is ApiException ? error.message : error.toString();
        });
      }
    }
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null || _submitting) return;
    final apiClient = context.read<ApiClient>();
    setState(() => _submitting = true);
    try {
      await EasyLoading.show(status: 'Loading...');
      final response = await apiClient.changeProgressAccount(
        orderNumber: widget.orderNumber,
        bindId: selected.bindId,
      );
      final url = response.data['topical'].stringValue.trim();
      final uri = ProductWebPage.validUri(url);
      if (uri == null) {
        throw const ApiException(
          type: ApiFailureType.business,
          message: 'Invalid account change result url',
        );
      }
      await EasyLoading.dismiss(animation: false);
      if (mounted) {
        final onCompleted = widget.onCompleted;
        if (onCompleted != null) {
          await onCompleted(uri.toString());
        } else {
          await Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(
              builder: (_) => ProductWebPage(url: uri.toString()),
            ),
          );
        }
      }
    } catch (error) {
      await EasyLoading.dismiss(animation: false);
      if (mounted) {
        await EasyLoading.showError(
          error is ApiException ? error.message : 'Unable to change account.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addMethod() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BindCardPage(
          productId: widget.productId,
          orderNumber: widget.orderNumber,
          isAccountChange: true,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final uri = ProductWebPage.validUri(result);
    if (uri == null) return;
    final onCompleted = widget.onCompleted;
    if (onCompleted != null) {
      await onCompleted(uri.toString());
      return;
    }
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => ProductWebPage(url: uri.toString())),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.section,
    required this.selected,
    required this.onSelected,
  });
  final AccountListSection section;
  final AccountListItem? selected;
  final ValueChanged<AccountListItem> onSelected;

  @override
  Widget build(BuildContext context) {
    final cardHeight =
        context.r(24) +
        section.accounts.fold<double>(
          0,
          (height, account) =>
              height + context.r(account.isUnderMaintenance ? 154 : 110),
        ) +
        (section.accounts.length - 1) * context.r(8);
    return Padding(
      padding: EdgeInsets.only(bottom: context.r(16)),
      child: Column(
        children: [
          SizedBox(
            height: context.r(67),
            child: _SectionTitle(
              key: Key('accountListSectionHeader-${section.type}'),
              title: section.title,
            ),
          ),
          SizedBox(
            height: cardHeight - context.r(24),
            child: OverflowBox(
              minHeight: cardHeight,
              maxHeight: cardHeight,
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, -context.r(24)),
                child: _OuterCard(
                  key: Key('accountListSectionCard-${section.type}'),
                  section: section,
                  selected: selected,
                  onSelected: onSelected,
                  height: cardHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, super.key});
  final String title;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          AppColors.accountListCard,
          AppColors.accountListBackgroundStart,
        ],
      ),
      borderRadius: BorderRadius.circular(context.r(12)),
    ),
    child: Transform.translate(
      offset: Offset(0, -context.r(8)),
      child: Row(
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
      ),
    ),
  );
}

class _OuterCard extends StatelessWidget {
  const _OuterCard({
    required this.section,
    required this.selected,
    required this.onSelected,
    required this.height,
    super.key,
  });
  final AccountListSection section;
  final AccountListItem? selected;
  final ValueChanged<AccountListItem> onSelected;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: EdgeInsets.all(context.r(12)),
    decoration: BoxDecoration(
      color: AppColors.accountListCard,
      borderRadius: BorderRadius.circular(context.r(12)),
    ),
    child: Column(
      children: [
        for (var i = 0; i < section.accounts.length; i++) ...[
          _AccountItem(
            section: section,
            account: section.accounts[i],
            selected: selected?.bindId == section.accounts[i].bindId,
            onTap: () => onSelected(section.accounts[i]),
          ),
          if (i != section.accounts.length - 1) SizedBox(height: context.r(8)),
        ],
      ],
    ),
  );
}

class _AccountItem extends StatelessWidget {
  const _AccountItem({
    required this.section,
    required this.account,
    required this.selected,
    required this.onTap,
  });
  final AccountListSection section;
  final AccountListItem account;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('accountListItem-${account.bindId}'),
      borderRadius: BorderRadius.circular(context.r(12)),
      onTap: onTap,
      child: Container(
        height: context.r(account.isUnderMaintenance ? 154 : 110),
        padding: EdgeInsets.fromLTRB(
          context.r(12),
          context.r(17),
          context.r(12),
          context.r(10),
        ),
        decoration: BoxDecoration(
          color: AppColors.accountListItem,
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (account.logoUrl.isNotEmpty) ...[
                  _Logo(url: account.logoUrl),
                  SizedBox(width: context.r(8)),
                ],
                Expanded(
                  child: Text(
                    account.providerName,
                    style: TextStyle(
                      fontSize: context.r(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Image.asset(
                  selected
                      ? AppAssets.accountOptionSelected
                      : AppAssets.accountOptionUnselected,
                  key: Key('accountListSelection-${account.bindId}'),
                  width: context.r(22),
                  height: context.r(22),
                ),
              ],
            ),
            if (account.isUnderMaintenance)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: context.r(5)),
                  child: Text(
                    'The bank is under maintenance. Loans may be delayed. Please wait or choose another option',
                    style: TextStyle(
                      color: AppColors.accountListMaintenance,
                      fontSize: context.r(11),
                      height: 16 / 11,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              height: context.r(1),
              width: double.infinity,
              child: CustomPaint(
                painter: _AccountDashedDividerPainter(
                  color: AppColors.accountListDivider,
                  dashWidth: context.r(8),
                  dashGap: context.r(8),
                ),
              ),
            ),
            SizedBox(height: context.r(17)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Receipt Account',
                  style: TextStyle(
                    color: AppColors.accountListLabel,
                    fontSize: context.r(14),
                    height: 18 / 14,
                  ),
                ),
                Text(
                  account.accountValue,
                  style: TextStyle(
                    fontSize: context.r(14),
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(context.r(4)),
    child: Image.network(
      url,
      width: context.r(23),
      height: context.r(23),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          SizedBox(width: context.r(23), height: context.r(23)),
    ),
  );
}

class _AccountDashedDividerPainter extends CustomPainter {
  const _AccountDashedDividerPainter({
    required this.color,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
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
  bool shouldRepaint(_AccountDashedDividerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap;
}

class _AddMethod extends StatelessWidget {
  const _AddMethod({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('accountAddPaymentMethod'),
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: context.r(48),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.accountAddMethodBorder),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.accountAddIcon,
            width: context.r(12),
            height: context.r(12),
          ),
          SizedBox(width: context.r(7)),
          Text(
            'Add other payment methods',
            style: TextStyle(fontSize: context.r(14), height: 18 / 14),
          ),
        ],
      ),
    ),
  );
}
