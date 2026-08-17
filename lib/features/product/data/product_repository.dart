import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

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

  Future<IdentityRecognitionData> uploadIdentityDocument({
    required String filePath,
    required String identityType,
    required bool wasCapturedWithCamera,
  });

  Future<void> saveIdentityDocument({
    required String fullName,
    required String idNumber,
    required String dateOfBirth,
    required String identityType,
  });
}

abstract interface class FaceVerificationGateway {
  Future<FaceLivenessToken> fetchFaceLivenessToken({
    required String orderNumber,
  });

  Future<void> uploadFaceLiveness({
    required String filePath,
    required FaceLivenessToken token,
    required String livenessId,
  });
}

abstract interface class PersonalInformationGateway {
  Future<PersonalInformationData> fetchPersonalInformation(String productId);

  Future<List<PersonalAddressNode>> fetchPersonalInformationAddresses();

  Future<void> savePersonalInformation({
    required String productId,
    required Map<String, String> fields,
  });
}

class ProductRepository
    implements
        ProductGateway,
        FaceVerificationGateway,
        PersonalInformationGateway {
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
  Future<IdentityRecognitionData> uploadIdentityDocument({
    required String filePath,
    required String identityType,
    required bool wasCapturedWithCamera,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'Identity image is missing',
      );
    }
    final formData = FormData.fromMap({
      'etherifying': '11',
      'tanners': wasCapturedWithCamera ? '2' : '1',
      'symptoms': identityType,
      'gibbon': '',
      'mosque': '',
      'wealthily': '',
      'piroplasma': '',
      'attach': await MultipartFile.fromFile(file.path),
    });
    final response = await apiClient.postMultipart<IdentityRecognitionData>(
      '/viler/argots',
      data: formData,
      decode: IdentityRecognitionData.fromJson,
    );
    return response.data;
  }

  @override
  Future<void> saveIdentityDocument({
    required String fullName,
    required String idNumber,
    required String dateOfBirth,
    required String identityType,
  }) async {
    await apiClient.post<void>(
      '/viler/knosp',
      data: {
        'palisades': dateOfBirth,
        'outdueled': idNumber,
        'emit': fullName,
        'etherifying': '11',
        'symptoms': identityType,
        'choppiest': '11',
      },
      decode: (_) {},
    );
  }

  @override
  Future<PersonalInformationData> fetchPersonalInformation(
    String productId,
  ) async {
    final response = await apiClient.post<PersonalInformationData>(
      '/viler/chippered',
      data: {'modernised': productId, 'movieola': ApiSignature.randomDigits(6)},
      decode: PersonalInformationData.fromJson,
    );
    return response.data;
  }

  @override
  Future<List<PersonalAddressNode>> fetchPersonalInformationAddresses() async {
    final response = await apiClient.get<List<PersonalAddressNode>>(
      '/viler/closets',
      decode: PersonalAddressNode.parseList,
    );
    return response.data;
  }

  @override
  Future<void> savePersonalInformation({
    required String productId,
    required Map<String, String> fields,
  }) async {
    await apiClient.post<void>(
      '/viler/requiems',
      data: {
        ...fields,
        'modernised': productId,
        'chapels': ApiSignature.randomDigits(6),
        'massiness': ApiSignature.randomDigits(6),
      },
      decode: (_) {},
    );
  }

  @override
  Future<FaceLivenessToken> fetchFaceLivenessToken({
    required String orderNumber,
  }) async {
    final response = await apiClient.post<FaceLivenessToken>(
      '/viler/irenically',
      data: {
        'clipsheet': orderNumber,
        'etherifying': '0',
        'colombard': ApiSignature.randomDigits(6),
        'libidinal': ApiSignature.randomDigits(6),
      },
      decode: FaceLivenessToken.fromJson,
    );
    return response.data;
  }

  @override
  Future<void> uploadFaceLiveness({
    required String filePath,
    required FaceLivenessToken token,
    required String livenessId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError.value(filePath, 'filePath', 'Face image is missing');
    }
    final formData = FormData.fromMap({
      'etherifying': '10',
      'tanners': '1',
      'symptoms': '',
      'gibbon': livenessId,
      'mosque': token.license,
      'wealthily': '${token.livenessType}',
      'attach': await MultipartFile.fromFile(file.path),
    });
    await apiClient.postMultipart<void>(
      '/viler/argots',
      data: formData,
      decode: (_) {},
    );
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
