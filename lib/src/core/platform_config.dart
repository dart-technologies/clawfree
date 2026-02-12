import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Device form factor for layout dispatch.
enum DeviceFormFactor {
  /// iPhone-class: < 600px width.
  phone,

  /// iPad-class: 600–1099px width on iOS, or narrow desktop web.
  tablet,

  /// macOS / large desktop browser: >= 1100px width or macOS native.
  desktop,

  /// watchOS target.
  watch,
}

/// Centralizes platform detection and URL resolution.
abstract final class PlatformConfig {
  static bool get isWeb => kIsWeb;

  static bool get isApple {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the platform is likely to have a camera for QR scanning.
  /// Desktop platforms (macOS, Linux, Windows) typically lack one.
  static bool get hasCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  /// Determine the device form factor from screen width and platform.
  static DeviceFormFactor formFactor(BuildContext context) {
    // macOS native is always "desktop" regardless of window size.
    if (isMacOS) return DeviceFormFactor.desktop;

    final width = MediaQuery.sizeOf(context).width;

    if (width < 600) return DeviceFormFactor.phone;
    if (width < 1100) return DeviceFormFactor.tablet;
    return DeviceFormFactor.desktop;
  }

  /// Parse a pairing link (deep link or HTTP gateway URL) into its components.
  /// Returns null if the URI is not a recognized pairing format.
  static ({String url, String? token})? parsePairingUri(Uri uri) {
    if (uri.scheme == 'clawfree' && uri.host == 'pair') {
      final url = uri.queryParameters['url'];
      if (url == null) return null;
      return (url: url, token: uri.queryParameters['token']);
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final url = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      return (url: url, token: null);
    }
    return null;
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
