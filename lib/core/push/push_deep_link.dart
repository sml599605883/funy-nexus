enum PushDeepLinkKind {
  home,
  mine,
  login,
  order,
  productDetail,
  admission,
  creditReview,
  webView,
  unsupported,
}

class PushDeepLink {
  const PushDeepLink({
    required this.kind,
    required this.alias,
    this.uri,
    this.arguments,
  });

  final PushDeepLinkKind kind;
  final String alias;
  final Uri? uri;
  final Object? arguments;

  String get productId {
    // Check for 'modernised' parameter (actual field name from backend)
    final fromQueryModernised = uri?.queryParameters['modernised']?.trim() ?? '';
    if (fromQueryModernised.isNotEmpty) {
      return fromQueryModernised;
    }
    // Fallback to 'productId' for compatibility
    final fromQuery = uri?.queryParameters['productId']?.trim() ?? '';
    if (fromQuery.isNotEmpty) {
      return fromQuery;
    }
    // Check arguments map
    if (arguments is Map) {
      final map = arguments as Map;
      final modernisedValue = map['modernised'];
      if (modernisedValue != null) {
        return modernisedValue.toString().trim();
      }
      final productIdValue = map['productId'];
      if (productIdValue != null) {
        return productIdValue.toString().trim();
      }
    }
    return '';
  }

  String get orderStatus {
    // Check for 'narthex' parameter (actual field name from backend)
    final fromQueryNarthex = uri?.queryParameters['narthex']?.trim() ?? '';
    if (fromQueryNarthex.isNotEmpty) {
      return fromQueryNarthex;
    }
    // Fallback to 'status' for compatibility
    final fromQuery = uri?.queryParameters['status']?.trim() ?? '';
    if (fromQuery.isNotEmpty) {
      return fromQuery;
    }
    // Check arguments map
    if (arguments is Map) {
      final map = arguments as Map;
      final narthexValue = map['narthex'];
      if (narthexValue != null) {
        return narthexValue.toString().trim();
      }
      final statusValue = map['status'];
      if (statusValue != null) {
        return statusValue.toString().trim();
      }
    }
    return '';
  }

  String get orderNumber {
    final fromQuery = uri?.queryParameters['orderNo']?.trim() ?? '';
    if (fromQuery.isNotEmpty) {
      return fromQuery;
    }
    if (arguments is Map) {
      final value = (arguments as Map)['orderNo'];
      return value?.toString().trim() ?? '';
    }
    return '';
  }
}

class PushDeepLinkParser {
  const PushDeepLinkParser();

  static const _scheme = 'ph';
  static const _host = 'fund-nexus';
  static const _platform = 'ios';

  PushDeepLink parse(String rawTarget, {Object? arguments}) {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return const PushDeepLink(
        kind: PushDeepLinkKind.unsupported,
        alias: '',
      );
    }

    // Try direct alias match first
    final directKind = _kindForAlias(target);
    if (directKind != null) {
      return PushDeepLink(
        kind: directKind,
        alias: target,
        arguments: arguments,
      );
    }

    // Parse as URI
    final uri = Uri.tryParse(target);
    if (uri == null) {
      return PushDeepLink(
        kind: PushDeepLinkKind.unsupported,
        alias: target,
        arguments: arguments,
      );
    }

    // HTTP/HTTPS URLs open in WebView
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return PushDeepLink(
        kind: PushDeepLinkKind.webView,
        alias: target,
        uri: uri,
        arguments: arguments,
      );
    }

    // Handle app scheme: ph://fund-nexus/ios/PageName
    if (_isAppScheme(uri)) {
      for (final segment in uri.pathSegments.reversed) {
        if (segment == _platform) {
          continue;
        }
        final kind = _kindForAlias(segment.trim());
        if (kind != null) {
          return PushDeepLink(
            kind: kind,
            alias: segment.trim(),
            uri: uri,
            arguments: arguments,
          );
        }
      }
      return PushDeepLink(
        kind: PushDeepLinkKind.unsupported,
        alias: target,
        uri: uri,
        arguments: arguments,
      );
    }

    // Check for appPage/page query parameter
    final page = uri.queryParameters['appPage'] ?? uri.queryParameters['page'];
    if (page == null) {
      return PushDeepLink(
        kind: PushDeepLinkKind.unsupported,
        alias: target,
        uri: uri,
        arguments: arguments,
      );
    }
    final trimmedPage = page.trim();
    final kind = _kindForAlias(trimmedPage);
    if (kind == null) {
      return PushDeepLink(
        kind: PushDeepLinkKind.unsupported,
        alias: target,
        uri: uri,
        arguments: arguments,
      );
    }
    return PushDeepLink(
      kind: kind,
      alias: trimmedPage,
      uri: uri,
      arguments: arguments,
    );
  }

  PushDeepLinkKind? _kindForAlias(String alias) {
    // Map both clear names and obfuscated names from ph_fund_nexus_ios
    return switch (alias) {
      'Home' || 'main' || 'Prismatic' => PushDeepLinkKind.home,
      'Mine' || 'setting' || 'UnstintedSparse' => PushDeepLinkKind.mine,
      'Login' || '/login' || 'login' || 'Genomes' => PushDeepLinkKind.login,
      'Order' || 'order' || 'BathymetricallyCrepy' => PushDeepLinkKind.order,
      'Loan' || 'ProductDetail' || 'productDetail' || 'Bullied' =>
        PushDeepLinkKind.productDetail,
      'Admission' || 'apiRemindUrl' || 'Painfulness' =>
        PushDeepLinkKind.admission,
      'CreditReview' || 'recredit' || 'MagnetiseRewrap' =>
        PushDeepLinkKind.creditReview,
      _ => null,
    };
  }

  bool _isAppScheme(Uri uri) {
    return uri.scheme == _scheme &&
        uri.host == _host &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == _platform;
  }
}
