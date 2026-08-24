import 'package:flutter/material.dart';
import 'package:fund_nexus/core/push/push_navigation_helper.dart';

/// 推送消息测试页面
/// 用于手动测试推送消息的路由跳转功能
class PushTestPage extends StatelessWidget {
  const PushTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推送消息测试'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '点击下方按钮测试推送消息路由',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _TestButton(
            label: '测试首页 (Prismatic)',
            url: 'ph://fund-nexus/ios/Prismatic',
          ),
          _TestButton(
            label: '测试首页 (Home)',
            url: 'ph://fund-nexus/ios/Home',
          ),
          _TestButton(
            label: '测试 Mine',
            url: 'ph://fund-nexus/ios/Mine',
          ),
          _TestButton(
            label: '测试产品详情',
            url: 'ph://fund-nexus/ios/Loan?productId=123',
          ),
          _TestButton(
            label: '测试订单',
            url: 'ph://fund-nexus/ios/Order?status=4',
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            '调试说明：',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '1. 点击按钮后，查看日志输出\n'
            '2. 应该看到 [PushNavigation] 开头的日志\n'
            '3. 如果没有日志，说明 PushNavigationHelper 未配置\n'
            '4. 如果有日志但没有跳转，需要实现具体导航逻辑',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({
    required this.label,
    required this.url,
  });

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          debugPrint('=== 测试按钮点击 ===');
          debugPrint('URL: $url');
          await PushNavigationHelper.navigateToTarget(url);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label),
      ),
    );
  }
}
