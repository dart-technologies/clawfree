import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'platform_config.dart';

/// A connected remote device session from the gateway `/sessions` endpoint.
class RemoteSession {
  const RemoteSession({
    required this.sessionId,
    required this.deviceType,
    required this.deviceName,
    this.connectedAt,
  });

  final String sessionId;
  final DeviceFormFactor deviceType;
  final String deviceName;
  final DateTime? connectedAt;

  factory RemoteSession.fromJson(Map<String, dynamic> json) {
    return RemoteSession(
      sessionId: json['session_id'] as String? ?? '',
      deviceType: _parseDeviceType(json['device_type'] as String?),
      deviceName: json['device_name'] as String? ?? 'Unknown',
      connectedAt: json['connected_at'] != null
          ? DateTime.tryParse(json['connected_at'] as String)
          : null,
    );
  }

  static DeviceFormFactor _parseDeviceType(String? raw) {
    return switch (raw) {
      'desktop' => DeviceFormFactor.desktop,
      'tablet' => DeviceFormFactor.tablet,
      'phone' => DeviceFormFactor.phone,
      'watch' => DeviceFormFactor.watch,
      'glasses' => DeviceFormFactor.glasses,
      _ => DeviceFormFactor.phone,
    };
  }
}

/// Returns an appropriate Material icon for the given device type.
IconData iconForDeviceType(DeviceFormFactor type) {
  return switch (type) {
    DeviceFormFactor.desktop => Symbols.desktop_mac,
    DeviceFormFactor.tablet => Symbols.tablet_mac,
    DeviceFormFactor.phone => Symbols.phone_iphone,
    DeviceFormFactor.watch => Symbols.watch,
    DeviceFormFactor.glasses => Symbols.eyeglasses,
  };
}

/// Returns plausible demo sessions for when no gateway is connected.
/// All devices are included (Mac first, iPad second) so the demo always
/// shows a full fleet regardless of the current form factor.
List<RemoteSession> defaultDemoSessions(DeviceFormFactor self) {
  return const [
    RemoteSession(
      sessionId: 'demo-mac',
      deviceType: DeviceFormFactor.desktop,
      deviceName: 'Mac',
    ),
    RemoteSession(
      sessionId: 'demo-ipad',
      deviceType: DeviceFormFactor.tablet,
      deviceName: 'iPad',
    ),
    RemoteSession(
      sessionId: 'demo-iphone',
      deviceType: DeviceFormFactor.phone,
      deviceName: 'iPhone',
    ),
    RemoteSession(
      sessionId: 'demo-watch',
      deviceType: DeviceFormFactor.watch,
      deviceName: 'Watch',
    ),
    RemoteSession(
      sessionId: 'demo-glasses',
      deviceType: DeviceFormFactor.glasses,
      deviceName: 'Glasses',
    ),
  ];
}
