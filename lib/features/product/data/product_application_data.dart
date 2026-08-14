import 'package:fund_nexus/core/json/json.dart';

Uri? productWebUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.host.isEmpty) return null;
  return uri.scheme == 'http' || uri.scheme == 'https' ? uri : null;
}

enum ProductAdmissionDisposition { detail, web, creditReview, unavailable }

class ProductAdmissionData {
  const ProductAdmissionData({
    required this.statusCode,
    required this.message,
    required this.target,
  });

  factory ProductAdmissionData.fromJson(Object? data) {
    final json = Json(data);
    return ProductAdmissionData(
      statusCode: json['trokes'].numValue.toInt(),
      message: json['hygieists'].stringValue.trim(),
      target: json['redepositing'].stringValue.trim(),
    );
  }

  final int statusCode;
  final String message;
  final String target;

  ProductAdmissionDisposition get disposition {
    if (_isCreditReviewTarget(target)) {
      return ProductAdmissionDisposition.creditReview;
    }
    if (productWebUri(target) != null) {
      return ProductAdmissionDisposition.web;
    }
    if (statusCode == 200) return ProductAdmissionDisposition.detail;
    return ProductAdmissionDisposition.unavailable;
  }

  static bool _isCreditReviewTarget(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'gold' &&
        uri.host == 'pocket' &&
        uri.pathSegments.length == 1 &&
        uri.pathSegments.single == 'recredit';
  }
}

class ProductDetailData {
  const ProductDetailData({
    required this.statusCode,
    required this.product,
    required this.nextStep,
    this.certificationCopy = const ProductCertificationCopy(),
  });

  factory ProductDetailData.fromJson(Object? data) {
    final json = Json(data);
    return ProductDetailData(
      statusCode: json['trokes'].numValue.toInt(),
      product: ProductDetailProduct.fromJson(json['supramolecular']),
      nextStep: ProductDetailNextStep.fromJson(json['metheglins']),
      certificationCopy: ProductCertificationCopy.fromJson(json['rubicund']),
    );
  }

  final int statusCode;
  final ProductDetailProduct product;
  final ProductDetailNextStep nextStep;
  final ProductCertificationCopy certificationCopy;
}

class ProductCertificationCopy {
  const ProductCertificationCopy({this.identityUploadGuidance = ''});

  factory ProductCertificationCopy.fromJson(Json json) {
    return ProductCertificationCopy(
      identityUploadGuidance: json['qintar'].stringValue.trim(),
    );
  }

  final String identityUploadGuidance;
}

class ProductDetailProduct {
  const ProductDetailProduct({
    required this.productId,
    required this.orderNumber,
    required this.amount,
    required this.loanTerm,
    required this.termType,
  });

  factory ProductDetailProduct.fromJson(Json json) {
    final terms = json['salvationist'].listValue;
    return ProductDetailProduct(
      productId: json['ecclesia'].stringValue.trim(),
      orderNumber: json['readjusts'].stringValue.trim(),
      amount: json['breaststrokers'].stringValue.trim(),
      loanTerm: terms.isEmpty ? '' : terms.first.stringValue.trim(),
      termType: json['nominees'].stringValue.trim(),
    );
  }

  final String productId;
  final String orderNumber;
  final String amount;
  final String loanTerm;
  final String termType;
}

class ProductDetailNextStep {
  const ProductDetailNextStep({required this.type, required this.title});

  factory ProductDetailNextStep.fromJson(Json json) {
    return ProductDetailNextStep(
      type: json['gabbler'].stringValue.trim(),
      title: json['culinarians'].stringValue.trim(),
    );
  }

  final String type;
  final String title;
}

class CreditReviewData {
  const CreditReviewData({required this.isApproved});

  factory CreditReviewData.fromJson(Object? data) {
    return CreditReviewData(
      isApproved: Json(data)['trokes'].numValue.toInt() == 1,
    );
  }

  final bool isApproved;
}

class LoanDestinationData {
  const LoanDestinationData({required this.target});

  factory LoanDestinationData.fromJson(Object? data) {
    return LoanDestinationData(
      target: Json(data)['redepositing'].stringValue.trim(),
    );
  }

  final String target;
}

class ProductIdentityData {
  const ProductIdentityData({required this.groups});

  factory ProductIdentityData.fromJson(Object? data) {
    final seen = <String>{};
    final groups = <List<String>>[];
    for (final group in Json(data)['polycythemic'].listValue) {
      final values = <String>[];
      for (final item in group.listValue) {
        final value = item.stringValue.trim();
        if (value.isNotEmpty && seen.add(value)) values.add(value);
      }
      if (values.isNotEmpty) groups.add(values);
    }
    return ProductIdentityData(groups: groups);
  }

  final List<List<String>> groups;

  List<String> get recommendedTypes =>
      groups.isEmpty ? const <String>[] : groups.first;

  List<String> get otherTypes =>
      groups.skip(1).expand((group) => group).toList(growable: false);
}
