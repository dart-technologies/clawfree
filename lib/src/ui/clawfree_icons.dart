import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../core/platform_config.dart';

/// Platform-adaptive icon registry.
abstract final class ClawfreeIcons {
  static IconData get back =>
      PlatformConfig.isApple ? CupertinoIcons.back : Icons.arrow_back;

  static IconData get send =>
      PlatformConfig.isApple ? CupertinoIcons.arrow_up_circle_fill : Icons.send;

  static IconData get menuOpen =>
      PlatformConfig.isApple ? CupertinoIcons.sidebar_left : Icons.menu_open;

  static IconData get download =>
      PlatformConfig.isApple ? CupertinoIcons.share : Icons.download;

  static const mic = Icons.mic;
  static const micNone = Icons.mic_none;
  static const dashboard = Icons.dashboard;
  static const copy = Icons.copy;
  static const refresh = Icons.refresh;
  static const error = Icons.error_outline;
  static const playArrow = Icons.play_arrow;
  static const key = Icons.key;
  static const agent = Icons.smart_toy;
  static const settings = Icons.settings;
  static const qrCode = Icons.qr_code;
  static const qrCodeScanner = Icons.qr_code_scanner;
  static const skills = Icons.extension;
  static const analytics = Icons.analytics;
  static const security = Icons.security;
  static const success = Icons.check_circle_outline;
  static const check = Icons.check;
  static const add = Icons.add;
  static const menu = Icons.menu;
  static const tune = Icons.tune;
  static const hub = Icons.hub;
  static const psychology = Icons.psychology;
  static const sync = Icons.sync;
  static const brokenImage = Icons.broken_image;
  static const arrowForward = Icons.arrow_forward;
  static const receipt = Icons.receipt_long;
  static const flightTakeoff = Icons.flight_takeoff;
  static const flightLand = Icons.flight_land;
  static const star = Icons.star;
  static const starBorder = Icons.star_border;
  static const timelineDot = Icons.radio_button_checked;
  static const pause = Icons.pause;

  // --- Device Symbols ---
  static const smartphone = Symbols.phone_iphone;
  static const tablet = Symbols.tablet_mac;
  static const desktop = Symbols.desktop_mac;
  static const watch = Symbols.watch;
  static const glasses = Symbols.eyeglasses;

  /// Returns the appropriate symbol for a given device form factor.
  static IconData iconForDeviceType(DeviceFormFactor type) {
    return switch (type) {
      DeviceFormFactor.phone => smartphone,
      DeviceFormFactor.tablet => tablet,
      DeviceFormFactor.desktop => desktop,
      DeviceFormFactor.watch => watch,
      DeviceFormFactor.glasses => glasses,
    };
  }
}
