import 'dart:async';
import 'report_service.dart';

class RiskReportScene {
  const RiskReportScene._();

  static void report(
    ReportService? service, {
    required String productId,
    required String sceneType,
    String orderNo = '',
    int? startedAtSeconds,
  }) {
    if (service == null) return;
    unawaited(
      service.reportRisk(
        productId: productId,
        sceneType: sceneType,
        orderNo: orderNo,
        startTimeSeconds: startedAtSeconds ?? ReportService.nowSeconds(),
      ),
    );
  }
}
