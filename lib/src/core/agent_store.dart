import 'package:flutter/foundation.dart';

/// Base class for agent configuration storage with shared CRUD logic.
///
/// Subclasses override [onModified] to persist or react to changes, and
/// use [loadAgents] to populate the store at init time.
class AgentRepository extends ChangeNotifier {
  final List<Map<String, dynamic>> _agents = [];

  List<Map<String, dynamic>> get agents => List.unmodifiable(_agents);

  int get count => _agents.length;

  void addAgent(Map<String, dynamic> config) {
    config['created_at'] ??= DateTime.now().toIso8601String();
    config['status'] ??= 'active';
    _agents.add(Map<String, dynamic>.from(config));
    notifyListeners();
    onModified();
  }

  Map<String, dynamic>? findByName(String name) {
    for (final agent in _agents) {
      if (agent['name'] == name) return agent;
    }
    return null;
  }

  bool removeByName(String name) {
    final idx = _agents.indexWhere((a) => a['name'] == name);
    if (idx >= 0) {
      _agents.removeAt(idx);
      notifyListeners();
      onModified();
      return true;
    }
    return false;
  }

  void clear() {
    _agents.clear();
    notifyListeners();
    onModified();
  }

  /// Called after every mutation. Override to persist changes.
  @protected
  void onModified() {}

  /// Bulk-add agents during initialization (does not call [onModified]).
  @protected
  void loadAgents(Iterable<Map<String, dynamic>> items) {
    _agents.addAll(items);
  }
}

/// In-memory agent store (no persistence).
class AgentStore extends AgentRepository {}
