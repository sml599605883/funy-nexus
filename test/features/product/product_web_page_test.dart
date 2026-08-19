import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/web/product_web_page.dart';

void main() {
  test('reads the product id only from Antimanagement URLs', () {
    expect(
      productWebRetentionProductId(
        'https://web.example.com/#/Antimanagement?pesters=product-9',
      ),
      'product-9',
    );
    expect(
      productWebRetentionProductId(
        'https://web.example.com/Antimanagement?pesters=product-10',
      ),
      'product-10',
    );
    expect(
      productWebRetentionProductId(
        'https://web.example.com/#/OtherPage?pesters=product-9',
      ),
      isEmpty,
    );
    expect(
      productWebRetentionProductId('https://web.example.com/#/Antimanagement'),
      isEmpty,
    );
  });

  test('uses Loading as the default and the loaded WebView title', () {
    expect(
      resolveProductWebTitle(pageTitle: null, fallback: 'Loading...'),
      'Loading...',
    );
    expect(
      productWebTitleFromJavaScriptResult(
        '"Loan status"',
        fallback: 'Loading...',
      ),
      'Loan status',
    );
    expect(
      productWebTitleFromJavaScriptResult(' ', fallback: 'Loading...'),
      'Loading...',
    );
  });

  test('installs an observer that reports later document title changes', () {
    expect(productWebTitleObserverScript, contains(productWebTitleChannel));
    expect(productWebTitleObserverScript, contains('MutationObserver'));
    expect(productWebTitleObserverScript, contains('document.title'));
  });
}
