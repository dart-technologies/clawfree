import 'dart:async';

import 'package:flutter/services.dart';
import 'agent_store.dart';
import 'health_poller.dart';
import '../ui/health/health_state.dart';

/// Syncs system state from the iPhone to the Apple Watch.
///
/// Uses the `art.dart.clawfree/watch` MethodChannel.
class WatchSyncService {
  WatchSyncService({
    required HealthPoller healthPoller,
    required AgentRepository agentStore,
  })  : _healthPoller = healthPoller,
        _agentStore = agentStore;

  final HealthPoller _healthPoller;
  final AgentRepository _agentStore;
  final _channel = const MethodChannel('art.dart.clawfree/watch');

  bool _isListening = false;
  bool _syncScheduled = false;

  void start() {
    _healthPoller.addListener(_scheduleSync);
    _agentStore.addListener(_scheduleSync);
    _doSync(); // Initial sync (immediate)
  }

  void stop() {
    _healthPoller.removeListener(_scheduleSync);
    _agentStore.removeListener(_scheduleSync);
  }

  void updateListening(bool isListening) {
    if (_isListening == isListening) return;
    _isListening = isListening;
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    scheduleMicrotask(_doSync);
  }

  void _doSync() {
    _syncScheduled = false;
    final health = _healthPoller.state;
    final agentCount = _agentStore.agents.length;

    final levelStr = switch (health.overall) {
      HealthLevel.nominal => 'nominal',
      HealthLevel.degraded => 'degraded',
      HealthLevel.error => 'error',
      HealthLevel.unknown => 'unknown',
    };

    final data = {
      'activeAgentCount': agentCount,
      'healthLevel': levelStr,
      'isListening': _isListening,
    };

    _channel.invokeMethod('syncWatch', data).catchError((e) {
      // Ignore if Watch isn't connected or channel not supported
      return null;
    });
  }
}
