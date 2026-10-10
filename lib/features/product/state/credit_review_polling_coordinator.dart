import 'dart:async';

import 'package:fund_nexus/features/product/data/product_repository.dart';

typedef CreditReviewForegroundHandler = Future<void> Function(
  String productId,
);

class CreditReviewPollingCoordinator {
  CreditReviewPollingCoordinator({
    required ProductGateway gateway,
    this.interval = const Duration(seconds: 10),
  }) : _gateway = gateway;

  final ProductGateway _gateway;
  final Duration interval;
  final StreamController<String> _approvals =
      StreamController<String>.broadcast();

  Timer? _timer;
  String _productId = '';
  bool _requestInFlight = false;
  bool _running = false;
  int _generation = 0;
  CreditReviewForegroundHandler? _foregroundHandler;

  bool get isRunning => _running;

  String get productId => _productId;

  Stream<String> get approvals => _approvals.stream;

  void start(String productId) {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) return;
    _generation += 1;
    final generation = _generation;
    _productId = normalizedProductId;
    _running = true;
    _requestInFlight = false;
    _timer?.cancel();
    _timer = Timer(Duration.zero, () => _poll(generation));
  }

  void stop() {
    _generation += 1;
    _timer?.cancel();
    _timer = null;
    _running = false;
    _requestInFlight = false;
  }

  void attachForegroundHandler(CreditReviewForegroundHandler handler) {
    _foregroundHandler = handler;
  }

  void detachForegroundHandler(CreditReviewForegroundHandler handler) {
    if (identical(_foregroundHandler, handler)) {
      _foregroundHandler = null;
    }
  }

  Future<void> _poll(int generation) async {
    if (!_isActive(generation)) return;
    if (_requestInFlight) {
      _scheduleRetry(generation);
      return;
    }
    _requestInFlight = true;
    late final bool isApproved;
    try {
      isApproved = (await _gateway.fetchCreditReview()).isApproved;
    } catch (_) {
      _scheduleRetry(generation);
      return;
    }
    if (!_isActive(generation)) return;
    if (isApproved) {
      await _complete(generation);
      return;
    }
    _scheduleRetry(generation);
  }

  Future<void> _complete(int generation) async {
    if (!_isActive(generation)) return;
    final handler = _foregroundHandler;
    final productId = _productId;
    stop();
    if (handler == null) {
      _approvals.add(productId);
      return;
    }
    try {
      await handler(productId);
    } catch (_) {
      // The foreground flow reports its own failures to the user.
    }
  }

  void _scheduleRetry(int generation) {
    if (!_isActive(generation)) return;
    _requestInFlight = false;
    _timer?.cancel();
    _timer = Timer(interval, () => _poll(generation));
  }

  bool _isActive(int generation) => _running && generation == _generation;
}
