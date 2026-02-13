import 'package:flutter/material.dart';

import '../../devices/device_registry.dart';

/// 已連線裝置設定頁面。
///
/// 列出 [DeviceRegistry] 中所有裝置，顯示名稱、類型、狀態與最後上線時間。
/// 採用簡潔 dark-theme 風格，與 Clawfree 整體設計一致。
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key, required this.registry});

  final DeviceRegistry registry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connected Devices')),
      body: ListenableBuilder(
        listenable: registry,
        builder: (context, _) {
          final devices = registry.devices;
          if (devices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.devices, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    'No devices connected',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: devices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _DeviceTile(device: devices[index]),
          );
        },
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});

  final ConnectedDevice device;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = switch (device.status) {
      DeviceStatus.online => Colors.greenAccent,
      DeviceStatus.speaking => cs.error,
      DeviceStatus.offline => Colors.white38,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // 裝置圖示
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(device.deviceType), color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          // 裝置資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.deviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (device.isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'This Device',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle(),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 狀態指示燈
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final type = device.deviceType;
    final lastSeen = device.lastSeen;
    final timeStr = lastSeen != null ? _formatTime(lastSeen) : '';
    final statusStr = device.status.name;
    return [type, statusStr, if (timeStr.isNotEmpty) timeStr].join(' · ');
  }

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
