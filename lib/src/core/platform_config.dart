import 'package:flutter/foundation.dart';

/// Centralizes platform detection and URL resolution.
abstract final class PlatformConfig {
  static bool get isWeb => kIsWeb;

  static bool get isApple {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Resolve the API base URL:
  /// 1. Explicit [gatewayUrl] if non-empty
  /// 2. On web: default to localhost gateway (CORS proxy required)
  /// 3. On native: direct Anthropic API
  static String resolveBaseUrl({String gatewayUrl = ''}) {
    if (gatewayUrl.isNotEmpty) return gatewayUrl;
    if (kIsWeb) return 'http://localhost:18789';
    return 'https://api.anthropic.com';
  }
}
