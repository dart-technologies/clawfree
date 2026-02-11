import 'package:flutter/foundation.dart';

/// Interface for agent configuration storage.
abstract class AgentRepository extends ChangeNotifier {
  List<Map<String, dynamic>> get agents;
  int get count;
  void addAgent(Map<String, dynamic> config);
  Map<String, dynamic>? findByName(String name);
  bool removeByName(String name);
}

/// In-memory store for created agent configurations.
class AgentStore extends AgentRepository {
  final List<Map<String, dynamic>> _agents = [];

  @override
  List<Map<String, dynamic>> get agents => List.unmodifiable(_agents);

  @override
  int get count => _agents.length;

  @override
  void addAgent(Map<String, dynamic> config) {
    config['created_at'] ??= DateTime.now().toIso8601String();
    config['status'] ??= 'active';
    _agents.add(Map<String, dynamic>.from(config));
    notifyListeners();
  }

  @override
  Map<String, dynamic>? findByName(String name) {
    for (final agent in _agents) {
      if (agent['name'] == name) return agent;
    }
    return null;
  }

  @override
  bool removeByName(String name) {
    final idx = _agents.indexWhere((a) => a['name'] == name);
    if (idx >= 0) {
      _agents.removeAt(idx);
      notifyListeners();
      return true;
    }
    return false;
  }
}
