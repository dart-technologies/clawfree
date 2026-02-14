import 'package:flutter/material.dart';

import '../../core/gateway_client.dart';
import '../../core/health_poller.dart';
import '../../core/remote_session.dart';
import '../chat_screen.dart';
import '../health/health_indicators.dart';

/// Manages HealthPoller lifecycle and exposes health state + remote sessions.
mixin HealthMonitorMixin on State<ChatScreen> {
  HealthState healthState = HealthState.nominal();
  HealthPoller? healthPoller;
  List<RemoteSession> remoteSessions = [];

  void initHealthMonitor(GatewayClient gatewayClient) {
    healthPoller = HealthPoller(gatewayClient: gatewayClient);
    healthPoller!.addListener(_onHealthChanged);
    healthPoller!.start();
  }

  void _onHealthChanged() {
    if (mounted) {
      setState(() {
        healthState = healthPoller!.state;
        remoteSessions = healthPoller!.sessions;
      });
    }
  }

  void disposeHealthMonitor() {
    healthPoller?.removeListener(_onHealthChanged);
    healthPoller?.dispose();
  }
}
