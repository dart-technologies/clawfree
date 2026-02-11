import 'dart:convert';

/// Parses agent configuration from interaction data or chat history.
class AgentConfigParser {
  /// Try to parse interaction data as an agent config.
  /// Returns null if the data doesn't contain agent fields.
  static Map<String, dynamic>? tryParse(String interactionData) {
    try {
      final data = jsonDecode(interactionData);
      if (data is! Map<String, dynamic>) return null;

      final hasAgentFields = data.keys.any((k) => k.startsWith('/agent/'));
      if (!hasAgentFields) return null;

      return _buildConfig(data);
    } catch (_) {
      return null;
    }
  }

  /// Parse agent config from raw interaction data (throws on invalid input).
  static Map<String, dynamic> parse(String interactionData) {
    final data = jsonDecode(interactionData) as Map<String, dynamic>;
    return _buildConfig(data);
  }

  /// Scan chat history for the most recent agent config submission.
  static Map<String, dynamic>? fromHistory(
    List<Map<String, String>> chatHistory,
  ) {
    for (final msg in chatHistory.reversed) {
      if (msg['role'] == 'user') {
        final content = msg['content'] ?? '';
        if (content.contains('"path"') && content.contains('/agent/')) {
          final result = tryParse(content);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _buildConfig(Map<String, dynamic> data) {
    return {
      'name': data['/agent/name'] ?? 'Untitled Agent',
      'model': data['/agent/model'] ?? 'claude-opus-4-6',
      'tools': data['/agent/tools'] ?? [],
      'channels': data['/agent/channels'] ?? [],
      'config': {
        'version': '1.0',
        'created_by': 'clawfree',
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }
}
