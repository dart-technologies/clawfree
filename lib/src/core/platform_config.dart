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

  /// Determine the device form factor from screen width and platform.
  static DeviceFormFactor formFactor(BuildContext context) {
    // macOS native is always "desktop" regardless of window size.
    if (isMacOS) return DeviceFormFactor.desktop;

    final width = MediaQuery.sizeOf(context).width;

    if (width < 600) return DeviceFormFactor.phone;
    if (width < 1100) return DeviceFormFactor.tablet;
    return DeviceFormFactor.desktop;
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
