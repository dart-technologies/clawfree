import 'package:flutter/material.dart';

import 'device_registry.dart';

/// Displays connected devices as a row of small chips/icons.
class DeviceChips extends StatelessWidget {
  const DeviceChips({super.key, required this.devices});

  final List<ConnectedDevice> devices;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final device = devices[index];
          return _DeviceChip(device: device);
        },
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  const _DeviceChip({required this.device});

  final ConnectedDevice device;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (device.status) {
      DeviceStatus.online => cs.primary,
      DeviceStatus.speaking => cs.error,
      DeviceStatus.offline => cs.outline,
    };

    return Chip(
      avatar: Icon(
        _iconFor(device.deviceType),
        size: 16,
        color: color,
      ),
      label: Text(
        device.deviceName,
        style: TextStyle(fontSize: 11, color: color),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      backgroundColor: color.withValues(alpha: 0.05),
    );
  }

  static IconData _iconFor(String type) {
    return switch (type) {
      'desktop' || 'macos' => Icons.desktop_mac,
      'tablet' || 'ipad' => Icons.tablet_mac,
      'watch' => Icons.watch,
      'web' => Icons.language,
      _ => Icons.phone_iphone,
    };
  }
}
