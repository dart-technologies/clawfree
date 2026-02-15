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
    final textPart = fenceIndex >= 0
        ? response.substring(0, fenceIndex)
        : response;
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
    // Self-correction prompts
    if (lower.contains('could not be parsed') ||
        lower.contains('please regenerate')) {
      return 'Let me try a different approach. What would you like to do?';
    }

    // WORKFLOW 1: Agent Creation Alignment
    if (lower.contains('create') && lower.contains('travel')) {
      return _createTravelAgentResponse;
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
    // Travel: all initial requests → vibe picker
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
    // Agent detail (specific agent — check before broad "show")
    'travel concierge': _travelConciergeDetailResponse,
    // Dashboard / agent list
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
    '_default':
        'I understand! Let me help you with that. '
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
    {
      'name': 'Telegram Bridge',
      'desc': 'Send and receive messages via Telegram Bot API',
      'cat': 'Communication',
      'icon': 'mail',
      'auto': false,
    },
    {
      'name': 'Slack Connector',
      'desc': 'Post messages, manage channels, and respond to Slack events',
      'cat': 'Communication',
      'icon': 'mail',
      'auto': false,
    },
    {
      'name': 'Discord Bot',
      'desc': 'Discord guild management with slash commands and reactions',
      'cat': 'Communication',
      'icon': 'mail',
      'auto': false,
    },
    {
      'name': 'Email Gateway',
      'desc': 'Send, receive, and filter emails via SMTP/IMAP',
      'cat': 'Communication',
      'icon': 'mail',
      'auto': false,
    },
    {
      'name': 'SMS Router',
      'desc': 'Route SMS messages through Twilio or Vonage',
      'cat': 'Communication',
      'icon': 'mail',
      'auto': false,
    },
    {
      'name': 'Webhook Relay',
      'desc': 'Forward and transform incoming webhooks between services',
      'cat': 'Communication',
      'icon': 'mail',
      'auto': true,
    },
    {
      'name': 'Push Notifier',
      'desc': 'Send push notifications to iOS, Android, and web clients',
      'cat': 'Communication',
      'icon': 'mail',
      'auto': false,
    },
    // Data & Analytics (7)
    {
      'name': 'API Connector',
      'desc': 'Universal REST/GraphQL client with auth and retry logic',
      'cat': 'Data & Analytics',
      'icon': 'search',
      'auto': true,
    },
    {
      'name': 'CSV/JSON Parser',
      'desc': 'Parse, validate, and transform CSV and JSON data streams',
      'cat': 'Data & Analytics',
      'icon': 'search',
      'auto': true,
    },
    {
      'name': 'SQL Query Engine',
      'desc': 'Execute read-only SQL queries against Postgres and MySQL',
      'cat': 'Data & Analytics',
      'icon': 'search',
      'auto': false,
    },
    {
      'name': 'Data Transformer',
      'desc': 'Map, filter, and reshape data between formats',
      'cat': 'Data & Analytics',
      'icon': 'search',
      'auto': false,
    },
    {
      'name': 'Chart Generator',
      'desc': 'Create bar, line, and pie charts from data series',
      'cat': 'Data & Analytics',
      'icon': 'search',
      'auto': false,
    },
    {
      'name': 'Report Builder',
      'desc': 'Generate PDF and HTML reports from templates',
      'cat': 'Data & Analytics',
      'icon': 'search',
      'auto': false,
    },
    {
      'name': 'Stream Processor',
      'desc': 'Process real-time event streams with windowing and aggregation',
      'cat': 'Data & Analytics',
      'icon': 'search',
      'auto': false,
    },
    // Development (7)
    {
      'name': 'Package Auditor',
      'desc': 'Scan dependencies for known vulnerabilities and license issues',
      'cat': 'Development',
      'icon': 'settings',
      'auto': true,
    },
    {
      'name': 'Git Watcher',
      'desc': 'Monitor repositories for commits, PRs, and branch changes',
      'cat': 'Development',
      'icon': 'settings',
      'auto': false,
    },
    {
      'name': 'CI/CD Trigger',
      'desc': 'Trigger and monitor CI/CD pipelines across providers',
      'cat': 'Development',
      'icon': 'settings',
      'auto': false,
    },
    {
      'name': 'Code Formatter',
      'desc': 'Auto-format code in 20+ languages on commit or save',
      'cat': 'Development',
      'icon': 'settings',
      'auto': false,
    },
    {
      'name': 'Dep Scanner',
      'desc': 'Detect outdated dependencies and suggest upgrade paths',
      'cat': 'Development',
      'icon': 'settings',
      'auto': false,
    },
    {
      'name': 'Test Runner',
      'desc': 'Execute and report test suites with parallel execution',
      'cat': 'Development',
      'icon': 'settings',
      'auto': false,
    },
    {
      'name': 'Linter',
      'desc': 'Run static analysis rules across project files',
      'cat': 'Development',
      'icon': 'settings',
      'auto': false,
    },
    // Security (6)
    {
      'name': 'Secret Scanner',
      'desc': 'Detect leaked API keys, tokens, and credentials in code',
      'cat': 'Security',
      'icon': 'lock',
      'auto': true,
    },
    {
      'name': 'Cert Monitor',
      'desc': 'Track TLS certificate expiry and auto-renew via ACME',
      'cat': 'Security',
      'icon': 'lock',
      'auto': true,
    },
    {
      'name': 'Access Controller',
      'desc': 'Role-based access control for agents and resources',
      'cat': 'Security',
      'icon': 'lock',
      'auto': false,
    },
    {
      'name': 'Threat Detector',
      'desc': 'Analyze request patterns for anomalies and attacks',
      'cat': 'Security',
      'icon': 'lock',
      'auto': false,
    },
    {
      'name': 'Vuln Scanner',
      'desc': 'Scan infrastructure and containers for known CVEs',
      'cat': 'Security',
      'icon': 'lock',
      'auto': false,
    },
    {
      'name': 'Token Rotator',
      'desc': 'Automatically rotate API keys and secrets on schedule',
      'cat': 'Security',
      'icon': 'lock',
      'auto': false,
    },
    // AI & ML (6)
    {
      'name': 'Prompt Router',
      'desc': 'Route prompts to optimal models based on complexity and cost',
      'cat': 'AI & ML',
      'icon': 'star',
      'auto': true,
    },
    {
      'name': 'Model Switcher',
      'desc': 'Hot-swap between LLM providers without downtime',
      'cat': 'AI & ML',
      'icon': 'star',
      'auto': false,
    },
    {
      'name': 'Embedding Store',
      'desc': 'Store and query vector embeddings for semantic search',
      'cat': 'AI & ML',
      'icon': 'star',
      'auto': false,
    },
    {
      'name': 'Classifier',
      'desc': 'Classify text into categories using fine-tuned models',
      'cat': 'AI & ML',
      'icon': 'star',
      'auto': false,
    },
    {
      'name': 'Summarizer',
      'desc': 'Generate concise summaries of long documents and threads',
      'cat': 'AI & ML',
      'icon': 'star',
      'auto': false,
    },
    {
      'name': 'RAG Pipeline',
      'desc': 'Retrieval-augmented generation with document chunking',
      'cat': 'AI & ML',
      'icon': 'star',
      'auto': false,
    },
    // Infrastructure (6)
    {
      'name': 'Health Monitor',
      'desc': 'Poll endpoints and report uptime with alerting',
      'cat': 'Infrastructure',
      'icon': 'visibility',
      'auto': true,
    },
    {
      'name': 'Log Aggregator',
      'desc': 'Collect, index, and search logs from all services',
      'cat': 'Infrastructure',
      'icon': 'visibility',
      'auto': false,
    },
    {
      'name': 'Container Manager',
      'desc': 'Start, stop, and scale Docker containers remotely',
      'cat': 'Infrastructure',
      'icon': 'visibility',
      'auto': false,
    },
    {
      'name': 'DNS Resolver',
      'desc': 'Manage DNS records and propagation checking',
      'cat': 'Infrastructure',
      'icon': 'visibility',
      'auto': false,
    },
    {
      'name': 'Load Balancer',
      'desc': 'Distribute traffic across backend instances',
      'cat': 'Infrastructure',
      'icon': 'visibility',
      'auto': false,
    },
    {
      'name': 'Backup Scheduler',
      'desc': 'Schedule and verify automated backups',
      'cat': 'Infrastructure',
      'icon': 'visibility',
      'auto': false,
    },
    // Productivity (5)
    {
      'name': 'Doc Summarizer',
      'desc': 'Summarize documents, emails, and meeting transcripts',
      'cat': 'Productivity',
      'icon': 'check',
      'auto': true,
    },
    {
      'name': 'Calendar Sync',
      'desc': 'Sync events across Google, Outlook, and Apple calendars',
      'cat': 'Productivity',
      'icon': 'check',
      'auto': false,
    },
    {
      'name': 'Task Tracker',
      'desc': 'Create and manage tasks in Jira, Linear, and Asana',
      'cat': 'Productivity',
      'icon': 'check',
      'auto': false,
    },
    {
      'name': 'Note Taker',
      'desc': 'Capture and organize meeting notes with action items',
      'cat': 'Productivity',
      'icon': 'check',
      'auto': false,
    },
    {
      'name': 'Reminder Service',
      'desc': 'Schedule and deliver time-based and location-based reminders',
      'cat': 'Productivity',
      'icon': 'check',
      'auto': false,
    },
    // Media & Content (5)
    {
      'name': 'Content Moderator',
      'desc': 'Filter and flag inappropriate text and image content',
      'cat': 'Media & Content',
      'icon': 'download',
      'auto': true,
    },
    {
      'name': 'Markdown Renderer',
      'desc': 'Convert Markdown to HTML, PDF, and rich text',
      'cat': 'Media & Content',
      'icon': 'download',
      'auto': true,
    },
    {
      'name': 'Image Optimizer',
      'desc': 'Resize, compress, and convert images for web and mobile',
      'cat': 'Media & Content',
      'icon': 'download',
      'auto': false,
    },
    {
      'name': 'PDF Generator',
      'desc': 'Create PDFs from templates with dynamic data binding',
      'cat': 'Media & Content',
      'icon': 'download',
      'auto': false,
    },
    {
      'name': 'Media Transcoder',
      'desc': 'Convert audio and video between formats and bitrates',
      'cat': 'Media & Content',
      'icon': 'download',
      'auto': false,
    },
    // System & Core (4, all auto)
    {
      'name': 'Registry',
      'desc': 'Central service registry for skill discovery and routing',
      'cat': 'System & Core',
      'icon': 'home',
      'auto': true,
    },
    {
      'name': 'Event Bus',
      'desc': 'Publish-subscribe event bus for inter-skill communication',
      'cat': 'System & Core',
      'icon': 'home',
      'auto': true,
    },
    {
      'name': 'Rate Limiter',
      'desc': 'Enforce per-agent and per-skill rate limits',
      'cat': 'System & Core',
      'icon': 'home',
      'auto': true,
    },
    {
      'name': 'Audit Logger',
      'desc': 'Immutable audit trail for all system actions',
      'cat': 'System & Core',
      'icon': 'home',
      'auto': true,
    },
  ];

  /// Build the Skill Library A2UI JSON programmatically from [_skillData].
  ///
  /// Uses a flat scrollable layout with category headers + card grids
  /// instead of Tabs (which had state-cycling instability in genUI).
  static String get _skillLibraryResponse {
    // Group skills by category preserving insertion order.
    final categories = <String, List<Map<String, dynamic>>>{};
    for (final s in _skillData) {
      (categories[s['cat'] as String] ??= []).add(s);
    }

    final allComponents = <Map<String, dynamic>>[];
    final sectionIds = <String>[];
    var idx = 0;

    for (final entry in categories.entries) {
      final cat = entry.key;
      final skills = entry.value;
      final catId =
          'cat-${cat.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}';

      // Category header
      final headerId = '$catId-hdr';
      final countText = '${skills.length} SKILL${skills.length > 1 ? "S" : ""}';
      allComponents.add({
        'id': headerId,
        'component': 'Text', 'variant': 'h5',
        'text': '${cat.toUpperCase()} \u2022 $countText',
        'fontSize': 10,
        'letterSpacing': 1.5,
        'color': '#66AAFF',
      });
      sectionIds.add(headerId);

      // Grid of skill cards
      final gridId = '$catId-grid';
      final cardIds = <String>[];

      for (final skill in skills) {
        final sid = 'sk-$idx';
        final autoMark = (skill['auto'] as bool) ? '\u2705 Auto' : '';
        cardIds.add('$sid-card');
        allComponents.addAll([
          {'id': '$sid-card', 'component': 'Card', 'child': '$sid-col'},
          {
            'id': '$sid-col',
            'component': 'Column',
            'children': [
              '$sid-name',
              '$sid-desc',
              if (autoMark.isNotEmpty) '$sid-auto',
            ],
          },
          {
            'id': '$sid-name',
            'component': 'Text', 'variant': 'body',
            'text': (skill['name'] as String).toUpperCase(),
            'fontSize': 10,
            'fontWeight': 700,
            'letterSpacing': 0.5,
          },
          {
            'id': '$sid-desc',
            'component': 'Text',
            'text': skill['desc'],
            'variant': 'body2',
          },
          if (autoMark.isNotEmpty)
            {
              'id': '$sid-auto',
              'component': 'Text',
              'text': autoMark,
              'variant': 'caption',
            },
        ]);
        idx++;
      }

      allComponents.add({
        'id': gridId,
        'component': 'ResponsiveContainer',
        'columns': 3,
        'mobileColumns': 1,
        'children': cardIds,
      });
      sectionIds.add(gridId);

      // Spacer between categories
      final gapId = '$catId-gap';
      allComponents.add({'id': gapId, 'component': 'Gap', 'height': 12});
      sectionIds.add(gapId);
    }

    // Root column: header + all category sections (flat, no Tabs).
    allComponents.addAll([
      {
        'id': 'root',
        'component': 'Column',
        'children': ['header-tt', 'gap-top', ...sectionIds],
      },
      {
        'id': 'header-tt',
        'component': 'ItineraryHeader',
        'title': 'SKILL LIBRARY',
        'subtitle': '53 SKILLS \u2022 9 CATEGORIES \u2022 14 ACTIVE',
        'vibe': 'SYSTEM',
        'status': 'READY',
      },
      {'id': 'gap-top', 'component': 'Gap', 'height': 16},
    ]);

    // Encode JSON.
    final surface = [
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'skill-library-001',
          'catalogId': _catalogId,
        },
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'skill-library-001',
          'components': allComponents,
        },
      },
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
      sb.write(
        value
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\n', '\\n'),
      );
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
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-1", "filter", "gap-2", "log-list"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "SYSTEM AUDIT TRAIL", "subtitle": "REAL-TIME MISSION ACTIVITY LOG", "vibe": "ADMIN", "status": "NOMINAL"},
    {"id": "gap-1", "component": "Gap", "height": 16},
    {"id": "filter", "component": "ChoicePicker", "label": "FILTER TRAIL", "variant": "mutuallyExclusive", "options": [{"label": "All", "value": "all"}, {"label": "Agents", "value": "agents"}, {"label": "System", "value": "system"}, {"label": "Security", "value": "security"}], "value": ["all"]},
    {"id": "gap-2", "component": "Gap", "height": 16},
    {"id": "log-list", "component": "Column", "children": ["log-1", "log-2", "log-3", "log-4", "log-5", "log-6", "log-7", "log-8"]},
    {"id": "log-1", "component": "Card", "child": "log-1-row"},
    {"id": "log-1-row", "component": "Row", "children": ["log-1-icon", "log-1-info"]},
    {"id": "log-1-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-1-info", "component": "Column", "children": ["log-1-title", "log-1-time"]},
    {"id": "log-1-title", "component": "Text", "text": "Agent 'GitDigest Bot' deployed successfully", "variant": "body"},
    {"id": "log-1-time", "component": "Text", "text": "2 min ago \u2022 Agent", "variant": "caption"},
    {"id": "log-2", "component": "Card", "child": "log-2-row"},
    {"id": "log-2-row", "component": "Row", "children": ["log-2-icon", "log-2-info"]},
    {"id": "log-2-icon", "component": "Icon", "icon": "lock", "size": "small"},
    {"id": "log-2-info", "component": "Column", "children": ["log-2-title", "log-2-time"]},
    {"id": "log-2-title", "component": "Text", "text": "API key rotated for Anthropic provider", "variant": "body"},
    {"id": "log-2-time", "component": "Text", "text": "8 min ago \u2022 Security", "variant": "caption"},
    {"id": "log-3", "component": "Card", "child": "log-3-row"},
    {"id": "log-3-row", "component": "Row", "children": ["log-3-icon", "log-3-info"]},
    {"id": "log-3-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-3-info", "component": "Column", "children": ["log-3-title", "log-3-time"]},
    {"id": "log-3-title", "component": "Text", "text": "Health check passed \u2014 all services nominal", "variant": "body"},
    {"id": "log-3-time", "component": "Text", "text": "15 min ago \u2022 System", "variant": "caption"},
    {"id": "log-4", "component": "Card", "child": "log-4-row"},
    {"id": "log-4-row", "component": "Row", "children": ["log-4-icon", "log-4-info"]},
    {"id": "log-4-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "log-4-info", "component": "Column", "children": ["log-4-title", "log-4-time"]},
    {"id": "log-4-title", "component": "Text", "text": "Rate limit threshold reached for Slack Connector", "variant": "body"},
    {"id": "log-4-time", "component": "Text", "text": "22 min ago \u2022 Agent", "variant": "caption"},
    {"id": "log-5", "component": "Card", "child": "log-5-row"},
    {"id": "log-5-row", "component": "Row", "children": ["log-5-icon", "log-5-info"]},
    {"id": "log-5-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-5-info", "component": "Column", "children": ["log-5-title", "log-5-time"]},
    {"id": "log-5-title", "component": "Text", "text": "Skill 'Secret Scanner' completed sweep \u2014 0 findings", "variant": "body"},
    {"id": "log-5-time", "component": "Text", "text": "31 min ago \u2022 Security", "variant": "caption"},
    {"id": "log-6", "component": "Card", "child": "log-6-row"},
    {"id": "log-6-row", "component": "Row", "children": ["log-6-icon", "log-6-info"]},
    {"id": "log-6-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "log-6-info", "component": "Column", "children": ["log-6-title", "log-6-time"]},
    {"id": "log-6-title", "component": "Text", "text": "Gateway upgraded to v2026.2.9", "variant": "body"},
    {"id": "log-6-time", "component": "Text", "text": "1h ago \u2022 System", "variant": "caption"},
    {"id": "log-7", "component": "Card", "child": "log-7-row"},
    {"id": "log-7-row", "component": "Row", "children": ["log-7-icon", "log-7-info"]},
    {"id": "log-7-icon", "component": "Icon", "icon": "lock", "size": "small"},
    {"id": "log-7-info", "component": "Column", "children": ["log-7-title", "log-7-time"]},
    {"id": "log-7-title", "component": "Text", "text": "New device paired via QR code", "variant": "body"},
    {"id": "log-7-time", "component": "Text", "text": "1h 15m ago \u2022 Security", "variant": "caption"},
    {"id": "log-8", "component": "Card", "child": "log-8-row"},
    {"id": "log-8-row", "component": "Row", "children": ["log-8-icon", "log-8-info"]},
    {"id": "log-8-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "log-8-info", "component": "Column", "children": ["log-8-title", "log-8-time"]},
    {"id": "log-8-title", "component": "Text", "text": "TLS certificate for api.example.com expires in 14 days", "variant": "body"},
    {"id": "log-8-time", "component": "Text", "text": "2h ago \u2022 Security", "variant": "caption"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Performance Analytics
  // ---------------------------------------------------------------------------

  static const _analyticsResponse =
      '''Telemetry grid online. All systems performing within nominal parameters.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "analytics-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "analytics-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "stats-grid", "gap-1", "agents-card", "gap-2", "skills-card", "gap-3", "fuel-card", "gap-4", "action-tray"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "TELEMETRY GRID", "subtitle": "REAL-TIME PERFORMANCE ANALYTICS", "vibe": "ADMIN", "status": "NOMINAL"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "stats-grid", "component": "ResponsiveContainer", "columns": 4, "mobileColumns": 2, "children": ["speed-pill", "memory-pill", "rel-pill", "fleet-pill"]},

    {"id": "speed-pill", "component": "Card", "child": "speed-col"},
    {"id": "speed-col", "component": "Column", "children": ["speed-val-tt", "speed-spark", "speed-label-tt"]},
    {"id": "speed-val-tt", "component": "Text", "variant": "h5", "text": "88ms", "fontSize": 16, "fontWeight": 800, "color": "#00FF88"},
    {"id": "speed-spark", "component": "HealthSparkline", "level": "nominal", "width": 80, "height": 16, "showGlow": true, "dataPoints": [0.7, 0.8, 0.75, 0.85, 0.9, 0.88, 0.82, 0.88]},
    {"id": "speed-label-tt", "component": "Text", "variant": "caption", "text": "AVG RESPONSE", "fontSize": 8, "color": "#888888"},

    {"id": "memory-pill", "component": "Card", "child": "mem-col"},
    {"id": "mem-col", "component": "Column", "children": ["mem-val-tt", "mem-spark", "mem-label-tt"]},
    {"id": "mem-val-tt", "component": "Text", "variant": "h5", "text": "85%", "fontSize": 16, "fontWeight": 800, "color": "#66AAFF"},
    {"id": "mem-spark", "component": "HealthSparkline", "level": "nominal", "width": 80, "height": 16, "showGlow": true, "dataPoints": [0.8, 0.82, 0.84, 0.85, 0.83, 0.85, 0.86, 0.85]},
    {"id": "mem-label-tt", "component": "Text", "variant": "caption", "text": "MEMORY RECALL", "fontSize": 8, "color": "#888888"},

    {"id": "rel-pill", "component": "Card", "child": "rel-col"},
    {"id": "rel-col", "component": "Column", "children": ["rel-val-tt", "rel-spark", "rel-label-tt"]},
    {"id": "rel-val-tt", "component": "Text", "variant": "h5", "text": "99.2%", "fontSize": 16, "fontWeight": 800, "color": "#00FF88"},
    {"id": "rel-spark", "component": "HealthSparkline", "level": "nominal", "width": 80, "height": 16, "showGlow": true},
    {"id": "rel-label-tt", "component": "Text", "variant": "caption", "text": "RELIABILITY", "fontSize": 8, "color": "#888888"},

    {"id": "fleet-pill", "component": "Card", "child": "fleet-col"},
    {"id": "fleet-col", "component": "Column", "children": ["fleet-val-tt", "fleet-spark", "fleet-label-tt"]},
    {"id": "fleet-val-tt", "component": "Text", "variant": "h5", "text": "3/3", "fontSize": 16, "fontWeight": 800, "color": "#00FF88"},
    {"id": "fleet-spark", "component": "HealthSparkline", "level": "nominal", "width": 80, "height": 16, "showGlow": true},
    {"id": "fleet-label-tt", "component": "Text", "variant": "caption", "text": "FLEET ONLINE", "fontSize": 8, "color": "#888888"},

    {"id": "gap-1", "component": "Gap", "height": 8},

    {"id": "agents-card", "component": "Card", "child": "agents-col"},
    {"id": "agents-col", "component": "Column", "children": ["agents-tt", "ag1-row", "ag2-row", "ag3-row"]},
    {"id": "agents-tt", "component": "Text", "variant": "h5", "text": "PER-AGENT TELEMETRY", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "ag1-row", "component": "Row", "children": ["ag1-spark", "ag1-name", "ag1-latency", "ag1-reqs"]},
    {"id": "ag1-spark", "component": "HealthSparkline", "level": "nominal", "width": 48, "height": 18, "showGlow": true},
    {"id": "ag1-name", "component": "Text", "variant": "body", "text": "GITDIGEST BOT", "fontSize": 9, "color": "#00FF88"},
    {"id": "ag1-latency", "component": "Text", "variant": "body", "text": "98ms", "fontSize": 9, "color": "#00FF88"},
    {"id": "ag1-reqs", "component": "Text", "variant": "caption", "text": "1,247 REQ/24H", "fontSize": 9, "color": "#888888"},
    {"id": "ag2-row", "component": "Row", "children": ["ag2-spark", "ag2-name", "ag2-latency", "ag2-reqs"]},
    {"id": "ag2-spark", "component": "HealthSparkline", "level": "nominal", "width": 48, "height": 18, "showGlow": true},
    {"id": "ag2-name", "component": "Text", "variant": "body", "text": "SLACK MONITOR", "fontSize": 9, "color": "#00FF88"},
    {"id": "ag2-latency", "component": "Text", "variant": "body", "text": "156ms", "fontSize": 9, "color": "#00FF88"},
    {"id": "ag2-reqs", "component": "Text", "variant": "caption", "text": "2,023 REQ/24H", "fontSize": 9, "color": "#888888"},
    {"id": "ag3-row", "component": "Row", "children": ["ag3-spark", "ag3-name", "ag3-latency", "ag3-reqs"]},
    {"id": "ag3-spark", "component": "HealthSparkline", "level": "degraded", "width": 48, "height": 18, "showGlow": true},
    {"id": "ag3-name", "component": "Text", "variant": "body", "text": "DATA PIPELINE", "fontSize": 9, "color": "#FFAA00"},
    {"id": "ag3-latency", "component": "Text", "variant": "body", "text": "203ms", "fontSize": 9, "color": "#FFAA00"},
    {"id": "ag3-reqs", "component": "Text", "variant": "caption", "text": "2,347 REQ/24H", "fontSize": 9, "color": "#888888"},

    {"id": "gap-2", "component": "Gap", "height": 8},

    {"id": "skills-card", "component": "Card", "child": "skills-col"},
    {"id": "skills-col", "component": "Column", "children": ["skills-tt", "sk1-row", "sk2-row", "sk3-row", "sk4-row", "sk5-row"]},
    {"id": "skills-tt", "component": "Text", "variant": "h5", "text": "TOP SKILLS BY THROUGHPUT", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "sk1-row", "component": "Row", "children": ["sk1-name", "sk1-ops", "sk1-avg"]},
    {"id": "sk1-name", "component": "Text", "variant": "body", "text": "RATE LIMITER", "fontSize": 9, "color": "#00FF88"},
    {"id": "sk1-ops", "component": "Text", "variant": "body", "text": "2,847 OPS", "fontSize": 9, "color": "#00FF88"},
    {"id": "sk1-avg", "component": "Text", "variant": "caption", "text": "1ms AVG", "fontSize": 9, "color": "#888888"},
    {"id": "sk2-row", "component": "Row", "children": ["sk2-name", "sk2-ops", "sk2-avg"]},
    {"id": "sk2-name", "component": "Text", "variant": "body", "text": "API CONNECTOR", "fontSize": 9, "color": "#00FF88"},
    {"id": "sk2-ops", "component": "Text", "variant": "body", "text": "1,847 OPS", "fontSize": 9, "color": "#00FF88"},
    {"id": "sk2-avg", "component": "Text", "variant": "caption", "text": "45ms AVG", "fontSize": 9, "color": "#888888"},
    {"id": "sk3-row", "component": "Row", "children": ["sk3-name", "sk3-ops", "sk3-avg"]},
    {"id": "sk3-name", "component": "Text", "variant": "body", "text": "WEBHOOK RELAY", "fontSize": 9, "color": "#66AAFF"},
    {"id": "sk3-ops", "component": "Text", "variant": "body", "text": "923 OPS", "fontSize": 9, "color": "#66AAFF"},
    {"id": "sk3-avg", "component": "Text", "variant": "caption", "text": "12ms AVG", "fontSize": 9, "color": "#888888"},
    {"id": "sk4-row", "component": "Row", "children": ["sk4-name", "sk4-ops", "sk4-avg"]},
    {"id": "sk4-name", "component": "Text", "variant": "body", "text": "PROMPT ROUTER", "fontSize": 9, "color": "#66AAFF"},
    {"id": "sk4-ops", "component": "Text", "variant": "body", "text": "847 OPS", "fontSize": 9, "color": "#66AAFF"},
    {"id": "sk4-avg", "component": "Text", "variant": "caption", "text": "8ms AVG", "fontSize": 9, "color": "#888888"},
    {"id": "sk5-row", "component": "Row", "children": ["sk5-name", "sk5-ops", "sk5-avg"]},
    {"id": "sk5-name", "component": "Text", "variant": "body", "text": "SECRET SCANNER", "fontSize": 9, "color": "#888888"},
    {"id": "sk5-ops", "component": "Text", "variant": "body", "text": "53 OPS", "fontSize": 9, "color": "#888888"},
    {"id": "sk5-avg", "component": "Text", "variant": "caption", "text": "340ms AVG", "fontSize": 9, "color": "#888888"},

    {"id": "gap-3", "component": "Gap", "height": 8},

    {"id": "fuel-card", "component": "Card", "child": "fuel-col"},
    {"id": "fuel-col", "component": "Column", "children": ["fuel-tt", "fuel-row", "fuel-slider", "fuel-models"]},
    {"id": "fuel-tt", "component": "Text", "variant": "h5", "text": "BUDGET FUEL TANK (24H)", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "fuel-row", "component": "Row", "children": ["fuel-spent", "fuel-remaining"]},
    {"id": "fuel-spent", "component": "Text", "variant": "body", "text": "\$22.90 / \$50.00", "fontSize": 9, "color": "#FFAA00"},
    {"id": "fuel-remaining", "component": "Text", "variant": "body", "text": "54% REMAINING", "fontSize": 9, "color": "#00FF88"},
    {"id": "fuel-slider", "component": "Slider", "label": "Budget", "value": 54, "min": 0, "max": 100},
    {"id": "fuel-models", "component": "Text", "variant": "caption", "text": "OPUS 4.6 + HAIKU 4.5", "fontSize": 8, "color": "#888888"},

    {"id": "gap-4", "component": "Gap", "height": 16},
    {"id": "action-tray", "component": "Row", "children": ["export-btn", "refresh-btn", "dashboard-btn"]},
    {"id": "export-btn", "component": "Button", "child": "export-btn-text", "variant": "primary", "action": {"event": {"name": "export_analytics"}}},
    {"id": "export-btn-text", "component": "Text", "text": "EXPORT CSV"},
    {"id": "refresh-btn", "component": "Button", "child": "refresh-btn-text", "variant": "secondary", "action": {"event": {"name": "refresh_analytics"}}},
    {"id": "refresh-btn-text", "component": "Text", "text": "REFRESH"},
    {"id": "dashboard-btn", "component": "Button", "child": "dashboard-btn-text", "variant": "secondary", "action": {"event": {"name": "navigate", "context": {"text": "Show my agents"}}}},
    {"id": "dashboard-btn-text", "component": "Text", "text": "DASHBOARD"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Security Overview
  // ---------------------------------------------------------------------------

  static const _securityResponse =
      '''Security scan complete. Score: 94/100. No critical findings detected.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "security-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "security-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "subtitle-tt", "gap-top", "score-card", "gap-1", "findings-card", "gap-2", "compliance-card", "gap-3", "actions-row"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "SECURITY SCAN", "fontSize": 14, "fontWeight": 800, "letterSpacing": 2.0},
    {"id": "subtitle-tt", "component": "Text", "variant": "caption", "text": "LAST SWEEP 2 MIN AGO \u2022 PERIMETER SECURE", "fontSize": 10, "letterSpacing": 1.5, "color": "#00FF88"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "score-card", "component": "Card", "child": "score-col"},
    {"id": "score-col", "component": "Column", "children": ["score-tt", "score-slider", "score-detail"]},
    {"id": "score-tt", "component": "Text", "variant": "h5", "text": "THREAT ASSESSMENT SCORE", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "score-slider", "component": "Slider", "label": "Score", "value": 94, "min": 0, "max": 100},
    {"id": "score-detail", "component": "Text", "variant": "body", "text": "94 / 100 \u2014 EXCELLENT \u2022 0 CRITICAL \u2022 2 MEDIUM \u2022 0 LOW", "fontSize": 9, "color": "#00FF88"},

    {"id": "gap-1", "component": "Gap", "height": 8},
    {"id": "findings-card", "component": "Card", "child": "findings-col"},
    {"id": "findings-col", "component": "Column", "children": ["findings-tt", "finding-1", "finding-2", "finding-3", "finding-4"]},
    {"id": "findings-tt", "component": "Text", "variant": "h5", "text": "FINDINGS", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "finding-1", "component": "Row", "children": ["f1-icon", "f1-col"]},
    {"id": "f1-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "f1-col", "component": "Column", "children": ["f1-text", "f1-ts"]},
    {"id": "f1-text", "component": "Text", "text": "All API keys rotated within last 30 days"},
    {"id": "f1-ts", "component": "Text", "variant": "caption", "text": "VERIFIED 2 MIN AGO", "fontSize": 8, "color": "#888888"},
    {"id": "finding-2", "component": "Row", "children": ["f2-icon", "f2-col"]},
    {"id": "f2-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "f2-col", "component": "Column", "children": ["f2-text", "f2-ts"]},
    {"id": "f2-text", "component": "Text", "text": "TLS cert for api.example.com expires in 14 days"},
    {"id": "f2-ts", "component": "Text", "variant": "caption", "text": "MEDIUM \u2022 AUTO-RENEW SCHEDULED", "fontSize": 8, "color": "#FFAA00"},
    {"id": "finding-3", "component": "Row", "children": ["f3-icon", "f3-col"]},
    {"id": "f3-icon", "component": "Icon", "icon": "warning", "size": "small"},
    {"id": "f3-col", "component": "Column", "children": ["f3-text", "f3-ts"]},
    {"id": "f3-text", "component": "Text", "text": "2 dependencies have known vulnerabilities (low severity)"},
    {"id": "f3-ts", "component": "Text", "variant": "caption", "text": "MEDIUM \u2022 PATCH AVAILABLE", "fontSize": 8, "color": "#FFAA00"},
    {"id": "finding-4", "component": "Row", "children": ["f4-icon", "f4-col"]},
    {"id": "f4-icon", "component": "Icon", "icon": "check", "size": "small"},
    {"id": "f4-col", "component": "Column", "children": ["f4-text", "f4-ts"]},
    {"id": "f4-text", "component": "Text", "text": "No leaked secrets detected in last scan"},
    {"id": "f4-ts", "component": "Text", "variant": "caption", "text": "VERIFIED 2 MIN AGO", "fontSize": 8, "color": "#888888"},

    {"id": "gap-2", "component": "Gap", "height": 8},
    {"id": "compliance-card", "component": "Card", "child": "compliance-col"},
    {"id": "compliance-col", "component": "Column", "children": ["compliance-tt", "comp-soc2", "comp-gdpr", "comp-hipaa", "comp-encrypt"]},
    {"id": "compliance-tt", "component": "Text", "variant": "h5", "text": "COMPLIANCE MATRIX", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "comp-soc2", "component": "CheckBox", "label": "SOC 2 Type II \u2014 Audit logging enabled", "value": true},
    {"id": "comp-gdpr", "component": "CheckBox", "label": "GDPR \u2014 Data retention policies configured", "value": true},
    {"id": "comp-hipaa", "component": "CheckBox", "label": "HIPAA \u2014 Encryption at rest enabled", "value": true},
    {"id": "comp-encrypt", "component": "CheckBox", "label": "Encryption \u2014 TLS 1.3 enforced on all endpoints", "value": true},

    {"id": "gap-3", "component": "Gap", "height": 16},
    {"id": "actions-row", "component": "Row", "children": ["scan-btn", "rotate-btn", "export-btn"]},
    {"id": "scan-btn", "component": "Button", "child": "scan-btn-text", "variant": "primary", "action": {"event": {"name": "run_security_scan"}}},
    {"id": "scan-btn-text", "component": "Text", "text": "RUN SCAN"},
    {"id": "rotate-btn", "component": "Button", "child": "rotate-btn-text", "variant": "secondary", "action": {"event": {"name": "rotate_api_keys"}}},
    {"id": "rotate-btn-text", "component": "Text", "text": "ROTATE KEYS"},
    {"id": "export-btn", "component": "Button", "child": "export-btn-text", "variant": "secondary", "action": {"event": {"name": "export_compliance"}}},
    {"id": "export-btn-text", "component": "Text", "text": "EXPORT REPORT"}
  ]}}
]
```''';

  static const _createTravelAgentResponse =
      '''I'll help you set up a Travel Concierge agent! I've pre-filled the configuration with recommended tools for travel planning and the high-reasoning Opus 4.6 model.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-form-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "name-field", "model-picker", "tools-picker", "channels-picker", "save-btn"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "CREATE NEW AGENT", "subtitle": "ORCHESTRATE TRAVEL INTELLIGENCE", "vibe": "ADMIN", "status": "PENDING"},
    {"id": "gap-top", "component": "Gap", "height": 16},
    {"id": "name-field", "component": "TextField", "label": "AGENT NAME", "value": "Travel Concierge"},
    {"id": "model-picker", "component": "ChoicePicker", "label": "AI MODEL", "variant": "mutuallyExclusive", "options": [{"label": "Claude Opus 4.6", "value": "claude-opus-4-6"}, {"label": "Claude Sonnet 4.5", "value": "claude-sonnet-4-5"}, {"label": "GPT-4o", "value": "gpt-4o"}], "value": ["claude-opus-4-6"]},
    {"id": "tools-picker", "component": "ChoicePicker", "label": "TOOLS", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": ["browser", "code", "search", "api"]},
    {"id": "channels-picker", "component": "ChoicePicker", "label": "CHANNELS", "variant": "multipleSelection", "options": [{"label": "Telegram", "value": "telegram"}, {"label": "Slack", "value": "slack"}, {"label": "Discord", "value": "discord"}], "value": ["telegram", "slack", "discord"]},
    {"id": "save-btn", "component": "Button", "child": "save-btn-text", "variant": "primary", "action": {"event": {"name": "save_agent", "context": {"name": {"path": "name-field.value"}, "model": {"path": "model-picker.value"}, "tools": {"path": "tools-picker.value"}, "channels": {"path": "channels-picker.value"}}}}},
    {"id": "save-btn-text", "component": "Text", "text": "SAVE AGENT"}
  ]}}
]
```''';

  static const _catalogId = 'clawfree-catalog';

  static const _createAgentResponse =
      '''Configure your new agent's intelligence and capabilities below.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-form-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "name-field", "gap-name", "intel-card", "gap-1", "cap-card", "gap-2", "deploy-note", "save-btn"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "CREATE NEW AGENT", "subtitle": "CONFIGURE MISSION INTELLIGENCE", "vibe": "ADMIN", "status": "PENDING"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "name-field", "component": "TextField", "label": "AGENT NAME", "value": "New Agent"},
    {"id": "gap-name", "component": "Gap", "height": 12},

    {"id": "intel-card", "component": "Card", "child": "intel-col"},
    {"id": "intel-col", "component": "Column", "children": ["intel-tt", "model-picker"]},
    {"id": "intel-tt", "component": "Text", "variant": "h5", "text": "INTELLIGENCE CONFIG", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "model-picker", "component": "ChoicePicker", "label": "AI MODEL", "variant": "mutuallyExclusive", "options": [{"label": "Claude Opus 4.6", "value": "claude-opus-4-6"}, {"label": "Claude Sonnet 4.5", "value": "claude-sonnet-4-5"}, {"label": "GPT-4o", "value": "gpt-4o"}], "value": []},

    {"id": "gap-1", "component": "Gap", "height": 8},

    {"id": "cap-card", "component": "Card", "child": "cap-col"},
    {"id": "cap-col", "component": "Column", "children": ["cap-tt", "tools-picker", "channels-picker"]},
    {"id": "cap-tt", "component": "Text", "variant": "h5", "text": "CAPABILITY MATRIX", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "tools-picker", "component": "ChoicePicker", "label": "TOOLS", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": []},
    {"id": "channels-picker", "component": "ChoicePicker", "label": "CHANNELS", "variant": "multipleSelection", "options": [{"label": "Telegram", "value": "telegram"}, {"label": "Slack", "value": "slack"}, {"label": "Discord", "value": "discord"}], "value": []},

    {"id": "gap-2", "component": "Gap", "height": 16},

    {"id": "deploy-note", "component": "Text", "variant": "caption", "text": "AGENT WILL BE CREATED AND DEPLOYED TO SELECTED CHANNELS", "fontSize": 8, "color": "#888888"},
    {"id": "save-btn", "component": "Button", "child": "save-btn-text", "variant": "primary", "action": {"event": {"name": "save_agent", "context": {"name": {"path": "name-field.value"}, "model": {"path": "model-picker.value"}, "tools": {"path": "tools-picker.value"}, "channels": {"path": "channels-picker.value"}}}}},
    {"id": "save-btn-text", "component": "Text", "text": "CREATE AGENT"}
  ]}}
]
```''';

  static const _dashboardResponse =
      '''Here are your agents. Tap an agent to view details.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "dashboard-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "dashboard-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "agent-1-card"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "SYSTEM OVERVIEW", "subtitle": "1 AGENT DEPLOYED \u2022 CLUSTER NOMINAL", "vibe": "ADMIN", "status": "ACTIVE"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "agent-1-card", "component": "AgentCard", "name": "TRAVEL CONCIERGE", "status": "ONLINE", "model": "OPUS 4.6", "level": "nominal", "meta": "VIBE-DRIVEN ITINERARY PLANNING \u2022 12 TRIPS", "action": {"event": {"name": "navigate", "context": {"text": "Plan a trip"}}}}
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
    {"id": "name-field", "component": "TextField", "label": "Agent Name", "value": "GitHub Digest Bot"}
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
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "qr-card", "instructions", "copy-btn"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "DEVICE PAIRING", "subtitle": "SECURE MULTI-DEVICE ORCHESTRATION", "vibe": "ADMIN", "status": "PENDING"},
    {"id": "gap-top", "component": "Gap", "height": 16},
    {"id": "qr-card", "component": "Card", "child": "qr-content"},
    {"id": "qr-content", "component": "Column", "children": ["qr-label", "qr-code", "backup-code"]},
    {"id": "qr-label", "component": "Text", "text": "Scan with your phone", "variant": "body2"},
    {"id": "qr-code", "component": "Image", "url": "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=clawfree-pair%3A%2F%2Flocalhost%3A18789%3Ftoken%3Ddemo-pair-token", "variant": "mediumFeature"},
    {"id": "backup-code", "component": "Text", "text": "Backup code: 847 291", "variant": "body2"},
    {"id": "instructions", "component": "Text", "text": "This link connects your device to the local OpenClaw gateway at ws://localhost:18789. The pairing token expires in 10 minutes."},
    {"id": "copy-btn", "component": "Button", "child": "copy-btn-text", "variant": "secondary", "action": {"event": {"name": "copy_pairing_link", "context": {"url": "ws://localhost:18789?token=demo-pair-token"}}}},
    {"id": "copy-btn-text", "component": "Text", "text": "COPY PAIRING LINK"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Management: OpenClaw controls
  // ---------------------------------------------------------------------------

  static const _manageResponse =
      '''Command Center online. Gateway is healthy and all systems are nominal.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "manage-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "manage-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "main-grid", "gap-1", "config-card", "gap-2", "action-tray"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "COMMAND CENTER", "subtitle": "OPENCLAW GATEWAY v2026.2.9", "vibe": "ADMIN", "status": "NOMINAL"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "main-grid", "component": "ResponsiveContainer", "columns": 2, "mobileColumns": 1, "children": ["status-card", "config-detail-card"]},

    {"id": "status-card", "component": "Card", "child": "status-col"},
    {"id": "status-col", "component": "Column", "children": ["status-title", "link-spark", "link-label", "cpu-spark", "cpu-label", "mem-spark", "mem-label", "uptime-tt"]},
    {"id": "status-title", "component": "Text", "variant": "h5", "text": "SYSTEM VITALS", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "link-spark", "component": "HealthSparkline", "level": "nominal", "width": 140, "height": 20, "showGlow": true},
    {"id": "link-label", "component": "Text", "variant": "caption", "text": "CONNECTIVITY \u2022 12ms LATENCY", "fontSize": 8, "color": "#00FF88"},
    {"id": "cpu-spark", "component": "HealthSparkline", "level": "nominal", "width": 140, "height": 20, "showGlow": true, "dataPoints": [0.3, 0.4, 0.35, 0.5, 0.45, 0.38, 0.42, 0.4]},
    {"id": "cpu-label", "component": "Text", "variant": "caption", "text": "CPU \u2022 42% UTILIZATION", "fontSize": 8, "color": "#00FF88"},
    {"id": "mem-spark", "component": "HealthSparkline", "level": "nominal", "width": 140, "height": 20, "showGlow": true, "dataPoints": [0.6, 0.62, 0.61, 0.63, 0.65, 0.64, 0.62, 0.63]},
    {"id": "mem-label", "component": "Text", "variant": "caption", "text": "MEMORY \u2022 63% ALLOCATED", "fontSize": 8, "color": "#FFAA00"},
    {"id": "uptime-tt", "component": "Text", "variant": "caption", "text": "UPTIME 2H 14M \u2022 3 AGENTS \u2022 14 SKILLS", "fontSize": 9, "color": "#888888"},

    {"id": "config-detail-card", "component": "Card", "child": "config-detail-col"},
    {"id": "config-detail-col", "component": "Column", "children": ["config-detail-title", "cfg-gw-row", "cfg-model-row", "cfg-budget-row", "config-gap", "cfg-agents-row", "cfg-skills-row"]},
    {"id": "config-detail-title", "component": "Text", "variant": "h5", "text": "CONFIGURATION", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "cfg-gw-row", "component": "Row", "justify": "spaceBetween", "children": ["cfg-gw-label", "cfg-gw-val"]},
    {"id": "cfg-gw-label", "component": "Text", "variant": "caption", "text": "GATEWAY", "fontSize": 9, "color": "#888888"},
    {"id": "cfg-gw-val", "component": "Text", "variant": "body", "text": "ws://localhost:18789", "fontSize": 9, "color": "#888888"},
    {"id": "cfg-model-row", "component": "Row", "justify": "spaceBetween", "children": ["cfg-model-label", "cfg-model-val"]},
    {"id": "cfg-model-label", "component": "Text", "variant": "caption", "text": "MODEL", "fontSize": 9, "color": "#888888"},
    {"id": "cfg-model-val", "component": "Text", "variant": "body", "text": "claude-opus-4-6", "fontSize": 9, "color": "#888888"},
    {"id": "cfg-budget-row", "component": "Row", "justify": "spaceBetween", "children": ["cfg-budget-label", "cfg-budget-val"]},
    {"id": "cfg-budget-label", "component": "Text", "variant": "caption", "text": "BUDGET", "fontSize": 9, "color": "#FFAA00"},
    {"id": "cfg-budget-val", "component": "Text", "variant": "body", "text": "\$50/day \u2022 \$22.90 used", "fontSize": 9, "color": "#FFAA00"},
    {"id": "config-gap", "component": "Gap", "height": 8},
    {"id": "cfg-agents-row", "component": "Row", "justify": "spaceBetween", "children": ["cfg-agents-label", "cfg-agents-val"]},
    {"id": "cfg-agents-label", "component": "Text", "variant": "caption", "text": "AGENTS", "fontSize": 9, "color": "#00FF88"},
    {"id": "cfg-agents-val", "component": "Text", "variant": "body", "text": "3 DEPLOYED \u2022 ALL NOMINAL", "fontSize": 9, "color": "#00FF88"},
    {"id": "cfg-skills-row", "component": "Row", "justify": "spaceBetween", "children": ["cfg-skills-label", "cfg-skills-val"]},
    {"id": "cfg-skills-label", "component": "Text", "variant": "caption", "text": "SKILLS", "fontSize": 9, "color": "#66AAFF"},
    {"id": "cfg-skills-val", "component": "Text", "variant": "body", "text": "14 ACTIVE \u2022 39 AVAILABLE", "fontSize": 9, "color": "#66AAFF"},

    {"id": "gap-1", "component": "Gap", "height": 8},

    {"id": "config-card", "component": "Card", "child": "config-col"},
    {"id": "config-col", "component": "Column", "children": ["config-title", "logs-btn"]},
    {"id": "config-title", "component": "Text", "variant": "h5", "text": "AUDIT", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "logs-btn", "component": "Button", "child": "logs-btn-text", "variant": "secondary", "action": {"event": {"name": "navigate", "context": {"text": "Show audit log"}}}},
    {"id": "logs-btn-text", "component": "Text", "text": "VIEW AUDIT TRAIL"},

    {"id": "gap-2", "component": "Gap", "height": 16},

    {"id": "action-tray", "component": "Row", "children": ["update-btn", "restart-btn", "pair-btn"]},
    {"id": "update-btn", "component": "Button", "child": "update-btn-text", "variant": "primary", "action": {"event": {"name": "update_openclaw"}}},
    {"id": "update-btn-text", "component": "Text", "text": "CHECK FOR UPDATES"},
    {"id": "restart-btn", "component": "Button", "child": "restart-btn-text", "variant": "secondary", "action": {"event": {"name": "restart_openclaw"}}},
    {"id": "restart-btn-text", "component": "Text", "text": "RESTART GATEWAY"},
    {"id": "pair-btn", "component": "Button", "child": "pair-btn-text", "variant": "secondary", "action": {"event": {"name": "pair_device"}}},
    {"id": "pair-btn-text", "component": "Text", "text": "PAIR DEVICE"}
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
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "vitals-card", "indicators-card", "readings-card"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "SYSTEM VITALS", "subtitle": "REAL-TIME DIAGNOSTIC TELEMETRY", "vibe": "HEALTH", "status": "NOMINAL"},
    {"id": "gap-top", "component": "Gap", "height": 16},
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
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "desc", "url-field", "token-field", "connect-btn"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "GATEWAY CONNECTION", "subtitle": "LINK TO EXISTING OPENCLAW INSTANCE", "vibe": "ADMIN", "status": "PENDING"},
    {"id": "gap-top", "component": "Gap", "height": 16},
    {"id": "desc", "component": "Text", "text": "Enter the URL and authentication token for your existing OpenClaw gateway. You can find these in your gateway's dashboard or config file."},
    {"id": "url-field", "component": "TextField", "label": "Gateway URL", "value": "ws://localhost:18789"},
    {"id": "token-field", "component": "TextField", "label": "Gateway Token", "value": ""},
    {"id": "connect-btn", "component": "Button", "child": "connect-btn-text", "variant": "primary", "action": {"event": {"name": "connect_gateway", "context": {"gateway_url": {"path": "url-field.value"}, "gateway_token": {"path": "token-field.value"}}}}},
    {"id": "connect-btn-text", "component": "Text", "text": "CONNECT"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Setup concierge agent
  // ---------------------------------------------------------------------------

      static const _travelSetupResponse =

          '''Travel Concierge activated. Select your destination and vibe to begin trip planning.

    

    ```json

    [

      {"version": "v0.9", "createSurface": {"surfaceId": "travel-setup-001", "catalogId": "$_catalogId"}},

      {"version": "v0.9", "updateComponents": {"surfaceId": "travel-setup-001", "components": [

        {"id": "root", "component": "Column", "children": ["header-tt", "gap-top", "dest-card", "gap-1", "config-card", "gap-2", "plan-btn"]},

        {"id": "header-tt", "component": "ItineraryHeader", "title": "TRAVEL CONCIERGE", "subtitle": "VIBE-DRIVEN TRIP PLANNING", "vibe": "TRAVEL", "status": "ACTIVE"},

        {"id": "gap-top", "component": "Gap", "height": 16},

    

  

      {"id": "dest-card", "component": "Card", "child": "dest-col"},

      {"id": "dest-col", "component": "Column", "children": ["dest-tt", "city-picker"]},

      {"id": "dest-tt", "component": "Text", "variant": "h5", "text": "DESTINATION SELECT", "fontSize": 10, "letterSpacing": 1.5},

      {"id": "city-picker", "component": "ChoicePicker", "label": "RECENT DESTINATIONS", "variant": "mutuallyExclusive", "layout": "grid", "options": [{"label": "Tokyo", "value": "tokyo"}, {"label": "London", "value": "london"}, {"label": "Paris", "value": "paris"}, {"label": "New York", "value": "new-york"}, {"label": "San Francisco", "value": "san-francisco"}], "value": ["tokyo"]},

  

      {"id": "gap-1", "component": "Gap", "height": 8},

  

      {"id": "config-card", "component": "Card", "child": "config-col"},

      {"id": "config-col", "component": "Column", "children": ["config-tt", "vibe-picker", "days-picker", "config-note"]},

      {"id": "config-tt", "component": "Text", "variant": "h5", "text": "TRAVEL PARAMETERS", "fontSize": 10, "letterSpacing": 1.5},

      {"id": "vibe-picker", "component": "ChoicePicker", "label": "TRAVEL VIBE", "variant": "mutuallyExclusive", "options": [{"label": "Foodie", "value": "foodie"}, {"label": "Artsy", "value": "artsy"}, {"label": "Outdoorsy", "value": "outdoorsy"}, {"label": "Budget", "value": "budget"}], "value": ["foodie"]},

      {"id": "days-picker", "component": "ChoicePicker", "label": "TRIP DURATION", "variant": "mutuallyExclusive", "options": [{"label": "3 Days", "value": "3"}, {"label": "5 Days", "value": "5"}, {"label": "7 Days", "value": "7"}], "value": ["3"]},

      {"id": "config-note", "component": "Text", "variant": "caption", "text": "VIBE INFLUENCES CURATED RESTAURANTS, ACTIVITIES, AND HOTEL MATCHES", "fontSize": 8, "color": "#888888"},

  

      {"id": "gap-2", "component": "Gap", "height": 16},

      {"id": "plan-btn", "component": "Button", "child": "plan-btn-text", "variant": "primary", "action": {"event": {"name": "generate_itinerary", "context": {"city": {"path": "city-picker.value"}, "vibe": {"path": "vibe-picker.value"}, "days": {"path": "days-picker.value"}}}}},

      {"id": "plan-btn-text", "component": "Text", "text": "GENERATE ITINERARY"}

    ]}}

  ]

  ```''';

  

  // ---------------------------------------------------------------------------
  // Travel: Tokyo overview (Foodie default) — VideoPlayer at top
  // ---------------------------------------------------------------------------

  static const _tokyoOverviewResponse =
      '''Trip itinerary complete. Here's your curated 3-day Tokyo foodie experience with flights and lodging.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "tokyo-itin-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "tokyo-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-1", "video", "gap-2", "trip-map", "gap-3", "timeline-card", "gap-4", "hotel-card", "gap-5", "flights-tt", "ticket1-card", "gap-6", "ticket2-card", "gap-7", "book-card"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "TOKYO 3-DAY FOODIE EXPERIENCE", "subtitle": "MAR 20\u201323, 2026 \u2022 12 RESTAURANTS", "vibe": "FOODIE", "status": "CONFIRMED"},
    {"id": "gap-1", "component": "Gap", "size": "lg"},
    {"id": "video", "component": "VideoPlayer", "tripId": "tokyo-foodie-3d"},
    {"id": "gap-2", "component": "Gap", "size": "xxl"},
    {"id": "trip-map", "component": "TripMap", "center": [35.68, 139.76], "zoom": 12, "markers": [{"lat": 35.6654, "lng": 139.7707, "label": "Tsukiji Market"}, {"lat": 35.6812, "lng": 139.7671, "label": "Ramen Street"}, {"lat": 35.6717, "lng": 139.7650, "label": "Ginza Depachika"}, {"lat": 35.6600, "lng": 139.7300, "label": "Sukiyabashi Jiro"}, {"lat": 35.6852, "lng": 139.7100, "label": "Shinjuku Gyoen"}, {"lat": 35.6940, "lng": 139.7036, "label": "Golden Gai"}, {"lat": 35.6457, "lng": 139.7835, "label": "Toyosu Market"}, {"lat": 35.6712, "lng": 139.7639, "label": "Tempura Kondo"}, {"lat": 35.7148, "lng": 139.7967, "label": "Asakusa"}, {"lat": 35.6720, "lng": 139.7252, "label": "Narisawa"}]},
    {"id": "gap-3", "component": "Gap", "size": "xxxl"},
    {"id": "timeline-card", "component": "ItineraryTimeline", "days": [
      {"dayLabel": "THU MAR 20 \u2022 DAY 1", "title": "Tsukiji & Ginza Exploration", "activities": [{"time": "5:30 AM", "label": "Sushi Dai breakfast", "icon": "wb_sunny"}, {"time": "12:00 PM", "label": "Rokurinsha tsukemen", "icon": "restaurant"}, {"time": "3:00 PM", "label": "Ginza depachika tour", "icon": "shopping_bag"}, {"time": "7:00 PM", "label": "Sukiyabashi Jiro Omakase", "icon": "nightlight"}]},
      {"dayLabel": "FRI MAR 21 \u2022 DAY 2", "title": "Shinjuku Heights & Hidden Bars", "activities": [{"time": "9:00 AM", "label": "Shinjuku Gyoen Matcha", "icon": "park"}, {"time": "12:30 PM", "label": "Fuunji Ramen", "icon": "restaurant"}, {"time": "3:00 PM", "label": "Omoide Yokocho Yakitori", "icon": "local_fire_department"}, {"time": "8:00 PM", "label": "Golden Gai Bar Crawl", "icon": "sports_bar"}]},
      {"dayLabel": "SAT MAR 22 \u2022 DAY 3", "title": "Toyosu Auction & Asakusa Tradition", "activities": [{"time": "6:00 AM", "label": "Toyosu Fish Auction", "icon": "wb_sunny"}, {"time": "12:00 PM", "label": "Tempura Kondo", "icon": "restaurant"}, {"time": "3:00 PM", "label": "Nakamise-dori Street Food", "icon": "store"}, {"time": "7:30 PM", "label": "Narisawa Innovation", "icon": "star"}]}
    ]},

    {"id": "gap-4", "component": "Gap", "size": "xxxl"},
    {"id": "hotel-card", "component": "HotelCard", "name": "Hoshinoya Tokyo", "address": "1-9-1 Otemachi, Chiyoda-ku, Tokyo", "imageUrl": "https://images.unsplash.com/photo-1590073242678-70ee3fc28e8e?w=800&h=400&fit=crop&auto=format", "price": "\$420", "rating": 5, "amenities": ["Private Kaiseki", "Rooftop Onsen", "Zen Garden"], "checkIn": "15:00", "checkOut": "11:00", "action": {"event": {"name": "browser_open", "context": {"url": "https://hoshinoya.com/tokyo/en/"}}}},

    {"id": "gap-5", "component": "Gap", "size": "xxxl"},
    {"id": "flights-tt", "component": "Text", "variant": "h5", "text": "ROUND-TRIP FLIGHTS", "fontSize": 11, "fontWeight": 800, "letterSpacing": 1.5},

    {"id": "ticket1-card", "component": "FlightTicket", "airline": "All Nippon Airways", "logoUrl": "https://images.kiwi.com/airlines/64/NH.png", "fromCode": "SFO", "toCode": "HND", "flightNo": "NH007", "departureTime": "1:15 PM", "arrivalTime": "5:45 PM+1", "date": "THU MAR 20", "returnFlightNo": "NH008", "returnDepartureTime": "9:55 PM", "returnArrivalTime": "2:10 PM", "returnDate": "SUN MAR 23", "price": "\$2,360", "selected": true, "selectionPath": "flights.selectedId", "action": {"event": {"name": "book_flight", "context": {"flight": "NH007", "price": 2360}}}},
    {"id": "gap-6", "component": "Gap", "size": "lg"},
    {"id": "ticket2-card", "component": "FlightTicket", "airline": "Japan Airlines", "logoUrl": "https://images.kiwi.com/airlines/64/JL.png", "fromCode": "SFO", "toCode": "NRT", "flightNo": "JL005", "departureTime": "11:35 AM", "arrivalTime": "3:50 PM+1", "date": "THU MAR 20", "returnFlightNo": "JL006", "returnDepartureTime": "6:30 PM", "returnArrivalTime": "11:00 AM", "returnDate": "SUN MAR 23", "price": "\$2,480", "selectionPath": "flights.selectedId", "action": {"event": {"name": "book_flight", "context": {"flight": "JL005", "price": 2480}}}},

    {"id": "gap-7", "component": "Gap", "size": "xxl"},

    {"id": "book-card", "component": "BookingSummary", "summary": "3 nights at Hoshinoya Tokyo + round-trip flights + 12 restaurant reservations", "total": "\$3,740", "hotelPrice": "\$1,260", "flightPrice": "\$2,360", "fees": "\$120", "buttonText": "CONFIRM BOOKING", "action": {"event": {"name": "book_trip", "context": {"city": {"path": "city-picker.value"}, "days": {"path": "days-picker.value"}, "vibe": {"path": "vibe-picker.value"}, "flight": {"path": "flights.selectedId"}}}}}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Tokyo Artistic persona variant
  // ---------------------------------------------------------------------------

  static const _tokyoArtisticResponse =
      '''Switching to the artsy travel style! Here's your curated Tokyo art and culture itinerary.

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "tokyo-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-1", "video", "gap-2", "timeline-card", "gap-3", "hotel-card", "gap-4", "flights-title", "ticket1-card", "gap-5", "ticket2-card", "gap-6", "book-card"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "TOKYO 3-DAY ART & CULTURE EXPERIENCE", "subtitle": "MAR 20\u201323, 2026 \u2022 INDIE GALLERIES", "vibe": "ARTSY", "status": "CONFIRMED"},
    {"id": "gap-1", "component": "Gap", "size": "lg"},
    {"id": "video", "component": "VideoPlayer", "tripId": "tokyo-foodie-3d"},
    {"id": "gap-2", "component": "Gap", "size": "xxl"},
    {"id": "timeline-card", "component": "ItineraryTimeline", "days": [
      {"dayLabel": "DAY 1 \u2022 ROPPONGI", "title": "Mori Art & Ando Design", "activities": [{"time": "10:00 AM", "label": "Mori Art Museum", "icon": "museum"}, {"time": "1:00 PM", "label": "National Art Center", "icon": "architecture"}, {"time": "3:30 PM", "label": "21_21 Design Sight", "icon": "palette"}, {"time": "7:30 PM", "label": "d47 Shokudo", "icon": "restaurant"}]},
      {"dayLabel": "DAY 2 \u2022 ODAIBA", "title": "Digital Immersions", "activities": [{"time": "11:00 AM", "label": "teamLab Borderless", "icon": "lightbulb"}, {"time": "2:00 PM", "label": "Bills Odaiba", "icon": "restaurant"}, {"time": "4:00 PM", "label": "Palette Town", "icon": "directions_car"}, {"time": "8:30 PM", "label": "Shimokitazawa Jazz", "icon": "music_note"}]},
      {"dayLabel": "DAY 3 \u2022 YANAKA", "title": "Nostalgic Tokyo", "activities": [{"time": "9:30 AM", "label": "Yanaka Gallery Crawl", "icon": "brush"}, {"time": "12:30 PM", "label": "Kayaba Coffee", "icon": "coffee"}, {"time": "3:00 PM", "label": "Ghibli Museum", "icon": "animation"}, {"time": "8:00 PM", "label": "Florilege", "icon": "restaurant"}]}
    ]},
    {"id": "gap-3", "component": "Gap", "size": "xxxl"},
    {"id": "hotel-card", "component": "HotelCard", "name": "Park Hyatt Tokyo", "address": "3-7-1-2 Nishi Shinjuku, Shinjuku-ku, Tokyo", "imageUrl": "https://images.unsplash.com/photo-1480796927426-f609979314bd?w=800&h=400&fit=crop&auto=format", "price": "\$380", "rating": 5, "amenities": ["Sky Bar", "Peak Lounge", "Iconic Views"], "checkIn": "15:00", "checkOut": "12:00", "action": {"event": {"name": "browser_open", "context": {"url": "https://www.hyatt.com/en-US/hotel/japan/park-hyatt-tokyo/tyoph"}}}},
    
    {"id": "gap-4", "component": "Gap", "size": "xxxl"},
    {"id": "flights-title", "component": "Text", "text": "AIRLINE OPTIONS", "variant": "h5", "fontSize": 11, "letterSpacing": 1.5},
    {"id": "ticket1-card", "component": "FlightTicket", "airline": "All Nippon Airways", "logoUrl": "https://images.kiwi.com/airlines/64/NH.png", "fromCode": "SFO", "toCode": "HND", "flightNo": "NH007", "departureTime": "1:15 PM", "arrivalTime": "5:45 PM+1", "date": "THU MAR 20", "returnFlightNo": "NH008", "returnDepartureTime": "9:55 PM", "returnArrivalTime": "2:10 PM", "returnDate": "SUN MAR 23", "price": "\$2,360", "selected": true, "selectionPath": "flights.selectedId", "action": {"event": {"name": "book_flight", "context": {"flight": "NH007", "price": 2360}}}},
    {"id": "gap-5", "component": "Gap", "size": "lg"},
    {"id": "ticket2-card", "component": "FlightTicket", "airline": "Japan Airlines", "logoUrl": "https://images.kiwi.com/airlines/64/JL.png", "fromCode": "SFO", "toCode": "NRT", "flightNo": "JL005", "departureTime": "11:35 AM", "arrivalTime": "3:50 PM+1", "date": "THU MAR 20", "returnFlightNo": "JL006", "returnDepartureTime": "6:30 PM", "returnArrivalTime": "11:00 AM", "returnDate": "SUN MAR 23", "price": "\$2,480", "selectionPath": "flights.selectedId", "action": {"event": {"name": "book_flight", "context": {"flight": "JL005", "price": 2480}}}},

    {"id": "gap-6", "component": "Gap", "size": "xxl"},
    {"id": "book-card", "component": "BookingSummary", "summary": "3 nights at Park Hyatt Tokyo + round-trip flights + museum passes", "total": "\$3,620", "hotelPrice": "\$1,140", "flightPrice": "\$2,360", "fees": "\$120", "buttonText": "CONFIRM BOOKING", "action": {"event": {"name": "book_trip", "context": {"city": {"path": "city-picker.value"}, "days": {"path": "days-picker.value"}, "vibe": {"path": "vibe-picker.value"}, "flight": {"path": "flights.selectedId"}}}}}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Tokyo Outdoorsy persona variant
  // ---------------------------------------------------------------------------

  static const _tokyoOutdoorsyResponse =
      '''Here's the nature and adventure travel experience! Tokyo has amazing outdoor escapes within day-trip distance.

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "tokyo-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-1", "video", "gap-2", "timeline-card", "gap-d3h", "hotel-card", "gap-hf", "flights-title", "ticket1-card", "gap-t1t2", "ticket2-card", "gap-t2book", "book-card"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "TOKYO 3-DAY NATURE & ADVENTURE EXPERIENCE", "subtitle": "MAR 20\u201323, 2026 \u2022 ANCIENT FORESTS", "vibe": "OUTDOORSY", "status": "CONFIRMED"},
    {"id": "gap-1", "component": "Gap", "height": 16},
    {"id": "gap-2", "component": "Gap", "height": 24},
    {"id": "timeline-card", "component": "ItineraryTimeline", "days": [
      {"dayLabel": "DAY 1 \u2022 MT. TAKAO", "title": "Summits & Shrines", "activities": [{"time": "8:30 AM", "label": "Mt. Takao Hike", "icon": "terrain"}, {"time": "12:30 PM", "label": "Summit Soba", "icon": "restaurant"}, {"time": "3:00 PM", "label": "Meiji Jingu Forest", "icon": "park"}, {"time": "6:30 PM", "label": "Yoyogi Park Sunset", "icon": "wb_sunny"}]},
      {"dayLabel": "DAY 2 \u2022 KAMAKURA", "title": "Ocean Caves & Buddha", "activities": [{"time": "9:00 AM", "label": "Enoshima Island Caves", "icon": "waves"}, {"time": "1:00 PM", "label": "Harbor Seafood", "icon": "restaurant"}, {"time": "3:30 PM", "label": "Daibutsu Hiking Trail", "icon": "terrain"}, {"time": "7:00 PM", "label": "Yuigahama Beach Izakaya", "icon": "sports_bar"}]},
      {"dayLabel": "DAY 3 \u2022 NIKKO", "title": "Waterfalls & Zen", "activities": [{"time": "10:00 AM", "label": "Kegon Falls Plunge", "icon": "water_drop"}, {"time": "1:30 PM", "label": "Buddhist Yuba Cuisine", "icon": "restaurant"}, {"time": "4:00 PM", "label": "Lake Chuzenji Kayak", "icon": "rowing"}, {"time": "8:00 PM", "label": "Volcanic Onsen Kaiseki", "icon": "hot_tub"}]}
    ]},
    {"id": "gap-d3h", "component": "Gap", "height": 32},

    {"id": "hotel-card", "component": "HotelCard", "name": "HOSHINOYA Fuji", "address": "1408 Oishi, Fujikawaguchiko, Yamanashi", "imageUrl": "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&h=400&fit=crop&auto=format", "price": "\$350", "rating": 4, "amenities": ["Glamping", "Mt. Fuji View", "Forest Trails"], "checkIn": "15:00", "checkOut": "11:00", "action": {"event": {"name": "browser_open", "context": {"url": "https://hoshinoya.com/fuji/en/"}}}},
    
    {"id": "flights-title", "component": "Text", "text": "AIRLINE OPTIONS", "variant": "h5", "fontSize": 11, "letterSpacing": 1.5},
    {"id": "ticket1-card", "component": "FlightTicket", "airline": "All Nippon Airways", "logoUrl": "https://images.kiwi.com/airlines/64/NH.png", "fromCode": "SFO", "toCode": "HND", "flightNo": "NH007", "departureTime": "1:15 PM", "arrivalTime": "5:45 PM+1", "date": "THU MAR 20", "returnFlightNo": "NH008", "returnDepartureTime": "9:55 PM", "returnArrivalTime": "2:10 PM", "returnDate": "SUN MAR 23", "price": "\$2,360", "selected": true, "selectionPath": "flights.selectedId", "action": {"event": {"name": "book_flight", "context": {"flight": "NH007", "price": 2360}}}},
    {"id": "gap-t1t2", "component": "Gap", "height": 16},
    {"id": "ticket2-card", "component": "FlightTicket", "airline": "Japan Airlines", "logoUrl": "https://images.kiwi.com/airlines/64/JL.png", "fromCode": "SFO", "toCode": "NRT", "flightNo": "JL005", "departureTime": "11:35 AM", "arrivalTime": "3:50 PM+1", "date": "THU MAR 20", "returnFlightNo": "JL006", "returnDepartureTime": "6:30 PM", "returnArrivalTime": "11:00 AM", "returnDate": "SUN MAR 23", "price": "\$2,480", "selectionPath": "flights.selectedId", "action": {"event": {"name": "book_flight", "context": {"flight": "JL005", "price": 2480}}}},

    {"id": "gap-t2book", "component": "Gap", "height": 16},
    {"id": "book-card", "component": "BookingSummary", "summary": "3 nights at HOSHINOYA Fuji + round-trip flights + guided trails", "total": "\$3,530", "hotelPrice": "\$1,050", "flightPrice": "\$2,360", "fees": "\$120", "buttonText": "CONFIRM BOOKING", "action": {"event": {"name": "book_trip", "context": {"city": {"path": "city-picker.value"}, "days": {"path": "days-picker.value"}, "vibe": {"path": "vibe-picker.value"}, "flight": {"path": "flights.selectedId"}}}}}
  ]}}
]
```''';

  static const _travelConciergeDetailResponse =
      '''Agent details for Travel Concierge.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-detail-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-detail-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "gap-1", "config-card", "gap-2", "actions"]},
    {"id": "header-tt", "component": "ItineraryHeader", "title": "TRAVEL CONCIERGE", "subtitle": "VIBE-DRIVEN ITINERARY PLANNING", "vibe": "TRAVEL", "status": "NOMINAL"},
    {"id": "gap-1", "component": "Gap", "height": 16},
    {"id": "config-card", "component": "Card", "child": "config-col"},
    {"id": "config-col", "component": "Column", "children": ["cfg-tt", "cfg-desc"]},
    {"id": "cfg-tt", "component": "Text", "variant": "h5", "text": "CONFIGURATION", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "cfg-desc", "component": "Text", "text": "Specialized in high-reasoning itinerary planning and vibe-driven discovery."},
    {"id": "gap-2", "component": "Gap", "height": 16},
    {"id": "actions", "component": "Row", "children": ["engage-btn", "delete-btn"]},
    {"id": "engage-btn", "component": "Button", "child": "engage-tt", "variant": "primary", "action": {"event": {"name": "navigate", "context": {"text": "Plan a trip"}}}},
    {"id": "engage-tt", "component": "Text", "variant": "body", "text": "ENGAGE"},
    {"id": "delete-btn", "component": "Button", "child": "delete-tt", "variant": "secondary", "action": {"event": {"name": "navigate", "context": {"text": "Delete agent"}}}},
    {"id": "delete-tt", "component": "Text", "variant": "body", "text": "DECOMMISSION", "color": "#FF4444"}
  ]}}
]
```''';
}
