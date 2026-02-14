import 'ai_client.dart';

/// A demo AI client that replays pre-recorded Opus responses without network.
/// Useful for live demo reliability and offline testing.
class DemoCacheAiClient implements AiClient {
  DemoCacheAiClient({
    Map<String, String>? cachedResponses,
    this.chunkSize = 40,
    this.chunkDelay = const Duration(milliseconds: 12),
  }) : _cachedResponses = cachedResponses ?? defaultResponses;

  final Map<String, String> _cachedResponses;
  final int chunkSize;
  final Duration chunkDelay;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    final response = _findResponse(prompt);

    // Split at the first JSON fence so conversational text streams with a
    // typing effect while the A2UI JSON block is delivered in one shot
    // (surfaces render instantly instead of waiting for slow chunk-by-chunk).
    final fenceIndex = response.indexOf('```json');
    final textPart = fenceIndex >= 0 ? response.substring(0, fenceIndex) : response;
    final jsonPart = fenceIndex >= 0 ? response.substring(fenceIndex) : '';

    // Stream the conversational text in small chunks (typing effect for TTS).
    for (var i = 0; i < textPart.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, textPart.length);
      yield textPart.substring(i, end);
      if (end < textPart.length) {
        await Future<void>.delayed(chunkDelay);
      }
    }

    // Yield the entire JSON block at once — no delay.
    if (jsonPart.isNotEmpty) {
      yield jsonPart;
    }
  }

  String _findResponse(String prompt) {
    final lower = prompt.toLowerCase();
    // Self-correction prompts from ChatSession should not re-trigger cached
    // surface responses (the "create" keyword inside "createSurface" would
    // match the agent-creation response, causing a 3x repetition loop).
    if (lower.contains('could not be parsed') ||
        lower.contains('please regenerate')) {
      return 'Let me try a different approach. What would you like to do?';
    }
    for (final entry in _cachedResponses.entries) {
      if (entry.key == '_default') continue;
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return _cachedResponses['_default'] ?? 'I can help you with that!';
  }

  @override
  void dispose() {}

  /// Default cached responses for demo scenarios.
  ///
  /// Order matters: entries are checked in insertion order via [contains],
  /// so refinement keywords come before broad creation keywords.
  static final Map<String, String> defaultResponses = {
    // Trip Planning demo (check before generic travel/add)
    'sushi': _sushiClassResponse,
    'weather in tokyo': _tokyoWeatherResponse,
    'create trip': _createTripAgentResponse,
    'trip planner': _createTripAgentResponse,
    'trip agent': _createTripAgentResponse,
    'plan a 3': _tripTokyoItineraryResponse,
    'plan 3': _tripTokyoItineraryResponse,
    '3 day trip': _tripTokyoItineraryResponse,
    '3-day': _tripTokyoItineraryResponse,
    // Refinement (check before broad keywords)
    'rename': _renameAgentResponse,
    'add': _addToolResponse,
    'test': _testAgentResponse,
    'deploy': _deployResponse,
    'help': _helpResponse,
    'delete': _deleteAgentResponse,
    // Travel: compound persona keys checked first (from generate_itinerary action)
    'foodie plan': _tokyoOverviewResponse,
    'artsy plan': _tokyoArtisticResponse,
    'outdoorsy plan': _tokyoOutdoorsyResponse,
    'budget plan': _tokyoOverviewResponse,
    // Travel: all initial requests → persona picker
    'tokyo': _travelSetupResponse,
    'travel': _travelSetupResponse,
    'itinerary': _travelSetupResponse,
    'foodie': _travelSetupResponse,
    'artsy': _travelSetupResponse,
    'outdoorsy': _travelSetupResponse,
    'trip': _travelSetupResponse,
    // Skill Library
    'skill': _skillLibraryResponse,
    'skills': _skillLibraryResponse,
    'library': _skillLibraryResponse,
    'browse': _skillLibraryResponse,
    'capabilities': _skillLibraryResponse,
    // Audit Trail
    'audit': _auditLogResponse,
    'activity': _auditLogResponse,
    'events': _auditLogResponse,
    // Analytics
    'analytics': _analyticsResponse,
    'performance': _analyticsResponse,
    'metrics': _analyticsResponse,
    'stats': _analyticsResponse,
    'usage': _analyticsResponse,
    // Security
    'security': _securityResponse,
    'threats': _securityResponse,
    'vulnerabilities': _securityResponse,
    'compliance': _securityResponse,
    // Creation
    'create': _createAgentResponse,
    'telegram': _createAgentResponse,
    'github': _createAgentResponse,
    // Dashboard
    'show': _dashboardResponse,
    'dashboard': _dashboardResponse,
    'agents': _dashboardResponse,
    // Pairing
    'pair': _pairDeviceResponse,
    'qr': _pairDeviceResponse,
    // Management
    'manage': _manageResponse,
    'update': _manageResponse,
    // Health / Status
    'health': _healthResponse,
    'status': _healthResponse,
    'vitals': _healthResponse,
    // Connect existing gateway
    'connect': _connectGatewayResponse,
    'link': _connectGatewayResponse,
    'gateway': _connectGatewayResponse,
    '_default': 'I understand! Let me help you with that. '
        'What kind of agent would you like to create?\n\n'
        'I can set up agents for automation (GitHub bots, CI/CD), '
        'communication (Telegram, Slack, Discord), '
        'or data processing (web scrapers, API integrators).\n\n'
        'Just tell me what you need!',
  };

  // ---------------------------------------------------------------------------
  // Skill Library: 53 official OpenClaw skills across 9 categories
  // ---------------------------------------------------------------------------

  static const _skillData = <Map<String, dynamic>>[
    // Communication (7)
    {'name': 'Telegram Bridge', 'desc': 'Send and receive messages via Telegram Bot API', 'cat': 'Communication', 'icon': 'mail', 'auto': false},
    {'name': 'Slack Connector', 'desc': 'Post messages, manage channels, and respond to Slack events', 'cat': 'Communication', 'icon': 'mail', 'auto': false},
    {'name': 'Discord Bot', 'desc': 'Discord guild management with slash commands and reactions', 'cat': 'Communication', 'icon': 'mail', 'auto': false},
    {'name': 'Email Gateway', 'desc': 'Send, receive, and filter emails via SMTP/IMAP', 'cat': 'Communication', 'icon': 'mail', 'auto': false},
    {'name': 'SMS Router', 'desc': 'Route SMS messages through Twilio or Vonage', 'cat': 'Communication', 'icon': 'mail', 'auto': false},
    {'name': 'Webhook Relay', 'desc': 'Forward and transform incoming webhooks between services', 'cat': 'Communication', 'icon': 'mail', 'auto': true},
    {'name': 'Push Notifier', 'desc': 'Send push notifications to iOS, Android, and web clients', 'cat': 'Communication', 'icon': 'mail', 'auto': false},
    // Data & Analytics (7)
    {'name': 'API Connector', 'desc': 'Universal REST/GraphQL client with auth and retry logic', 'cat': 'Data & Analytics', 'icon': 'search', 'auto': true},
    {'name': 'CSV/JSON Parser', 'desc': 'Parse, validate, and transform CSV and JSON data streams', 'cat': 'Data & Analytics', 'icon': 'search', 'auto': true},
    {'name': 'SQL Query Engine', 'desc': 'Execute read-only SQL queries against Postgres and MySQL', 'cat': 'Data & Analytics', 'icon': 'search', 'auto': false},
    {'name': 'Data Transformer', 'desc': 'Map, filter, and reshape data between formats', 'cat': 'Data & Analytics', 'icon': 'search', 'auto': false},
    {'name': 'Chart Generator', 'desc': 'Create bar, line, and pie charts from data series', 'cat': 'Data & Analytics', 'icon': 'search', 'auto': false},
    {'name': 'Report Builder', 'desc': 'Generate PDF and HTML reports from templates', 'cat': 'Data & Analytics', 'icon': 'search', 'auto': false},
    {'name': 'Stream Processor', 'desc': 'Process real-time event streams with windowing and aggregation', 'cat': 'Data & Analytics', 'icon': 'search', 'auto': false},
    // Development (7)
    {'name': 'Package Auditor', 'desc': 'Scan dependencies for known vulnerabilities and license issues', 'cat': 'Development', 'icon': 'settings', 'auto': true},
    {'name': 'Git Watcher', 'desc': 'Monitor repositories for commits, PRs, and branch changes', 'cat': 'Development', 'icon': 'settings', 'auto': false},
    {'name': 'CI/CD Trigger', 'desc': 'Trigger and monitor CI/CD pipelines across providers', 'cat': 'Development', 'icon': 'settings', 'auto': false},
    {'name': 'Code Formatter', 'desc': 'Auto-format code in 20+ languages on commit or save', 'cat': 'Development', 'icon': 'settings', 'auto': false},
    {'name': 'Dep Scanner', 'desc': 'Detect outdated dependencies and suggest upgrade paths', 'cat': 'Development', 'icon': 'settings', 'auto': false},
    {'name': 'Test Runner', 'desc': 'Execute and report test suites with parallel execution', 'cat': 'Development', 'icon': 'settings', 'auto': false},
    {'name': 'Linter', 'desc': 'Run static analysis rules across project files', 'cat': 'Development', 'icon': 'settings', 'auto': false},
    // Security (6)
    {'name': 'Secret Scanner', 'desc': 'Detect leaked API keys, tokens, and credentials in code', 'cat': 'Security', 'icon': 'lock', 'auto': true},
    {'name': 'Cert Monitor', 'desc': 'Track TLS certificate expiry and auto-renew via ACME', 'cat': 'Security', 'icon': 'lock', 'auto': true},
    {'name': 'Access Controller', 'desc': 'Role-based access control for agents and resources', 'cat': 'Security', 'icon': 'lock', 'auto': false},
    {'name': 'Threat Detector', 'desc': 'Analyze request patterns for anomalies and attacks', 'cat': 'Security', 'icon': 'lock', 'auto': false},
    {'name': 'Vuln Scanner', 'desc': 'Scan infrastructure and containers for known CVEs', 'cat': 'Security', 'icon': 'lock', 'auto': false},
    {'name': 'Token Rotator', 'desc': 'Automatically rotate API keys and secrets on schedule', 'cat': 'Security', 'icon': 'lock', 'auto': false},
    // AI & ML (6)
    {'name': 'Prompt Router', 'desc': 'Route prompts to optimal models based on complexity and cost', 'cat': 'AI & ML', 'icon': 'star', 'auto': true},
    {'name': 'Model Switcher', 'desc': 'Hot-swap between LLM providers without downtime', 'cat': 'AI & ML', 'icon': 'star', 'auto': false},
    {'name': 'Embedding Store', 'desc': 'Store and query vector embeddings for semantic search', 'cat': 'AI & ML', 'icon': 'star', 'auto': false},
    {'name': 'Classifier', 'desc': 'Classify text into categories using fine-tuned models', 'cat': 'AI & ML', 'icon': 'star', 'auto': false},
    {'name': 'Summarizer', 'desc': 'Generate concise summaries of long documents and threads', 'cat': 'AI & ML', 'icon': 'star', 'auto': false},
    {'name': 'RAG Pipeline', 'desc': 'Retrieval-augmented generation with document chunking', 'cat': 'AI & ML', 'icon': 'star', 'auto': false},
    // Infrastructure (6)
    {'name': 'Health Monitor', 'desc': 'Poll endpoints and report uptime with alerting', 'cat': 'Infrastructure', 'icon': 'visibility', 'auto': true},
    {'name': 'Log Aggregator', 'desc': 'Collect, index, and search logs from all services', 'cat': 'Infrastructure', 'icon': 'visibility', 'auto': false},
    {'name': 'Container Manager', 'desc': 'Start, stop, and scale Docker containers remotely', 'cat': 'Infrastructure', 'icon': 'visibility', 'auto': false},
    {'name': 'DNS Resolver', 'desc': 'Manage DNS records and propagation checking', 'cat': 'Infrastructure', 'icon': 'visibility', 'auto': false},
    {'name': 'Load Balancer', 'desc': 'Distribute traffic across backend instances', 'cat': 'Infrastructure', 'icon': 'visibility', 'auto': false},
    {'name': 'Backup Scheduler', 'desc': 'Schedule and verify automated backups', 'cat': 'Infrastructure', 'icon': 'visibility', 'auto': false},
    // Productivity (5)
    {'name': 'Doc Summarizer', 'desc': 'Summarize documents, emails, and meeting transcripts', 'cat': 'Productivity', 'icon': 'check', 'auto': true},
    {'name': 'Calendar Sync', 'desc': 'Sync events across Google, Outlook, and Apple calendars', 'cat': 'Productivity', 'icon': 'check', 'auto': false},
    {'name': 'Task Tracker', 'desc': 'Create and manage tasks in Jira, Linear, and Asana', 'cat': 'Productivity', 'icon': 'check', 'auto': false},
    {'name': 'Note Taker', 'desc': 'Capture and organize meeting notes with action items', 'cat': 'Productivity', 'icon': 'check', 'auto': false},
    {'name': 'Reminder Service', 'desc': 'Schedule and deliver time-based and location-based reminders', 'cat': 'Productivity', 'icon': 'check', 'auto': false},
    // Media & Content (5)
    {'name': 'Content Moderator', 'desc': 'Filter and flag inappropriate text and image content', 'cat': 'Media & Content', 'icon': 'download', 'auto': true},
    {'name': 'Markdown Renderer', 'desc': 'Convert Markdown to HTML, PDF, and rich text', 'cat': 'Media & Content', 'icon': 'download', 'auto': true},
    {'name': 'Image Optimizer', 'desc': 'Resize, compress, and convert images for web and mobile', 'cat': 'Media & Content', 'icon': 'download', 'auto': false},
    {'name': 'PDF Generator', 'desc': 'Create PDFs from templates with dynamic data binding', 'cat': 'Media & Content', 'icon': 'download', 'auto': false},
    {'name': 'Media Transcoder', 'desc': 'Convert audio and video between formats and bitrates', 'cat': 'Media & Content', 'icon': 'download', 'auto': false},
    // System & Core (4, all auto)
    {'name': 'Registry', 'desc': 'Central service registry for skill discovery and routing', 'cat': 'System & Core', 'icon': 'home', 'auto': true},
    {'name': 'Event Bus', 'desc': 'Publish-subscribe event bus for inter-skill communication', 'cat': 'System & Core', 'icon': 'home', 'auto': true},
    {'name': 'Rate Limiter', 'desc': 'Enforce per-agent and per-skill rate limits', 'cat': 'System & Core', 'icon': 'home', 'auto': true},
    {'name': 'Audit Logger', 'desc': 'Immutable audit trail for all system actions', 'cat': 'System & Core', 'icon': 'home', 'auto': true},
  ];

  /// Build the Skill Library A2UI JSON programmatically from [_skillData].
  static String get _skillLibraryResponse {
    // Group skills by category preserving insertion order.
    final categories = <String, List<Map<String, dynamic>>>{};
    for (final s in _skillData) {
      (categories[s['cat'] as String] ??= []).add(s);
    }

    final allComponents = <Map<String, dynamic>>[];
    final tabEntries = <Map<String, String>>[];
    var idx = 0;

    for (final entry in categories.entries) {
      final cat = entry.key;
      final skills = entry.value;
      final tabId = 'tab-${cat.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}';
      tabEntries.add({'label': cat, 'content': tabId});

      final cardIds = <String>[];
      for (final skill in skills) {
        final sid = 'sk-$idx';
        final autoMark = (skill['auto'] as bool) ? '\u2705 Auto' : '';
        cardIds.add('$sid-card');
        // Flat Card > Column > [name, desc] layout — no Row alignment issues.
        allComponents.addAll([
          {'id': '$sid-card', 'component': 'Card', 'child': '$sid-col'},
          {'id': '$sid-col', 'component': 'Column', 'children': [
            '$sid-name',
            '$sid-desc',
            if (autoMark.isNotEmpty) '$sid-auto',
          ]},
          {'id': '$sid-name', 'component': 'Text', 'text': skill['name'], 'variant': 'h6'},
          {'id': '$sid-desc', 'component': 'Text', 'text': skill['desc'], 'variant': 'body2'},
          if (autoMark.isNotEmpty)
            {'id': '$sid-auto', 'component': 'Text', 'text': autoMark, 'variant': 'caption'},
        ]);
        idx++;
      }

      // Use List (scrollable via ListView) instead of Column to prevent overflow.
      allComponents.addAll([
        {'id': tabId, 'component': 'List', 'direction': 'vertical', 'children': cardIds},
      ]);
    }

    // Build Tabs wrapping the category columns.
    // genUI Tabs expects: "tabs": [{"label": "...", "content": "component-id"}, ...]
    allComponents.addAll([
      {'id': 'root', 'component': 'Column', 'children': ['title', 'subtitle', 'skill-tabs']},
      {'id': 'title', 'component': 'Text', 'text': 'Skill Library', 'variant': 'h4'},
      {'id': 'subtitle', 'component': 'Text', 'text': '53 skills \u2022 9 categories \u2022 14 auto-activated'},
      {
        'id': 'skill-tabs',
        'component': 'Tabs',
        'tabs': tabEntries,
      },
    ]);

    // Encode JSON.
    final surface = [
      {'version': 'v0.9', 'createSurface': {'surfaceId': 'skill-library-001', 'catalogId': _catalogId}},
      {'version': 'v0.9', 'updateComponents': {'surfaceId': 'skill-library-001', 'components': allComponents}},
    ];

    final json = _jsonEncode(surface);
    return 'Here\u2019s the full OpenClaw skill library \u2014 53 official skills across 9 categories. '
        'Skills marked with a check are auto-activated on every new agent.\n\n'
        '```json\n$json\n```';
  }

  /// Compact JSON encoder (no pretty-print to keep response small).
  static String _jsonEncode(Object value) {
    // Use dart:convert indirectly via String interpolation to avoid import.
    final sb = StringBuffer();
    _writeJson(value, sb);
    return sb.toString();
  }

  static void _writeJson(Object? value, StringBuffer sb) {
    if (value == null) {
      sb.write('null');
    } else if (value is bool) {
      sb.write(value ? 'true' : 'false');
    } else if (value is num) {
      sb.write(value);
    } else if (value is String) {
      sb.write('"');
      sb.write(value
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n'));
      sb.write('"');
    } else if (value is List) {
      sb.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) sb.write(',');
        _writeJson(value[i], sb);
      }
      sb.write(']');
    } else if (value is Map) {
      sb.write('{');
      var first = true;
      for (final e in value.entries) {
        if (!first) sb.write(',');
        first = false;
        _writeJson(e.key, sb);
        sb.write(':');
        _writeJson(e.value, sb);
      }
      sb.write('}');
    }
  }

  // ---------------------------------------------------------------------------
  // Audit Trail
  // ---------------------------------------------------------------------------

  static const _auditLogResponse =
      '''Here's the recent activity log for your OpenClaw instance.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "audit-log-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "audit-log-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "filter", "log-list"]},
    {"id": "title", "component": "Text", "text": "Audit Trail", "variant": "h4"},
    {"id": "filter", "component": "ChoicePicker", "label": "Filter", "variant": "mutuallyExclusive", "options": [{"label": "All", "value": "all"}, {"label": "Agents", "value": "agents"}, {"label": "System", "value": "system"}, {"label": "Security", "value": "security"}], "value": ["all"]},
    {"id": "log-list", "component": "Column", "children": ["log-1", "log-2", "log-3", "log-4", "log-5", "log-6", "log-7", "log-8"]},
    {"id": "log-1", "component": "Card", "child": "log-1-row"},
    {"id": "log-1-row", "component": "Row", "children": ["log-1-icon", "log-1-info"]},
    {"id": "log-1-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-1-info", "component": "Column", "children": ["log-1-title", "log-1-time"]},
    {"id": "log-1-title", "component": "Text", "text": "Agent 'GitDigest Bot' deployed successfully", "variant": "body1"},
    {"id": "log-1-time", "component": "Text", "text": "2 min ago \u2022 Agent", "variant": "caption"},
    {"id": "log-2", "component": "Card", "child": "log-2-row"},
    {"id": "log-2-row", "component": "Row", "children": ["log-2-icon", "log-2-info"]},
    {"id": "log-2-icon", "component": "Icon", "icon": "lock", "size": "small"},
    {"id": "log-2-info", "component": "Column", "children": ["log-2-title", "log-2-time"]},
    {"id": "log-2-title", "component": "Text", "text": "API key rotated for Anthropic provider", "variant": "body1"},
    {"id": "log-2-time", "component": "Text", "text": "8 min ago \u2022 Security", "variant": "caption"},
    {"id": "log-3", "component": "Card", "child": "log-3-row"},
    {"id": "log-3-row", "component": "Row", "children": ["log-3-icon", "log-3-info"]},
    {"id": "log-3-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-3-info", "component": "Column", "children": ["log-3-title", "log-3-time"]},
    {"id": "log-3-title", "component": "Text", "text": "Health check passed \u2014 all services nominal", "variant": "body1"},
    {"id": "log-3-time", "component": "Text", "text": "15 min ago \u2022 System", "variant": "caption"},
    {"id": "log-4", "component": "Card", "child": "log-4-row"},
    {"id": "log-4-row", "component": "Row", "children": ["log-4-icon", "log-4-info"]},
    {"id": "log-4-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "log-4-info", "component": "Column", "children": ["log-4-title", "log-4-time"]},
    {"id": "log-4-title", "component": "Text", "text": "Rate limit threshold reached for Slack Connector", "variant": "body1"},
    {"id": "log-4-time", "component": "Text", "text": "22 min ago \u2022 Agent", "variant": "caption"},
    {"id": "log-5", "component": "Card", "child": "log-5-row"},
    {"id": "log-5-row", "component": "Row", "children": ["log-5-icon", "log-5-info"]},
    {"id": "log-5-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-5-info", "component": "Column", "children": ["log-5-title", "log-5-time"]},
    {"id": "log-5-title", "component": "Text", "text": "Skill 'Secret Scanner' completed sweep \u2014 0 findings", "variant": "body1"},
    {"id": "log-5-time", "component": "Text", "text": "31 min ago \u2022 Security", "variant": "caption"},
    {"id": "log-6", "component": "Card", "child": "log-6-row"},
    {"id": "log-6-row", "component": "Row", "children": ["log-6-icon", "log-6-info"]},
    {"id": "log-6-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-6-info", "component": "Column", "children": ["log-6-title", "log-6-time"]},
    {"id": "log-6-title", "component": "Text", "text": "Gateway upgraded to v2026.2.9", "variant": "body1"},
    {"id": "log-6-time", "component": "Text", "text": "1h ago \u2022 System", "variant": "caption"},
    {"id": "log-7", "component": "Card", "child": "log-7-row"},
    {"id": "log-7-row", "component": "Row", "children": ["log-7-icon", "log-7-info"]},
    {"id": "log-7-icon", "component": "Icon", "icon": "lock", "size": "small"},
    {"id": "log-7-info", "component": "Column", "children": ["log-7-title", "log-7-time"]},
    {"id": "log-7-title", "component": "Text", "text": "New device paired via QR code", "variant": "body1"},
    {"id": "log-7-time", "component": "Text", "text": "1h 15m ago \u2022 Security", "variant": "caption"},
    {"id": "log-8", "component": "Card", "child": "log-8-row"},
    {"id": "log-8-row", "component": "Row", "children": ["log-8-icon", "log-8-info"]},
    {"id": "log-8-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "log-8-info", "component": "Column", "children": ["log-8-title", "log-8-time"]},
    {"id": "log-8-title", "component": "Text", "text": "TLS certificate for api.example.com expires in 14 days", "variant": "body1"},
    {"id": "log-8-time", "component": "Text", "text": "2h ago \u2022 Security", "variant": "caption"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Performance Analytics
  // ---------------------------------------------------------------------------

  static const _analyticsResponse =
      '''Your system is running smoothly. Response speed is fast, memory is healthy, and you're well within budget.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "analytics-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "analytics-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "barometers-grid", "indicators-card", "workforce-card", "fuel-card", "export-btn"]},
    {"id": "title", "component": "Text", "text": "Performance Vitals", "variant": "h4"},
    {"id": "barometers-grid", "component": "ResponsiveContainer", "children": ["speed-card", "memory-card", "reliability-card", "workforce-summary"]},
    {"id": "speed-card", "component": "Card", "child": "speed-col"},
    {"id": "speed-col", "component": "Column", "children": ["speed-val", "speed-label", "speed-slider"]},
    {"id": "speed-val", "component": "Text", "text": "Fast", "variant": "h4"},
    {"id": "speed-label", "component": "Text", "text": "Response Speed", "variant": "caption"},
    {"id": "speed-slider", "component": "Slider", "label": "Speed", "value": 88, "min": 0, "max": 100},
    {"id": "memory-card", "component": "Card", "child": "memory-col"},
    {"id": "memory-col", "component": "Column", "children": ["memory-val", "memory-label", "memory-slider"]},
    {"id": "memory-val", "component": "Text", "text": "85%", "variant": "h4"},
    {"id": "memory-label", "component": "Text", "text": "Short-term Memory", "variant": "caption"},
    {"id": "memory-slider", "component": "Slider", "label": "Memory", "value": 85, "min": 0, "max": 100},
    {"id": "reliability-card", "component": "Card", "child": "rel-col"},
    {"id": "rel-col", "component": "Column", "children": ["rel-val", "rel-label"]},
    {"id": "rel-val", "component": "Text", "text": "\u2b50\u2b50\u2b50\u2b50\u2b50", "variant": "h4"},
    {"id": "rel-label", "component": "Text", "text": "Reliability (99.2%)", "variant": "caption"},
    {"id": "workforce-summary", "component": "Card", "child": "wf-col"},
    {"id": "wf-col", "component": "Column", "children": ["wf-val", "wf-label"]},
    {"id": "wf-val", "component": "Text", "text": "\ud83d\udfe2\ud83d\udfe2\ud83d\udfe2 Online", "variant": "h4"},
    {"id": "wf-label", "component": "Text", "text": "Active Workforce (3 agents)", "variant": "caption"},
    {"id": "indicators-card", "component": "Card", "child": "ind-col"},
    {"id": "ind-col", "component": "Column", "children": ["ind-title", "ind-1", "ind-2", "ind-3"]},
    {"id": "ind-title", "component": "Text", "text": "Agent Activity", "variant": "h5"},
    {"id": "ind-1", "component": "Text", "text": "\ud83d\udfe2 GitDigest Bot \u2014 Cruising (98ms avg) \u2022 \u2b50\u2b50\u2b50\u2b50\u2b50 Reliability"},
    {"id": "ind-2", "component": "Text", "text": "\ud83d\udfe2 Slack Monitor \u2014 Busy (156ms avg) \u2022 \u2b50\u2b50\u2b50\u2b50\u2b50 Reliability"},
    {"id": "ind-3", "component": "Text", "text": "\ud83d\udfe1 Data Pipeline \u2014 Working Hard (203ms avg) \u2022 \u2b50\u2b50\u2b50\u2b50 Reliability"},
    {"id": "workforce-card", "component": "Card", "child": "skills-col"},
    {"id": "skills-col", "component": "Column", "children": ["skills-title", "skill-1", "skill-2", "skill-3", "skill-4", "skill-5"]},
    {"id": "skills-title", "component": "Text", "text": "Hardest-Working Skills", "variant": "h5"},
    {"id": "skill-1", "component": "Text", "text": "Rate Limiter \u2022 2,847 actions \u2022 Barely breaking a sweat (1ms)"},
    {"id": "skill-2", "component": "Text", "text": "API Connector \u2022 1,847 actions \u2022 Quick responses (45ms)"},
    {"id": "skill-3", "component": "Text", "text": "Webhook Relay \u2022 923 actions \u2022 Lightning fast (12ms)"},
    {"id": "skill-4", "component": "Text", "text": "Prompt Router \u2022 847 actions \u2022 Instant routing (8ms)"},
    {"id": "skill-5", "component": "Text", "text": "Secret Scanner \u2022 53 deep scans \u2022 Thorough (340ms)"},
    {"id": "fuel-card", "component": "Card", "child": "fuel-col"},
    {"id": "fuel-col", "component": "Column", "children": ["fuel-title", "fuel-detail", "fuel-slider"]},
    {"id": "fuel-title", "component": "Text", "text": "Budget Fuel Tank (24h)", "variant": "h5"},
    {"id": "fuel-detail", "component": "Text", "text": "\$22.90 spent of \$50 daily budget \u2014 54% remaining. Opus handles the hard thinking, Haiku does the quick jobs."},
    {"id": "fuel-slider", "component": "Slider", "label": "Budget", "value": 54, "min": 0, "max": 100},
    {"id": "export-btn", "component": "Button", "child": "export-btn-text", "variant": "secondary", "action": {"event": {"name": "export_analytics"}}},
    {"id": "export-btn-text", "component": "Text", "text": "Export to CSV"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Security Overview
  // ---------------------------------------------------------------------------

  static const _securityResponse =
      '''Here's your security overview. Overall score: 94/100 — looking good!

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "security-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "security-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "score-card", "findings-card", "compliance-card", "actions-row"]},
    {"id": "title", "component": "Text", "text": "Security Overview", "variant": "h4"},
    {"id": "score-card", "component": "Card", "child": "score-col"},
    {"id": "score-col", "component": "Column", "children": ["score-label", "score-slider", "score-detail"]},
    {"id": "score-label", "component": "Text", "text": "Security Score", "variant": "h5"},
    {"id": "score-slider", "component": "Slider", "label": "Score", "value": 94, "min": 0, "max": 100},
    {"id": "score-detail", "component": "Text", "text": "94 / 100 \u2014 Excellent. 2 medium findings, 0 critical.", "variant": "body2"},
    {"id": "findings-card", "component": "Card", "child": "findings-col"},
    {"id": "findings-col", "component": "Column", "children": ["findings-title", "finding-1", "finding-2", "finding-3", "finding-4"]},
    {"id": "findings-title", "component": "Text", "text": "Recent Findings", "variant": "h5"},
    {"id": "finding-1", "component": "Row", "children": ["f1-icon", "f1-text"]},
    {"id": "f1-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "f1-text", "component": "Text", "text": "All API keys rotated within last 30 days"},
    {"id": "finding-2", "component": "Row", "children": ["f2-icon", "f2-text"]},
    {"id": "f2-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "f2-text", "component": "Text", "text": "TLS cert for api.example.com expires in 14 days"},
    {"id": "finding-3", "component": "Row", "children": ["f3-icon", "f3-text"]},
    {"id": "f3-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "f3-text", "component": "Text", "text": "2 dependencies have known vulnerabilities (low severity)"},
    {"id": "finding-4", "component": "Row", "children": ["f4-icon", "f4-text"]},
    {"id": "f4-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "f4-text", "component": "Text", "text": "No leaked secrets detected in last scan"},
    {"id": "compliance-card", "component": "Card", "child": "compliance-col"},
    {"id": "compliance-col", "component": "Column", "children": ["compliance-title", "comp-soc2", "comp-gdpr", "comp-hipaa", "comp-encrypt"]},
    {"id": "compliance-title", "component": "Text", "text": "Compliance Checklist", "variant": "h5"},
    {"id": "comp-soc2", "component": "CheckBox", "label": "SOC 2 Type II — Audit logging enabled", "value": true},
    {"id": "comp-gdpr", "component": "CheckBox", "label": "GDPR — Data retention policies configured", "value": true},
    {"id": "comp-hipaa", "component": "CheckBox", "label": "HIPAA — Encryption at rest enabled", "value": true},
    {"id": "comp-encrypt", "component": "CheckBox", "label": "Encryption — TLS 1.3 enforced on all endpoints", "value": true},
    {"id": "actions-row", "component": "Row", "children": ["scan-btn", "rotate-btn", "export-btn"]},
    {"id": "scan-btn", "component": "Button", "child": "scan-btn-text", "variant": "primary", "action": {"event": {"name": "run_security_scan"}}},
    {"id": "scan-btn-text", "component": "Text", "text": "Run Scan"},
    {"id": "rotate-btn", "component": "Button", "child": "rotate-btn-text", "variant": "secondary", "action": {"event": {"name": "rotate_api_keys"}}},
    {"id": "rotate-btn-text", "component": "Text", "text": "Rotate Keys"},
    {"id": "export-btn", "component": "Button", "child": "export-btn-text", "variant": "secondary", "action": {"event": {"name": "export_compliance"}}},
    {"id": "export-btn-text", "component": "Text", "text": "Export Report"}
  ]}}
]
```''';

  static const _catalogId =
      'https://a2ui.org/specification/v0_9/standard_catalog.json';

  static const _createAgentResponse =
      '''Great! I'll help you create an agent. Let me build a configuration form for you.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-form-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "name-field", "model-picker", "tools-picker", "channels-picker", "save-btn"]},
    {"id": "title", "component": "Text", "text": "Create New Agent", "variant": "h4"},
    {"id": "name-field", "component": "TextField", "label": "Agent Name", "text": "My Agent"},
    {"id": "model-picker", "component": "ChoicePicker", "label": "AI Model", "variant": "mutuallyExclusive", "options": [{"label": "Claude Opus 4.6", "value": "claude-opus-4-6"}, {"label": "Claude Sonnet 4.5", "value": "claude-sonnet-4-5"}, {"label": "GPT-4o", "value": "gpt-4o"}], "value": []},
    {"id": "tools-picker", "component": "ChoicePicker", "label": "Tools", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": []},
    {"id": "channels-picker", "component": "ChoicePicker", "label": "Channels", "variant": "multipleSelection", "options": [{"label": "Telegram", "value": "telegram"}, {"label": "Slack", "value": "slack"}, {"label": "Discord", "value": "discord"}], "value": []},
    {"id": "save-btn", "component": "Button", "child": "save-btn-text", "variant": "primary", "action": {"event": {"name": "save_agent", "context": {"name": {"path": "name-field.value"}, "model": {"path": "model-picker.value"}, "tools": {"path": "tools-picker.value"}, "channels": {"path": "channels-picker.value"}}}}},
    {"id": "save-btn-text", "component": "Text", "text": "Save Agent"}
  ]}}
]
```''';

  static const _dashboardResponse =
      '''Here are your agents! Let me generate a dashboard view.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "dashboard-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "dashboard-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "agent-card-1"]},
    {"id": "title", "component": "Text", "text": "Your Agents", "variant": "h4"},
    {"id": "agent-card-1", "component": "Card", "child": "agent-1-info"},
    {"id": "agent-1-info", "component": "Column", "children": ["agent-1-name", "agent-1-status"]},
    {"id": "agent-1-name", "component": "Text", "text": "GitDigest Bot", "variant": "h5"},
    {"id": "agent-1-status", "component": "Text", "text": "Status: Active | Model: Claude Opus 4.6"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Multi-turn refinement responses (updateComponents on existing surface)
  // ---------------------------------------------------------------------------

  static const _renameAgentResponse =
      '''Done! I've updated the agent name to "GitHub Digest Bot".

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "name-field", "component": "TextField", "label": "Agent Name", "text": "GitHub Digest Bot"}
  ]}}
]
```''';

  static const _addToolResponse =
      '''I've added the Browser tool to your agent configuration.

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "tools-picker", "component": "ChoicePicker", "label": "Tools", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": ["browser"]}
  ]}}
]
```''';

  static const _testAgentResponse =
      'Your agent is configured and ready to test! '
      'Once deployed via OpenClaw, it will be available on your selected channels. '
      'You can test it by sending messages through Telegram, Slack, or whichever channel you chose.';

  static const _deployResponse =
      'Deploying your agent to OpenClaw! '
      'The agent will be live on your selected channels within a few minutes. '
      'You\'ll receive a confirmation once the deployment is complete.';

  static const _helpResponse =
      'Here\'s what I can do:\n\n'
      '- **Create an agent**: "Create a GitHub automation agent"\n'
      '- **Modify the form**: "Rename it to X" or "Add browser tool"\n'
      '- **Save**: Click the Save Agent button in the form\n'
      '- **View agents**: "Show my agents" or "Open the dashboard"\n'
      '- **Test/Deploy**: "Test the agent" or "Deploy it"\n'
      '- **Plan a trip**: "Plan a trip" or "Set up a travel agent"\n'
      '- **Pair a device**: "Pair my watch" or "Show QR code"\n'
      '- **Manage gateway**: "Manage OpenClaw" or "Update gateway"\n'
      '- **Check health**: "System health" or "Check status"\n'
      '- **Connect gateway**: "Connect to my gateway" or "Link gateway"\n'
      '- **Browse skills**: "Show skill library" or "Browse capabilities"\n'
      '- **Audit trail**: "Show audit log" or "Recent activity"\n'
      '- **Analytics**: "Show analytics" or "Performance metrics"\n'
      '- **Security**: "Security overview" or "Run a scan"\n\n'
      'Just speak or type your request!';

  static const _deleteAgentResponse =
      'Agent deleted. You can create a new one anytime \u2014 '
      'just say "Create an agent" to get started again.';

  // ---------------------------------------------------------------------------
  // Pairing: QR code surface
  // ---------------------------------------------------------------------------

  static const _pairDeviceResponse =
      '''Here's a QR code to pair your device with this OpenClaw instance.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "pair-qr-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "pair-qr-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "qr-card", "instructions", "copy-btn"]},
    {"id": "title", "component": "Text", "text": "Pair Device", "variant": "h4"},
    {"id": "qr-card", "component": "Card", "child": "qr-content"},
    {"id": "qr-content", "component": "Column", "children": ["qr-label", "qr-code", "backup-code"]},
    {"id": "qr-label", "component": "Text", "text": "Scan with your phone or watch", "variant": "body2"},
    {"id": "qr-code", "component": "Image", "url": "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=clawfree-pair%3A%2F%2Flocalhost%3A18789%3Ftoken%3Ddemo-pair-token", "variant": "mediumFeature"},
    {"id": "backup-code", "component": "Text", "text": "Backup code: 847 291", "variant": "body2"},
    {"id": "instructions", "component": "Text", "text": "This link connects your device to the local OpenClaw gateway at ws://localhost:18789. The pairing token expires in 10 minutes."},
    {"id": "copy-btn", "component": "Button", "child": "copy-btn-text", "variant": "secondary", "action": {"event": {"name": "copy_pairing_link", "context": {"url": "ws://localhost:18789?token=demo-pair-token"}}}},
    {"id": "copy-btn-text", "component": "Text", "text": "Copy Pairing Link"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Management: OpenClaw controls
  // ---------------------------------------------------------------------------

  static const _manageResponse =
      '''Here's your OpenClaw management dashboard.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "manage-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "manage-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "version-card", "actions-card"]},
    {"id": "title", "component": "Text", "text": "Manage OpenClaw", "variant": "h4"},
    {"id": "version-card", "component": "Card", "child": "version-info"},
    {"id": "version-info", "component": "Column", "children": ["ver-label", "ver-detail", "ver-uptime"]},
    {"id": "ver-label", "component": "Text", "text": "Gateway Status", "variant": "h5"},
    {"id": "ver-detail", "component": "Text", "text": "Version: v2026.2.9 \u2022 Status: Healthy"},
    {"id": "ver-uptime", "component": "Text", "text": "Uptime: 2h 14m \u2022 Agents: 1 active \u2022 Channels: 0 configured"},
    {"id": "actions-card", "component": "Card", "child": "actions-col"},
    {"id": "actions-col", "component": "Column", "children": ["actions-title", "update-btn", "restart-btn", "pair-btn"]},
    {"id": "actions-title", "component": "Text", "text": "Quick Actions", "variant": "h5"},
    {"id": "update-btn", "component": "Button", "child": "update-btn-text", "variant": "primary", "action": {"event": {"name": "update_openclaw"}}},
    {"id": "update-btn-text", "component": "Text", "text": "Check for Updates"},
    {"id": "restart-btn", "component": "Button", "child": "restart-btn-text", "variant": "secondary", "action": {"event": {"name": "restart_openclaw"}}},
    {"id": "restart-btn-text", "component": "Text", "text": "Restart Gateway"},
    {"id": "pair-btn", "component": "Button", "child": "pair-btn-text", "variant": "secondary", "action": {"event": {"name": "pair_device"}}},
    {"id": "pair-btn-text", "component": "Text", "text": "Pair New Device"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // System Vitals (health / status)
  // ---------------------------------------------------------------------------

  static const _healthResponse =
      '''All vitals normal. Your agent is thinking clearly and has full recall.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "health-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "health-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "vitals-card", "indicators-card", "readings-card"]},
    {"id": "title", "component": "Text", "text": "System Vitals", "variant": "h4"},
    {"id": "vitals-card", "component": "Card", "child": "vitals-col"},
    {"id": "vitals-col", "component": "Column", "children": ["vitals-status", "vitals-detail"]},
    {"id": "vitals-status", "component": "Text", "text": "\u2705 Healthy \u2014 All vitals normal across all systems", "variant": "h5"},
    {"id": "vitals-detail", "component": "Text", "text": "Your agent is in Light Thinking mode with Full Recall. All 14 skills are responsive and the gateway has been steady for 2h 14m.", "variant": "body2"},
    {"id": "indicators-card", "component": "Card", "child": "ind-col"},
    {"id": "ind-col", "component": "Column", "children": ["ind-title", "ind-link", "ind-think", "ind-reach", "ind-skill", "ind-ear"]},
    {"id": "ind-title", "component": "Text", "text": "Vital Signs", "variant": "h5"},
    {"id": "ind-link", "component": "Text", "text": "\ud83d\udfe2 Connectivity \u2014 Gateway linked, 12ms response"},
    {"id": "ind-think", "component": "Text", "text": "\ud83d\udfe2 Thinking \u2014 Opus 4.6 ready, light reasoning"},
    {"id": "ind-reach", "component": "Text", "text": "\ud83d\udfe2 Reach \u2014 All channels idle, standing by"},
    {"id": "ind-skill", "component": "Text", "text": "\ud83d\udfe2 Skills \u2014 14 active, 39 available"},
    {"id": "ind-ear", "component": "Text", "text": "\ud83d\udfe2 Listening \u2014 Voice pipeline active"},
    {"id": "readings-card", "component": "Card", "child": "readings-col"},
    {"id": "readings-col", "component": "Column", "children": ["readings-title", "baro-speed", "baro-speed-slider", "baro-memory", "baro-memory-slider", "baro-budget", "baro-budget-slider"]},
    {"id": "readings-title", "component": "Text", "text": "Vital Readings", "variant": "h5"},
    {"id": "baro-speed", "component": "Text", "text": "Response Speed", "variant": "body2"},
    {"id": "baro-speed-slider", "component": "Slider", "label": "Speed", "value": 92, "min": 0, "max": 100},
    {"id": "baro-memory", "component": "Text", "text": "Short-term Memory", "variant": "body2"},
    {"id": "baro-memory-slider", "component": "Slider", "label": "Memory", "value": 85, "min": 0, "max": 100},
    {"id": "baro-budget", "component": "Text", "text": "Budget Remaining", "variant": "body2"},
    {"id": "baro-budget-slider", "component": "Slider", "label": "Budget", "value": 78, "min": 0, "max": 100}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Connect existing gateway
  // ---------------------------------------------------------------------------

  static const _connectGatewayResponse =
      '''I'll help you connect to an existing OpenClaw gateway. Enter your gateway details below.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "connect-gw-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "connect-gw-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "desc", "url-field", "token-field", "connect-btn"]},
    {"id": "title", "component": "Text", "text": "Connect to Gateway", "variant": "h4"},
    {"id": "desc", "component": "Text", "text": "Enter the URL and authentication token for your existing OpenClaw gateway. You can find these in your gateway's dashboard or config file."},
    {"id": "url-field", "component": "TextField", "label": "Gateway URL", "text": "ws://localhost:18789"},
    {"id": "token-field", "component": "TextField", "label": "Gateway Token", "text": ""},
    {"id": "connect-btn", "component": "Button", "child": "connect-btn-text", "variant": "primary", "action": {"event": {"name": "connect_gateway", "context": {"gateway_url": {"path": "url-field.value"}, "gateway_token": {"path": "token-field.value"}}}}},
    {"id": "connect-btn-text", "component": "Text", "text": "Connect"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Setup concierge agent
  // ---------------------------------------------------------------------------

  static const _travelSetupResponse =
      '''Great choice! I've set up your travel concierge with Web Search and Maps tools. Pick a city, persona, and duration to build your itinerary.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "travel-setup-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "travel-setup-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "desc", "city-picker", "persona-picker", "days-picker", "plan-btn"]},
    {"id": "title", "component": "Text", "text": "Travel Concierge", "variant": "h4"},
    {"id": "desc", "component": "Text", "text": "Powered by Opus 4.6 \u2022 Persona-driven itinerary planning with real-time flight and hotel matching."},
    {"id": "city-picker", "component": "ChoicePicker", "label": "Destination", "variant": "mutuallyExclusive", "options": [{"label": "Tokyo", "value": "tokyo"}, {"label": "Paris", "value": "paris"}, {"label": "New York", "value": "new-york"}, {"label": "London", "value": "london"}], "value": ["tokyo"]},
    {"id": "persona-picker", "component": "ChoicePicker", "label": "Travel Persona", "variant": "mutuallyExclusive", "options": [{"label": "Foodie", "value": "foodie"}, {"label": "Artsy", "value": "artsy"}, {"label": "Outdoorsy", "value": "outdoorsy"}, {"label": "Budget", "value": "budget"}], "value": ["foodie"]},
    {"id": "days-picker", "component": "ChoicePicker", "label": "Trip Duration", "variant": "mutuallyExclusive", "options": [{"label": "3 Days", "value": "3"}, {"label": "5 Days", "value": "5"}, {"label": "7 Days", "value": "7"}], "value": ["3"]},
    {"id": "plan-btn", "component": "Button", "child": "plan-btn-text", "variant": "primary", "action": {"event": {"name": "generate_itinerary", "context": {"city": {"path": "city-picker.value"}, "persona": {"path": "persona-picker.value"}, "days": {"path": "days-picker.value"}}}}},
    {"id": "plan-btn-text", "component": "Text", "text": "Generate Itinerary"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Tokyo overview (Foodie default)
  // ---------------------------------------------------------------------------

  static const _tokyoOverviewResponse =
      '''Here's your 3-day Tokyo foodie itinerary! I've matched flights and hotels to your culinary adventure persona.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "tokyo-itin-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "tokyo-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "travel-grid", "day1-card", "day2-card", "day3-card", "persona-switch", "save-btn"]},
    {"id": "title", "component": "Text", "text": "Tokyo \u2014 3 Day Foodie Itinerary", "variant": "h4"},
    {"id": "travel-grid", "component": "ResponsiveContainer", "children": ["flights-card", "hotel-card"]},
    {"id": "flights-card", "component": "Card", "child": "flights-col"},
    {"id": "flights-col", "component": "Column", "children": ["flights-title", "flight1-row", "flight2-row"]},
    {"id": "flights-title", "component": "Text", "text": "Recommended Flights", "variant": "h5"},
    {"id": "flight1-row", "component": "Row", "children": ["f1-info", "f1-btn"]},
    {"id": "f1-info", "component": "Column", "children": ["f1-name", "f1-detail"]},
    {"id": "f1-name", "component": "Text", "text": "JL005 \u2022 JAL", "variant": "h6"},
    {"id": "f1-detail", "component": "Text", "text": "SFO \u2192 NRT \u2022 11h 15m \u2022 \$1,240"},
    {"id": "f1-btn", "component": "Button", "child": "f1-btn-text", "variant": "secondary", "action": {"event": {"name": "book_flight", "context": {"flight": "JL005", "price": 1240}}}},
    {"id": "f1-btn-text", "component": "Text", "text": "Select"},
    {"id": "flight2-row", "component": "Row", "children": ["f2-info", "f2-btn"]},
    {"id": "f2-info", "component": "Column", "children": ["f2-name", "f2-detail"]},
    {"id": "f2-name", "component": "Text", "text": "NH007 \u2022 ANA", "variant": "h6"},
    {"id": "f2-detail", "component": "Text", "text": "SFO \u2192 HND \u2022 11h 30m \u2022 \$1,180"},
    {"id": "f2-btn", "component": "Button", "child": "f2-btn-text", "variant": "secondary", "action": {"event": {"name": "book_flight", "context": {"flight": "NH007", "price": 1180}}}},
    {"id": "f2-btn-text", "component": "Text", "text": "Select"},
    {"id": "hotel-card", "component": "Card", "child": "hotel-col"},
    {"id": "hotel-col", "component": "Column", "children": ["hotel-title", "hotel-img", "hotel-name", "hotel-detail", "hotel-btn"]},
    {"id": "hotel-title", "component": "Text", "text": "Recommended Stay", "variant": "h5"},
    {"id": "hotel-img", "component": "Image", "url": "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&h=400&fit=crop&auto=format", "variant": "header"},
    {"id": "hotel-name", "component": "Text", "text": "Hoshinoya Tokyo \u2022 \u2605\u2605\u2605\u2605\u2605", "variant": "h6"},
    {"id": "hotel-detail", "component": "Text", "text": "Otemachi \u2022 Onsen ryokan in the heart of Tokyo \u2022 \$420/night \u2022 Perfect for foodies: private kaiseki dining"},
    {"id": "hotel-btn", "component": "Button", "child": "hotel-btn-text", "variant": "secondary", "action": {"event": {"name": "browser_open", "context": {"url": "https://hoshinoya.com/tokyo/en/"}}}},
    {"id": "hotel-btn-text", "component": "Text", "text": "View Hotel"},
    {"id": "day1-card", "component": "Card", "child": "day1-col"},
    {"id": "day1-col", "component": "Column", "children": ["day1-title", "day1-am", "day1-lunch", "day1-pm", "day1-dinner"]},
    {"id": "day1-title", "component": "Text", "text": "Day 1 \u2014 Tsukiji & Ginza", "variant": "h5"},
    {"id": "day1-am", "component": "Text", "text": "\ud83c\udf05 Morning: Tsukiji Outer Market \u2014 fresh sushi breakfast at Sushi Dai (arrive 5:30 AM)"},
    {"id": "day1-lunch", "component": "Text", "text": "\u2615 Lunch: Ramen Street at Tokyo Station \u2014 try Rokurinsha's tsukemen"},
    {"id": "day1-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Ginza depachika (department store food halls) \u2014 wagashi tasting"},
    {"id": "day1-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: Sukiyabashi Jiro (Roppongi) \u2014 omakase sushi"},
    {"id": "day2-card", "component": "Card", "child": "day2-col"},
    {"id": "day2-col", "component": "Column", "children": ["day2-title", "day2-am", "day2-lunch", "day2-pm", "day2-dinner"]},
    {"id": "day2-title", "component": "Text", "text": "Day 2 \u2014 Shinjuku & Golden Gai", "variant": "h5"},
    {"id": "day2-am", "component": "Text", "text": "\ud83c\udf05 Morning: Shinjuku Gyoen \u2014 matcha at the tea house"},
    {"id": "day2-lunch", "component": "Text", "text": "\u2615 Lunch: Fuunji \u2014 famous fish-broth tsukemen (expect a 30-min queue)"},
    {"id": "day2-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Takashimaya food hall + Omoide Yokocho yakitori alley"},
    {"id": "day2-dinner", "component": "Text", "text": "\ud83c\udf19 Evening: Golden Gai bar crawl \u2014 6 tiny bars, 6 different sake"},
    {"id": "day3-card", "component": "Card", "child": "day3-col"},
    {"id": "day3-col", "component": "Column", "children": ["day3-title", "day3-am", "day3-lunch", "day3-pm", "day3-dinner"]},
    {"id": "day3-title", "component": "Text", "text": "Day 3 \u2014 Toyosu & Asakusa", "variant": "h5"},
    {"id": "day3-am", "component": "Text", "text": "\ud83c\udf05 Morning: Toyosu Fish Market \u2014 tuna auction viewing deck (reserve online)"},
    {"id": "day3-lunch", "component": "Text", "text": "\u2615 Lunch: Tempura Kondo (Ginza) \u2014 Michelin-starred tempura"},
    {"id": "day3-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Asakusa \u2014 Nakamise-dori street food (melon pan, ningyo-yaki)"},
    {"id": "day3-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: Narisawa \u2014 #12 World's 50 Best, innovative satoyama cuisine"},
    {"id": "persona-switch", "component": "ChoicePicker", "label": "Switch Persona", "variant": "mutuallyExclusive", "options": [{"label": "Foodie", "value": "foodie"}, {"label": "Artsy", "value": "artsy"}, {"label": "Outdoorsy", "value": "outdoorsy"}], "value": ["foodie"], "onSubmit": {"event": {"name": "generate_itinerary", "context": {"city": "tokyo", "persona": {"path": "persona-switch.value"}, "days": "3"}}}},
    {"id": "save-btn", "component": "Button", "child": "save-btn-text", "variant": "primary", "action": {"event": {"name": "save_itin", "context": {"city": "tokyo", "days": 3, "persona": "foodie"}}}},
    {"id": "save-btn-text", "component": "Text", "text": "Save Itinerary"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Tokyo Artistic persona variant
  // ---------------------------------------------------------------------------

  static const _tokyoArtisticResponse =
      '''Switching to the artsy persona! Here's your Tokyo art and culture itinerary.

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "tokyo-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "travel-grid", "day1-card", "day2-card", "day3-card", "persona-switch"]},
    {"id": "title", "component": "Text", "text": "Tokyo \u2014 3 Day Art & Culture Itinerary", "variant": "h4"},
    {"id": "travel-grid", "component": "ResponsiveContainer", "children": ["flights-card", "hotel-card"]},
    {"id": "hotel-img", "component": "Image", "url": "https://images.unsplash.com/photo-1480796927426-f609979314bd?w=800&h=400&fit=crop&auto=format", "variant": "header"},
    {"id": "hotel-name", "component": "Text", "text": "Park Hyatt Tokyo \u2022 \u2605\u2605\u2605\u2605\u2605", "variant": "h6"},
    {"id": "hotel-detail", "component": "Text", "text": "Shinjuku \u2022 Iconic Lost in Translation hotel \u2022 \$380/night \u2022 Perfect for art lovers: views of Mt. Fuji, New York Bar"},
    {"id": "day1-title", "component": "Text", "text": "Day 1 \u2014 Roppongi Art Triangle", "variant": "h5"},
    {"id": "day1-am", "component": "Text", "text": "\ud83c\udf05 Morning: Mori Art Museum \u2014 contemporary exhibits on the 53rd floor"},
    {"id": "day1-lunch", "component": "Text", "text": "\u2615 Lunch: The National Art Center cafe \u2014 Kisho Kurokawa's undulating glass facade"},
    {"id": "day1-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: 21_21 Design Sight \u2014 Tadao Ando's design museum"},
    {"id": "day1-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: d47 Shokudo (Shibuya) \u2014 curated regional Japanese food"},
    {"id": "day2-title", "component": "Text", "text": "Day 2 \u2014 TeamLab & Odaiba", "variant": "h5"},
    {"id": "day2-am", "component": "Text", "text": "\ud83c\udf05 Morning: teamLab Borderless (Azabudai Hills) \u2014 immersive digital art"},
    {"id": "day2-lunch", "component": "Text", "text": "\u2615 Lunch: Bills Odaiba \u2014 ocean-view ricotta hotcakes"},
    {"id": "day2-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Palette Town \u2014 Toyota mega-web + VenusFort architecture"},
    {"id": "day2-dinner", "component": "Text", "text": "\ud83c\udf19 Evening: Shimokitazawa \u2014 indie galleries, vintage shops, live jazz"},
    {"id": "day3-title", "component": "Text", "text": "Day 3 \u2014 Yanaka & Ghibli", "variant": "h5"},
    {"id": "day3-am", "component": "Text", "text": "\ud83c\udf05 Morning: Yanaka district \u2014 gallery alley + SCAI The Bathhouse"},
    {"id": "day3-lunch", "component": "Text", "text": "\u2615 Lunch: Kayaba Coffee \u2014 1916 machiya renovated into a minimalist cafe"},
    {"id": "day3-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Ghibli Museum (Mitaka) \u2014 reserve tickets 1 month ahead"},
    {"id": "day3-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: Florilege (Aoyama) \u2014 #39 World's 50 Best, French-Japanese fusion"},
    {"id": "persona-switch", "component": "ChoicePicker", "label": "Switch Persona", "variant": "mutuallyExclusive", "options": [{"label": "Foodie", "value": "foodie"}, {"label": "Artsy", "value": "artsy"}, {"label": "Outdoorsy", "value": "outdoorsy"}], "value": ["artsy"], "onSubmit": {"event": {"name": "generate_itinerary", "context": {"city": "tokyo", "persona": {"path": "persona-switch.value"}, "days": "3"}}}}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Tokyo Outdoorsy persona variant
  // ---------------------------------------------------------------------------

  static const _tokyoOutdoorsyResponse =
      '''Here's the nature and adventure version! Tokyo has amazing outdoor escapes within day-trip distance.

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "tokyo-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "travel-grid", "day1-card", "day2-card", "day3-card", "persona-switch"]},
    {"id": "title", "component": "Text", "text": "Tokyo \u2014 3 Day Nature & Adventure Itinerary", "variant": "h4"},
    {"id": "travel-grid", "component": "ResponsiveContainer", "children": ["flights-card", "hotel-card"]},
    {"id": "hotel-img", "component": "Image", "url": "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&h=400&fit=crop&auto=format", "variant": "header"},
    {"id": "hotel-name", "component": "Text", "text": "HOSHINOYA Fuji \u2022 \u2605\u2605\u2605\u2605", "variant": "h6"},
    {"id": "hotel-detail", "component": "Text", "text": "Kawaguchiko \u2022 Glamping resort overlooking Mt. Fuji \u2022 \$350/night \u2022 Perfect for outdoors: forest activities, stargazing deck"},
    {"id": "day1-title", "component": "Text", "text": "Day 1 \u2014 Mt. Takao & Meiji Shrine", "variant": "h5"},
    {"id": "day1-am", "component": "Text", "text": "\ud83c\udf05 Morning: Mt. Takao (599m) \u2014 Trail 1 through cedar forests, 90 min to summit"},
    {"id": "day1-lunch", "component": "Text", "text": "\u2615 Lunch: Soba noodles at the summit teahouse \u2014 hand-made with mountain spring water"},
    {"id": "day1-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Meiji Jingu \u2014 100-year-old forest in central Tokyo, 700K trees"},
    {"id": "day1-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: Yoyogi Park sunset picnic \u2014 grab bento from Omotesando delis"},
    {"id": "day2-title", "component": "Text", "text": "Day 2 \u2014 Kamakura Coast", "variant": "h5"},
    {"id": "day2-am", "component": "Text", "text": "\ud83c\udf05 Morning: Enoshima Island \u2014 sea caves + hawk viewpoint (1h train from Shinjuku)"},
    {"id": "day2-lunch", "component": "Text", "text": "\u2615 Lunch: Shirasu (whitebait) rice bowl at Enoshima harbor"},
    {"id": "day2-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Kamakura Great Buddha + Daibutsu hiking trail through bamboo"},
    {"id": "day2-dinner", "component": "Text", "text": "\ud83c\udf19 Evening: Yuigahama Beach sunset + seafood izakaya"},
    {"id": "day3-title", "component": "Text", "text": "Day 3 \u2014 Nikko National Park", "variant": "h5"},
    {"id": "day3-am", "component": "Text", "text": "\ud83c\udf05 Morning: Kegon Falls (97m) \u2014 one of Japan's top 3 waterfalls"},
    {"id": "day3-lunch", "component": "Text", "text": "\u2615 Lunch: Yuba (tofu skin) at Nikko's famous Buddhist restaurants"},
    {"id": "day3-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Lake Chuzenji kayaking + Senjogahara marshland boardwalk"},
    {"id": "day3-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: Onsen ryokan kaiseki \u2014 soak in volcanic hot springs after a full day"},
    {"id": "persona-switch", "component": "ChoicePicker", "label": "Switch Persona", "variant": "mutuallyExclusive", "options": [{"label": "Foodie", "value": "foodie"}, {"label": "Artsy", "value": "artsy"}, {"label": "Outdoorsy", "value": "outdoorsy"}], "value": ["outdoorsy"], "onSubmit": {"event": {"name": "generate_itinerary", "context": {"city": "tokyo", "persona": {"path": "persona-switch.value"}, "days": "3"}}}}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Trip Planning Demo: Agent creation
  // ---------------------------------------------------------------------------

  static const _createTripAgentResponse =
      '''Great! I'll set up a Trip Planner agent powered by Opus 4.6 with flight search, hotel booking, and itinerary planning skills.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "trip-agent-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "trip-agent-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "desc", "name-field", "model-picker", "skills-picker", "create-btn"]},
    {"id": "title", "component": "Text", "text": "Create Trip Planner Agent", "variant": "h4"},
    {"id": "desc", "component": "Text", "text": "Configure your AI travel assistant with specialized planning skills."},
    {"id": "name-field", "component": "TextField", "label": "Agent Name", "text": "Trip Planner"},
    {"id": "model-picker", "component": "ChoicePicker", "label": "AI Model", "variant": "mutuallyExclusive", "options": [{"label": "Claude Opus 4.6", "value": "claude-opus-4-6"}, {"label": "Claude Sonnet 4.5", "value": "claude-sonnet-4-5"}], "value": ["claude-opus-4-6"]},
    {"id": "skills-picker", "component": "ChoicePicker", "label": "Skills", "variant": "multipleSelection", "options": [{"label": "Flight Search", "value": "flights"}, {"label": "Hotel Booking", "value": "hotels"}, {"label": "Itinerary Planning", "value": "itinerary"}, {"label": "Weather Lookup", "value": "weather"}, {"label": "Restaurant Finder", "value": "restaurants"}], "value": ["flights", "hotels", "itinerary"]},
    {"id": "create-btn", "component": "Button", "child": "create-btn-text", "variant": "primary", "action": {"event": {"name": "save_agent", "context": {"name": {"path": "name-field.value"}, "model": {"path": "model-picker.value"}, "skills": {"path": "skills-picker.value"}}}}},
    {"id": "create-btn-text", "component": "Text", "text": "Create Agent"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Trip Planning Demo: 3-day Tokyo itinerary
  // ---------------------------------------------------------------------------

  static const _tripTokyoItineraryResponse =
      '''Here's your 3-day Tokyo itinerary! I've planned a mix of culture, food, and exploration with an estimated budget of \u00a5150,000 (~\$1,000).

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "trip-itin-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "trip-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "budget-card", "day1-card", "day2-card", "day3-card"]},
    {"id": "title", "component": "Text", "text": "Tokyo \u2014 3 Day Itinerary", "variant": "h4"},
    {"id": "budget-card", "component": "Card", "child": "budget-col"},
    {"id": "budget-col", "component": "Column", "children": ["budget-title", "budget-detail"]},
    {"id": "budget-title", "component": "Text", "text": "Estimated Budget: \u00a5150,000", "variant": "h5"},
    {"id": "budget-detail", "component": "Text", "text": "Accommodation \u00a545,000 \u2022 Food \u00a530,000 \u2022 Transport \u00a515,000 \u2022 Activities \u00a520,000 \u2022 Shopping \u00a540,000"},
    {"id": "day1-card", "component": "Card", "child": "day1-col"},
    {"id": "day1-col", "component": "Column", "children": ["day1-title", "day1-am", "day1-mid", "day1-pm", "day1-dinner"]},
    {"id": "day1-title", "component": "Text", "text": "Day 1 \u2014 Shibuya & Harajuku", "variant": "h5"},
    {"id": "day1-am", "component": "Text", "text": "\ud83c\udf05 Morning: Meiji Shrine \u2014 serene forest walk in the heart of Tokyo"},
    {"id": "day1-mid", "component": "Text", "text": "\ud83d\udecd Midday: Takeshita Street \u2014 Harajuku fashion, crepes, and street culture"},
    {"id": "day1-pm", "component": "Text", "text": "\ud83c\udf06 Afternoon: Shibuya Crossing \u2014 world's busiest intersection, Hachiko statue"},
    {"id": "day1-dinner", "component": "Text", "text": "\ud83c\udf5c Dinner: Fuunji Ramen \u2014 famous tsukemen near Shinjuku Station"},
    {"id": "day2-card", "component": "Card", "child": "day2-col"},
    {"id": "day2-col", "component": "Column", "children": ["day2-title", "day2-am", "day2-mid", "day2-pm", "day2-dinner"]},
    {"id": "day2-title", "component": "Text", "text": "Day 2 \u2014 Asakusa & Akihabara", "variant": "h5"},
    {"id": "day2-am", "component": "Text", "text": "\u26e9 Morning: Senso-ji Temple \u2014 Tokyo's oldest temple, Thunder Gate"},
    {"id": "day2-mid", "component": "Text", "text": "\ud83c\udfed Midday: Nakamise Shopping Street \u2014 traditional snacks and souvenirs"},
    {"id": "day2-pm", "component": "Text", "text": "\ud83d\udd0c Afternoon: Akihabara \u2014 electronics, anime, and gaming paradise"},
    {"id": "day2-dinner", "component": "Text", "text": "\ud83c\udf76 Dinner: Izakaya hopping \u2014 yakitori and sake under the rail tracks"},
    {"id": "day3-card", "component": "Card", "child": "day3-col"},
    {"id": "day3-col", "component": "Column", "children": ["day3-title", "day3-am", "day3-mid", "day3-pm", "day3-depart"]},
    {"id": "day3-title", "component": "Text", "text": "Day 3 \u2014 Shinjuku & Departure", "variant": "h5"},
    {"id": "day3-am", "component": "Text", "text": "\ud83c\udf38 Morning: Shinjuku Gyoen Park \u2014 beautiful gardens, perfect for a morning stroll"},
    {"id": "day3-mid", "component": "Text", "text": "\ud83d\uddfc Midday: Tokyo Tower \u2014 panoramic city views from the observation deck"},
    {"id": "day3-pm", "component": "Text", "text": "\ud83c\udf63 Afternoon: Tsukiji Outer Market \u2014 fresh sushi and street food for lunch"},
    {"id": "day3-depart", "component": "Text", "text": "\u2708\ufe0f Evening: Depart from Narita/Haneda \u2014 pick up last-minute souvenirs at the airport"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Trip Planning Demo: Add sushi class to Day 2
  // ---------------------------------------------------------------------------

  static const _sushiClassResponse =
      '''Done! I've added a Sushi Making Class to Day 2. The updated itinerary now includes the class between Nakamise and Akihabara.

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "trip-itin-001", "components": [
    {"id": "day2-col", "component": "Column", "children": ["day2-title", "day2-am", "day2-mid", "day2-sushi", "day2-pm", "day2-dinner"]},
    {"id": "day2-title", "component": "Text", "text": "Day 2 \u2014 Asakusa & Akihabara (Updated)", "variant": "h5"},
    {"id": "day2-am", "component": "Text", "text": "\u26e9 Morning: Senso-ji Temple \u2014 Tokyo's oldest temple, Thunder Gate"},
    {"id": "day2-mid", "component": "Text", "text": "\ud83c\udfed Midday: Nakamise Shopping Street \u2014 traditional snacks and souvenirs"},
    {"id": "day2-sushi", "component": "Text", "text": "\ud83c\udf63 NEW: Sushi Making Class \u2014 Learn to make nigiri and maki from a master chef (2 hours, \u00a58,000)"},
    {"id": "day2-pm", "component": "Text", "text": "\ud83d\udd0c Afternoon: Akihabara \u2014 electronics, anime, and gaming paradise"},
    {"id": "day2-dinner", "component": "Text", "text": "\ud83c\udf76 Dinner: Izakaya hopping \u2014 yakitori and sake under the rail tracks"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Trip Planning Demo: Tokyo weather
  // ---------------------------------------------------------------------------

  static const _tokyoWeatherResponse =
      '''Here's the current weather in Tokyo \u2014 great conditions for sightseeing!

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "weather-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "weather-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "weather-card", "forecast-card", "tip"]},
    {"id": "title", "component": "Text", "text": "Tokyo Weather", "variant": "h4"},
    {"id": "weather-card", "component": "Card", "child": "weather-col"},
    {"id": "weather-col", "component": "Column", "children": ["temp", "condition", "details"]},
    {"id": "temp", "component": "Text", "text": "15\u00b0C / 59\u00b0F", "variant": "h4"},
    {"id": "condition", "component": "Text", "text": "\u26c5 Partly Cloudy", "variant": "h6"},
    {"id": "details", "component": "Text", "text": "Humidity: 62% \u2022 Wind: 8 km/h NW \u2022 UV Index: 3 (Moderate)"},
    {"id": "forecast-card", "component": "Card", "child": "forecast-col"},
    {"id": "forecast-col", "component": "Column", "children": ["forecast-title", "fc-1", "fc-2", "fc-3"]},
    {"id": "forecast-title", "component": "Text", "text": "3-Day Forecast", "variant": "h6"},
    {"id": "fc-1", "component": "Text", "text": "Tomorrow: 17\u00b0C \u2600\ufe0f Sunny \u2014 Perfect for outdoor sightseeing"},
    {"id": "fc-2", "component": "Text", "text": "Day 3: 14\u00b0C \ud83c\udf27\ufe0f Light Rain \u2014 Bring an umbrella, great for museums"},
    {"id": "fc-3", "component": "Text", "text": "Day 4: 16\u00b0C \u26c5 Partly Cloudy \u2014 Good conditions overall"},
    {"id": "tip", "component": "Text", "text": "\ud83d\udca1 Tip: Layer up! Tokyo mornings can be cool but afternoons warm up. Perfect weather for walking tours.", "variant": "body2"}
  ]}}
]
```''';
}
