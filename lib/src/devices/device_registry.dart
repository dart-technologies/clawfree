import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/watch_bridge.dart';
import '../services/openclaw_client.dart';

/// Status of a connected device.
enum DeviceStatus { online, offline, speaking }

/// A device connected to the OpenClaw Gateway.
class ConnectedDevice {
  const ConnectedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.status = DeviceStatus.online,
    this.lastSeen,
    this.isSelf = false,
  });

  final String deviceId;
  final String deviceName;
  final String deviceType;
  final DeviceStatus status;
  final DateTime? lastSeen;
  final bool isSelf;

  ConnectedDevice copyWith({DeviceStatus? status, DateTime? lastSeen}) {
    return ConnectedDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isSelf: isSelf,
    );
  }

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? 'Unknown',
      deviceType: json['device_type'] as String? ?? 'phone',
      status: _parseStatus(json['status'] as String?),
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'] as String)
          : null,
    );
  }

  static DeviceStatus _parseStatus(String? raw) {
    return switch (raw) {
      'online' => DeviceStatus.online,
      'speaking' => DeviceStatus.speaking,
      'offline' => DeviceStatus.offline,
      _ => DeviceStatus.online,
    };
  }
}

/// Tracks connected devices via OpenClaw Gateway polling.
///
/// Falls back to local-only mode when the gateway doesn't support
/// `/v1/devices` (404). In local-only mode, tracks self + Watch
/// reachability via [WatchBridge].
class DeviceRegistry extends ChangeNotifier {
  DeviceRegistry({
    required OpenClawClient client,
    this.pollInterval = const Duration(seconds: 10),
  }) : _client = client;

  final OpenClawClient _client;
  final Duration pollInterval;

  Timer? _pollTimer;
  final Map<String, ConnectedDevice> _devices = {};
  String? _selfDeviceId;

  /// When true, the gateway doesn't support `/v1/devices` and we
  /// only track local devices (self + Watch via WCSession).
  bool _localOnly = false;

  /// Whether the registry is in local-only mode (gateway has no devices API).
  bool get isLocalOnly => _localOnly;

  /// All known devices.
  List<ConnectedDevice> get devices => _devices.values.toList();

  /// Other devices (excluding self).
  List<ConnectedDevice> get otherDevices =>
      _devices.values.where((d) => !d.isSelf).toList();

  /// Register this device and start polling.
  ///
  /// If the gateway returns 404 for device registration, switches to
  /// local-only mode — tracking self + Watch reachability only.
  Future<void> registerAndStart({
    required String deviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    _selfDeviceId = deviceId;

    try {
      await _client.registerDevice(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
      );
    } on OpenClawException catch (e) {
      if (e.statusCode == 404) {
        debugPrint('[DeviceRegistry] Gateway has no /v1/devices API — local-only mode');
        _localOnly = true;
      } else {
        debugPrint('[DeviceRegistry] Registration failed: $e');
      }
    } catch (e) {
      debugPrint('[DeviceRegistry] Registration failed: $e');
    }

    // Add self immediately
    _devices[deviceId] = ConnectedDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      status: DeviceStatus.online,
      lastSeen: DateTime.now(),
      isSelf: true,
    );
    notifyListeners();

    // Start polling (gateway devices or Watch reachability)
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
    _poll();
  }

  /// Update self status (e.g. when recording).
  void updateSelfStatus(DeviceStatus status) {
    if (_selfDeviceId == null) return;
    final self = _devices[_selfDeviceId!];
    if (self != null) {
      _devices[_selfDeviceId!] = self.copyWith(
        status: status,
        lastSeen: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> _poll() async {
    if (_localOnly) {
      await _pollWatchReachability();
      return;
    }

    try {
      final deviceList = await _client.fetchDevices();
      final newIds = <String>{};

      for (final json in deviceList) {
        final device = ConnectedDevice.fromJson(json);
        newIds.add(device.deviceId);

        final isSelf = device.deviceId == _selfDeviceId;
        if (isSelf) {
          // Keep local status for self
          final existing = _devices[device.deviceId];
          if (existing != null) continue;
        }

        _devices[device.deviceId] = ConnectedDevice(
          deviceId: device.deviceId,
          deviceName: device.deviceName,
          deviceType: device.deviceType,
          status: device.status,
          lastSeen: device.lastSeen ?? DateTime.now(),
          isSelf: isSelf,
        );
      }

      // Mark missing devices as offline
      for (final id in _devices.keys.toList()) {
        if (!newIds.contains(id) && id != _selfDeviceId) {
          _devices[id] = _devices[id]!.copyWith(status: DeviceStatus.offline);
        }
      }

      notifyListeners();
    } on OpenClawException catch (e) {
      if (e.statusCode == 404) {
        debugPrint('[DeviceRegistry] /v1/devices returned 404 — switching to local-only');
        _localOnly = true;
        await _pollWatchReachability();
      } else {
        debugPrint('[DeviceRegistry] Poll failed: $e');
      }
    } catch (e) {
      debugPrint('[DeviceRegistry] Poll failed: $e');
    }
  }

  /// In local-only mode, check Watch reachability via WCSession
  /// and add/update the Watch device entry accordingly.
  static const _watchDeviceId = 'apple-watch-local';

  Future<void> _pollWatchReachability() async {
    try {
      final reachable = await WatchBridge.isWatchReachable;
      final existing = _devices[_watchDeviceId];

      if (reachable) {
        _devices[_watchDeviceId] = ConnectedDevice(
          deviceId: _watchDeviceId,
          deviceName: 'Apple Watch',
          deviceType: 'watch',
          status: DeviceStatus.online,
          lastSeen: DateTime.now(),
        );
      } else if (existing != null) {
        _devices[_watchDeviceId] = existing.copyWith(
          status: DeviceStatus.offline,
        );
      }
      notifyListeners();
    } catch (_) {
      // WatchBridge not available on this platform
    }
  }

  /// Stop polling.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
