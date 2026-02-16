import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Maps icon name strings to Material Icons for A2UI components.
const Map<String, IconData> _iconMap = {
  'check': Icons.check,
  'warning': Icons.warning_amber_rounded,
  'error': Icons.error_outline,
  'info': Icons.info_outline,
  'star': Icons.star,
  'close': Icons.close,
  'add': Icons.add,
  'search': Icons.search,
  'settings': Icons.settings,
  'person': Icons.person,
  'home': Icons.home,
  'send': Icons.send,
  'edit': Icons.edit,
  'delete': Icons.delete_outline,
  'copy': Icons.copy,
  'share': Icons.share,
  'download': Icons.download,
  'upload': Icons.upload,
  'refresh': Icons.refresh,
  'arrow_forward': Icons.arrow_forward,
  'arrow_back': Icons.arrow_back,
  'favorite': Icons.favorite,
  'location': Icons.location_on,
  'calendar': Icons.calendar_today,
  'time': Icons.access_time,
  'mic': Icons.mic,
  'mic_none': Icons.mic_none,
  'dashboard': Icons.dashboard,
  'play_arrow': Icons.play_arrow,
  'smart_toy': Icons.smart_toy,
  'qr_code': Icons.qr_code,
  'qr_code_scanner': Icons.qr_code_scanner,
  'extension': Icons.extension,
  'analytics': Icons.analytics,
  'security': Icons.security,
  'check_circle': Icons.check_circle_outline,
  'hub': Icons.hub,
  'psychology': Icons.psychology,
  'sync': Icons.sync,
  'broken_image': Icons.broken_image,
  'receipt_long': Icons.receipt_long,
  'flight_takeoff': Icons.flight_takeoff,
  'flight_land': Icons.flight_land,
  'star_border': Icons.star_border,
  'radio_button_checked': Icons.radio_button_checked,
  'pause': Icons.pause,
  'phone_iphone': Symbols.phone_iphone,
  'tablet_mac': Symbols.tablet_mac,
  'desktop_mac': Symbols.desktop_mac,
  'watch': Symbols.watch,
  'eyeglasses': Symbols.eyeglasses,
};

/// Resolves an icon name string to a Material [IconData].
/// Returns `null` for unknown or null names.
IconData? resolveIcon(String? name) {
  if (name == null) return null;
  return _iconMap[name];
}

/// Parses a hex color string (e.g. "#FF6600") into a [Color].
/// Returns `null` if parsing fails or input is null.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return null;
  }
}
