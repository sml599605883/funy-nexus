import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';
import 'package:fund_nexus/features/product/data/bind_card_data.dart';
import 'package:fund_nexus/features/product/data/emergency_contact_data.dart';
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
    String type = '0',
  });

  Future<void> uploadFaceLiveness({
    required String filePath,
    required FaceLivenessToken token,
    required String livenessId,
  });
}

abstract interface class PersonalInformationGateway {
  Future<PersonalInformationData> fetchPersonalInformation(String productId);

  Future<PersonalInformationData> fetchWorkInformation(String productId);

  Future<List<PersonalAddressNode>> fetchPersonalInformationAddresses();

  Future<void> savePersonalInformation({
    required String productId,
    required Map<String, String> fields,
  });

  Future<void> saveWorkInformation({
    required String productId,
    required Map<String, String> fields,
  });
}

abstract interface class EmergencyContactGateway {
  Future<EmergencyContactData> fetchEmergencyContacts(String productId);

  Future<void> saveEmergencyContacts({
    required String productId,
    required List<Map<String, String>> contacts,
  });
}

abstract interface class BindCardGateway {
  Future<BindCardData> fetchBindCard(String productId);

  Future<BindCardSubmitResult> submitBindCard({
    required String productId,
    required String cardType,
    required Map<String, String> fields,
    required BindCardLivenessPayload liveness,
  });
}

class ProductRepository
    implements
        ProductGateway,
        FaceVerificationGateway,
        PersonalInformationGateway,
        EmergencyContactGateway,
        BindCardGateway {
  ProductRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<ProductAdmissionData> requestAdmission(String productId) async {
    final response = await apiClient.post<ProductAdmissionData>(
      '/viler/pelvis',
      data: {
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
  Future<PersonalInformationData> fetchWorkInformation(String productId) async {
    final response = await apiClient.get<PersonalInformationData>(
      '/viler/externalising',
      queryParameters: {
        'modernised': productId,
        'movieola': ApiSignature.randomDigits(6),
      },
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
  Future<void> saveWorkInformation({
    required String productId,
    required Map<String, String> fields,
  }) async {
    await apiClient.post<void>(
      '/viler/semihobos',
      data: {
        ...fields,
        'modernised': productId,
        'conducted': ApiSignature.randomDigits(6),
        'settlors': ApiSignature.randomDigits(6),
        'confusional': ApiSignature.randomDigits(6),
      },
      decode: (_) {},
    );
  }

  @override
  Future<EmergencyContactData> fetchEmergencyContacts(String productId) async {
    final response = await apiClient.get<EmergencyContactData>(
      '/viler/etherifying',
      queryParameters: {
        'modernised': productId,
        'overshoot': ApiSignature.randomDigits(6),
      },
      decode: EmergencyContactData.fromJson,
    );
    return response.data;
  }

  @override
  Future<void> saveEmergencyContacts({
    required String productId,
    required List<Map<String, String>> contacts,
  }) async {
    await apiClient.post<void>(
      '/viler/mycetozoan',
      data: {
        'modernised': productId,
        'foresight': jsonEncode(contacts),
        'meditations': ApiSignature.randomDigits(6),
      },
      decode: (_) {},
    );
  }

  @override
  Future<BindCardData> fetchBindCard(String productId) async {
    final response = await apiClient.get<BindCardData>(
      '/viler/ecclesia',
      queryParameters: {
        'modernised': productId,
        'grandstanding': ApiSignature.randomDigits(6),
        'unequaled': ApiSignature.randomDigits(6),
      },
      decode: BindCardData.fromJson,
    );
    return response.data;
  }

  @override
  Future<BindCardSubmitResult> submitBindCard({
    required String productId,
    required String cardType,
    required Map<String, String> fields,
    required BindCardLivenessPayload liveness,
  }) async {
    final response = await apiClient.post<BindCardSubmitResult>(
      '/viler/redepositing',
      data: {
        'modernised': productId,
        'symptoms': cardType,
        ...fields,
        'myxomatoses': ApiSignature.randomDigits(7),
        'wealthily': liveness.type,
        'gibbon': liveness.livenessId,
        'mosque': liveness.license,
      },
      additionalSuccessCodes: const {'20000'},
      decode: (data) => BindCardSubmitResult.fromJson(data, '0'),
    );
    return BindCardSubmitResult.fromJson(response.data, response.code);
  }

  @override
  Future<FaceLivenessToken> fetchFaceLivenessToken({
    required String orderNumber,
    String type = '0',
  }) async {
    final response = await apiClient.post<FaceLivenessToken>(
      '/viler/irenically',
      data: {
        'clipsheet': orderNumber,
        'etherifying': type,
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
