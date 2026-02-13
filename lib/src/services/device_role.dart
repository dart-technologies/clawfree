import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The role this device plays in the local sync network.
enum SyncRole {
  /// iPhone: runs the WebSocket server and broadcasts events.
  host,

  /// iPad / macOS: connects to the host as a WebSocket client.
  client,
}

/// Determines the sync role for this device automatically.
///
/// - iPhone (iOS + small screen) → host
/// - iPad (iOS + large screen) → client
/// - macOS → client
///
/// Can be overridden manually via [overrideRole].
class DeviceRoleDetector extends ChangeNotifier {
  SyncRole? _override;
  String? _hostIp;

  /// Manually override the detected role.
  void overrideRole(SyncRole role, {String? hostIp}) {
    _override = role;
    _hostIp = hostIp;
    notifyListeners();
  }

  /// The IP address of the host (only relevant for client role).
  String? get hostIp => _hostIp;

  /// Clear the manual override and return to auto-detection.
  void clearOverride() {
    _override = null;
    _hostIp = null;
    notifyListeners();
  }

  /// Detect the role for this device.
  ///
  /// [context] is used to measure screen size on iOS to distinguish
  /// iPhone from iPad.
  SyncRole detect([BuildContext? context]) {
    if (_override != null) return _override!;

    if (kIsWeb) return SyncRole.client;

    if (Platform.isMacOS) return SyncRole.client;

    if (Platform.isIOS) {
      // Use screen shortest side to distinguish iPhone vs iPad.
      // iPhone: < 500, iPad: >= 500 (logical pixels).
      if (context != null) {
        final shortest = MediaQuery.sizeOf(context).shortestSide;
        return shortest < 500 ? SyncRole.host : SyncRole.client;
      }
      // Without context, assume iPhone (host) as the safer default.
      return SyncRole.host;
    }

    return SyncRole.client;
  }
}
