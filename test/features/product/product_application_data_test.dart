import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';

void main() {
  test('classifies documented admission outcomes', () {
    expect(
      ProductAdmissionData.fromJson({
        'trokes': 200,
        'redepositing': '',
      }).disposition,
      ProductAdmissionDisposition.detail,
    );
    expect(
      ProductAdmissionData.fromJson({
        'trokes': 302,
        'redepositing': 'https://web.example.com/#/HardierLaitance',
      }).disposition,
      ProductAdmissionDisposition.web,
    );
    expect(
      ProductAdmissionData.fromJson({
        'trokes': 302,
        'redepositing': 'gold://pocket/recredit',
      }).disposition,
      ProductAdmissionDisposition.creditReview,
    );
    expect(
      ProductAdmissionData.fromJson({
        'trokes': 302,
        'redepositing': 'https://web.example.com/recredit',
      }).disposition,
      ProductAdmissionDisposition.web,
    );
    expect(
      ProductAdmissionData.fromJson({'trokes': 505}).disposition,
      ProductAdmissionDisposition.unavailable,
    );
  });

  test('allows only absolute HTTP(S) product destinations', () {
    expect(productWebUri('https://web.example.com/route'), isNotNull);
    expect(productWebUri('gold://pocket/recredit'), isNull);
    expect(productWebUri('/#/Antimanagement'), isNull);
  });

  test('maps the documented product detail and loan continuation fields', () {
    final detail = ProductDetailData.fromJson({
      'trokes': 200,
      'supramolecular': {
        'ecclesia': 8,
        'readjusts': 'ORDER-8',
        'breaststrokers': '1,000.00',
        'salvationist': [7],
        'nominees': 1,
      },
      'metheglins': {'gabbler': 'Rondo', 'culinarians': 'Bank details'},
      'rubicund': {
        'qintar': 'Use a clear ID photo.',
        'dissyllables': 'Position your face clearly in the frame.',
      },
    });

    expect(detail.statusCode, 200);
    expect(detail.product.productId, '8');
    expect(detail.product.orderNumber, 'ORDER-8');
    expect(detail.product.amount, '1,000.00');
    expect(detail.product.loanTerm, '7');
    expect(detail.product.termType, '1');
    expect(detail.nextStep.type, 'Rondo');
    expect(
      detail.certificationCopy.identityUploadGuidance,
      'Use a clear ID photo.',
    );
    expect(
      detail.certificationCopy.faceVerificationGuidance,
      'Position your face clearly in the frame.',
    );
  });

  test('maps the documented face liveness token response', () {
    final token = FaceLivenessToken.fromJson({
      'bootees': 200,
      'reimplants': 'liveness-license',
      'girandola': '',
      'wealthily': 7,
    });

    expect(token.resultCode, '200');
    expect(token.license, 'liveness-license');
    expect(token.livenessType, 7);
  });

  test('maps the identity recognition response', () {
    final result = IdentityRecognitionData.fromJson({
      'emit': 'NAVEEN TOM VARGHESE',
      'outdueled': '623099344111',
      'matcher': 'Male',
      'palisades': '23/11/1993',
      'redepositing': 'https://example.com/id.jpg',
    });

    expect(result.fullName, 'NAVEEN TOM VARGHESE');
    expect(result.idNumber, '623099344111');
    expect(result.gender, 'Male');
    expect(result.dateOfBirth, '23/11/1993');
    expect(result.imageUrl, 'https://example.com/id.jpg');
  });

  test('uses the first identity group as recommended and flattens others', () {
    final data = ProductIdentityData.fromJson({
      'polycythemic': [
        ['DRIVINGLICENSE', 'PRC', 'PRC'],
        ['TIN', 'VOTERID'],
        ['NATIONALID'],
      ],
    });

    expect(data.recommendedTypes, ['DRIVINGLICENSE', 'PRC']);
    expect(data.otherTypes, ['TIN', 'VOTERID', 'NATIONALID']);
  });
}
