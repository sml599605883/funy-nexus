import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';

void main() {
  test('maps documented and obfuscated home section types', () {
    final data = HomeData.fromJson({
      'chippered': {
        'requiems': 'https://example.com/chat.png',
        'externalising': 'https://example.com/support',
      },
      'semihobos': [
        {
          'etherifying': 'DonkeyCatch',
          'mycetozoan': [
            {
              'ecclesia': 8,
              'redepositing': 'app://banner',
              'closets': 'https://example.com/banner.png',
            },
          ],
        },
        {
          'etherifying': 'Majordomo',
          'mycetozoan': [
            {
              'ecclesia': 101,
              'ritualize': 'Maya Agad',
              'typographies': 'https://example.com/product.png',
              'apparentness': '₱50,000',
              'remediation': 'Maximum Loan Amount Upto',
              'pharmacognosy': '180 days',
              'hoblike': 'Loan Term',
              'filthier': '0.05% day',
              'bravenesses': 'Interest Rate',
              'uremia': 'Complete authentication',
              'soreness': 'Apply Now',
              'crisscrossing': 1,
              'gossans': '0917****567',
              'painters': 'Receipt Account',
              'vicarious': [
                {
                  'culinarians': '91 Days',
                  'geometers': '₱50,000',
                  'myasthenias': 1,
                },
              ],
              'chubbily': [
                {
                  'astrict': '2',
                  'pigeonwing': 'Period',
                  'filthier': '≤ 0.5% / Day',
                },
              ],
              'waul': 'https://example.com/term.png',
              'shades': 'https://example.com/rate.png',
            },
          ],
        },
      ],
    });

    expect(data.isEmpty, isFalse);
    expect(data.customerService?.target, 'https://example.com/support');
    expect(data.banner?.id, '8');
    expect(data.banner?.imageUrl, 'https://example.com/banner.png');
    expect(data.primaryCard?.productId, '101');
    expect(data.primaryCard?.productLogo, 'https://example.com/product.png');
    expect(data.primaryCard?.amount, '₱50,000');
    expect(data.primaryCard?.loanTerm, '180 days');
    expect(data.primaryCard?.interestRate, '0.05% day');
    expect(data.primaryCard?.certificationCompleted, 1);
    expect(data.primaryCard?.receiptAccount, '0917****567');
    expect(data.primaryCard?.receiptAccountLabel, 'Receipt Account');
    expect(data.primaryCard?.certificationProgress.single.title, '91 Days');
    expect(data.primaryCard?.certificationProgress.single.selected, 1);
    expect(data.primaryCard?.loanTermRows.single.period, '2');
    expect(data.primaryCard?.loanTermRows.single.label, 'Period');
    expect(data.primaryCard?.loanTermRows.single.interestRate, '≤ 0.5% / Day');
    expect(data.primaryCard?.loanTermIcon, 'https://example.com/term.png');
    expect(data.primaryCard?.interestRateIcon, 'https://example.com/rate.png');
  });

  test('accepts the original section names from the response example', () {
    final data = HomeData.fromJson({
      'semihobos': [
        {
          'etherifying': 'LARGE_CARD',
          'mycetozoan': [
            {'apparentness': '₱60,000'},
          ],
        },
      ],
    });

    expect(data.primaryCard?.amount, '₱60,000');
  });

  test('does not use SMALL_CARD as the homepage large card', () {
    final data = HomeData.fromJson({
      'semihobos': [
        {
          'etherifying': 'Nonsteroidal',
          'mycetozoan': [
            {'apparentness': '₱10,000'},
          ],
        },
      ],
    });

    expect(data.primaryCard, isNull);
  });

  test('rejects a malformed home section collection', () {
    expect(
      () => HomeData.fromJson({'semihobos': {}}),
      throwsA(isA<FormatException>()),
    );
  });
}
