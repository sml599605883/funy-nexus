import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';

abstract interface class ProductGateway {
  Future<ProductAdmissionData> requestAdmission(String productId);

  Future<ProductDetailData> fetchProductDetail(String productId);

  Future<ProductIdentityData> fetchIdentityOptions(String productId);

  Future<CreditReviewData> fetchCreditReview();

  Future<LoanDestinationData> fetchLoanDestination({
    required String orderNumber,
    required String amount,
    required String loanTerm,
    required String termType,
  });
}

class ProductRepository implements ProductGateway {
  ProductRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<ProductAdmissionData> requestAdmission(String productId) async {
    final response = await apiClient.post<ProductAdmissionData>(
      '/viler/pelvis',
      data: {
        'metageneses': '1001',
        'servitude': '1000',
        'explantation': '1000',
        'modernised': productId,
        'nonpermissive': '0',
        'disaggregate': ApiSignature.randomDigits(6),
        'coccyx': ApiSignature.randomDigits(6),
      },
      decode: ProductAdmissionData.fromJson,
    );
    return response.data;
  }

  @override
  Future<ProductDetailData> fetchProductDetail(String productId) async {
    final response = await apiClient.post<ProductDetailData>(
      '/viler/commenting',
      data: {
        'modernised': productId,
        'xerophily': ApiSignature.randomDigits(6),
        'tragedienne': ApiSignature.randomDigits(6),
        'impowering': ApiSignature.randomDigits(6),
      },
      decode: ProductDetailData.fromJson,
    );
    return response.data;
  }

  @override
  Future<ProductIdentityData> fetchIdentityOptions(String productId) async {
    final response = await apiClient.get<ProductIdentityData>(
      '/viler/invital',
      queryParameters: {
        'modernised': productId,
        'pacification': ApiSignature.randomDigits(6),
      },
      decode: ProductIdentityData.fromJson,
    );
    return response.data;
  }

  @override
  Future<CreditReviewData> fetchCreditReview() async {
    final response = await apiClient.get<CreditReviewData>(
      '/viler/pepperboxes',
      queryParameters: {'underheat': ApiSignature.randomDigits(6)},
      decode: CreditReviewData.fromJson,
    );
    return response.data;
  }

  @override
  Future<LoanDestinationData> fetchLoanDestination({
    required String orderNumber,
    required String amount,
    required String loanTerm,
    required String termType,
  }) async {
    final response = await apiClient.post<LoanDestinationData>(
      '/viler/remediation',
      data: {
        'clipsheet': orderNumber,
        'breaststrokers': amount,
        'germicides': loanTerm,
        'nominees': termType,
        'substantive': ApiSignature.randomDigits(6),
        'inquiry': ApiSignature.randomDigits(6),
        'shocker': ApiSignature.randomDigits(6),
        'parbake': ApiSignature.randomDigits(6),
      },
      decode: LoanDestinationData.fromJson,
    );
    return response.data;
  }
}
