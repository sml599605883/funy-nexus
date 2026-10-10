import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';
import 'package:fund_nexus/features/product/state/credit_review_polling_coordinator.dart';

void main() {
  test('polls immediately and stops once the review is approved', () async {
    final gateway = _RecordingGateway([true]);
    final coordinator = CreditReviewPollingCoordinator(
      gateway: gateway,
      interval: const Duration(milliseconds: 5),
    );
    addTearDown(coordinator.stop);
    final approvals = <String>[];
    final subscription = coordinator.approvals.listen(approvals.add);
    addTearDown(subscription.cancel);

    coordinator.start('product-1');
    await _settle();

    expect(gateway.calls, 1);
    expect(coordinator.isRunning, isFalse);
    expect(approvals, ['product-1']);
  });

  test('keeps polling while the review is pending', () async {
    final gateway = _RecordingGateway([false, false, true]);
    final coordinator = CreditReviewPollingCoordinator(
      gateway: gateway,
      interval: const Duration(milliseconds: 5),
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-1');
    await _settle();

    expect(gateway.calls, greaterThanOrEqualTo(3));
    expect(coordinator.isRunning, isFalse);
  });

  test('retries after a failed request instead of stopping', () async {
    final gateway = _RecordingGateway([false, true], failFirst: true);
    final coordinator = CreditReviewPollingCoordinator(
      gateway: gateway,
      interval: const Duration(milliseconds: 5),
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-1');
    await _settle();

    expect(gateway.calls, greaterThanOrEqualTo(2));
    expect(coordinator.isRunning, isFalse);
  });

  test('keeps polling after the page detaches its handler', () async {
    final gateway = _RecordingGateway([false, true]);
    final coordinator = CreditReviewPollingCoordinator(
      gateway: gateway,
      interval: const Duration(milliseconds: 5),
    );
    addTearDown(coordinator.stop);
    final handled = <String>[];
    Future<void> handler(String productId) async => handled.add(productId);
    coordinator.attachForegroundHandler(handler);
    final approvals = <String>[];
    final subscription = coordinator.approvals.listen(approvals.add);
    addTearDown(subscription.cancel);

    coordinator.start('product-1');
    coordinator.detachForegroundHandler(handler);
    await _settle();

    expect(gateway.calls, greaterThanOrEqualTo(2));
    expect(handled, isEmpty);
    expect(approvals, ['product-1']);
  });

  test('hands the approval to the attached foreground handler', () async {
    final gateway = _RecordingGateway([true]);
    final coordinator = CreditReviewPollingCoordinator(
      gateway: gateway,
      interval: const Duration(milliseconds: 5),
    );
    addTearDown(coordinator.stop);
    final handled = <String>[];
    final approvals = <String>[];
    final subscription = coordinator.approvals.listen(approvals.add);
    addTearDown(subscription.cancel);
    coordinator.attachForegroundHandler((productId) async {
      handled.add(productId);
    });

    coordinator.start('product-1');
    await _settle();

    expect(handled, ['product-1']);
    expect(approvals, isEmpty);
  });

  test('stop cancels the loop', () async {
    final gateway = _RecordingGateway([false]);
    final coordinator = CreditReviewPollingCoordinator(
      gateway: gateway,
      interval: const Duration(milliseconds: 5),
    );
    addTearDown(coordinator.stop);

    coordinator.start('product-1');
    await _settle();
    coordinator.stop();
    final callsAfterStop = gateway.calls;
    await _settle();

    expect(coordinator.isRunning, isFalse);
    expect(gateway.calls, callsAfterStop);
  });

  test('a restart replaces the previous loop', () async {
    final gateway = _RecordingGateway([true]);
    final coordinator = CreditReviewPollingCoordinator(
      gateway: gateway,
      interval: const Duration(milliseconds: 5),
    );
    addTearDown(coordinator.stop);
    final handled = <String>[];
    coordinator.attachForegroundHandler((productId) async {
      handled.add(productId);
    });

    coordinator.start('product-1');
    coordinator.start('product-2');
    await _settle();

    expect(handled, ['product-2']);
  });
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 120));

class _RecordingGateway implements ProductGateway {
  _RecordingGateway(this.responses, {this.failFirst = false});

  final List<bool> responses;
  final bool failFirst;
  int calls = 0;

  @override
  Future<CreditReviewData> fetchCreditReview() async {
    final index = calls;
    calls += 1;
    if (failFirst && index == 0) {
      throw StateError('transient failure');
    }
    final boundedIndex = index.clamp(0, responses.length - 1);
    final approved = responses[boundedIndex];
    return CreditReviewData(isApproved: approved);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
