import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fund_nexus/features/product/data/product_application_data.dart';

class ProductWebPage extends StatefulWidget {
  const ProductWebPage({required this.url, super.key});

  final String url;

  static Uri? validUri(String value) => productWebUri(value);

  @override
  State<ProductWebPage> createState() => _ProductWebPageState();
}

class _ProductWebPageState extends State<ProductWebPage> {
  late final WebViewController _controller;
  var _loading = true;
  var _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final uri = ProductWebPage.validUri(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _loadFailed = true;
              });
            }
          },
        ),
      );
    if (uri != null) {
      _controller.loadRequest(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = ProductWebPage.validUri(widget.url);
    return Scaffold(
      appBar: AppBar(title: const Text('Loan application')),
      body: uri == null
          ? const Center(child: Text('Unable to open this page.'))
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const LinearProgressIndicator(),
                if (_loadFailed)
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadFailed = false;
                        });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
              ],
            ),
    );
  }
}
