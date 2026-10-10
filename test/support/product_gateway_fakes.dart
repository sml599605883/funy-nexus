import 'dart:async';

import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

class StubProductGateway implements ProductGateway {
  @override
  Future<CreditReviewData> fetchCreditReview() =>
      Completer<CreditReviewData>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
