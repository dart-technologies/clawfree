import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agent_store.dart';

/// Persistent [AgentRepository] backed by [SharedPreferences].
///
/// Use the async factory [create] to construct an instance (loads existing data
/// from disk on startup).
class SharedPreferencesAgentStore extends AgentRepository {
  SharedPreferencesAgentStore._(this._prefs) {
    _load();
  }

  /// Async factory: awaits [SharedPreferences] initialization, then loads.
  static Future<SharedPreferencesAgentStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesAgentStore._(prefs);
  }

  final SharedPreferences _prefs;
  static const _key = 'clawfree_agents';

  @override
  void onModified() => _persist();

  // ---------------------------------------------------------------------------
  // Persistence helpers
  // ---------------------------------------------------------------------------

  void _load() {
    final stored = _prefs.getStringList(_key);
    if (stored == null) return;
    final items = <Map<String, dynamic>>[];
    for (final json in stored) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map<String, dynamic>) {
          items.add(decoded);
        }
      } catch (e) {
        debugPrint('[SharedPreferencesAgentStore] Skipping corrupt entry: $e');
      }
    }
    loadAgents(items);
  }

  /// Fire-and-forget persist for UI responsiveness.
  void _persist() {
    final encoded = agents.map((a) => jsonEncode(a)).toList();
    _prefs.setStringList(_key, encoded);
  }
}
