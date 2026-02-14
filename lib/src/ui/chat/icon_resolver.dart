import 'package:flutter/material.dart';

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
