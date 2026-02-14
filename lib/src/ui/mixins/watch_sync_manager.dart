import 'package:flutter/material.dart';

import '../../core/agent_store.dart';
import '../../core/health_poller.dart';
import '../../core/watch_sync_service.dart';
import '../chat_screen.dart';

/// Manages WatchSyncService lifecycle.
mixin WatchSyncManager on State<ChatScreen> {
  WatchSyncService? watchSync;

  void initWatchSync({
    required HealthPoller healthPoller,
    required AgentRepository agentStore,
  }) {
    watchSync = WatchSyncService(
      healthPoller: healthPoller,
      agentStore: agentStore,
    );
    watchSync!.start();
  }

  void updateWatchListening(bool isListening) {
    watchSync?.updateListening(isListening);
  }

  void disposeWatchSync() {
    watchSync?.stop();
  }
}
