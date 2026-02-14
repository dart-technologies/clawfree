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
        'children': ['header-tt', 'subtitle-tt', 'gap-top', ...sectionIds],
      },
      {
        'id': 'header-tt',
        'component': 'Text', 'variant': 'h4',
        'text': 'SKILL LIBRARY',
        'fontSize': 14,
        'fontWeight': 800,
        'letterSpacing': 2.0,
      },
      {
        'id': 'subtitle-tt',
        'component': 'Text', 'variant': 'caption',
        'text': '53 SKILLS \u2022 9 CATEGORIES \u2022 14 AUTO-ACTIVATED',
        'fontSize': 10,
        'letterSpacing': 1.5,
        'color': '#66AAFF',
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
      '''Telemetry grid online. All systems performing within nominal parameters.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "analytics-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "analytics-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "subtitle-tt", "gap-top", "stats-grid", "gap-1", "agents-card", "gap-2", "skills-card", "gap-3", "fuel-card", "gap-4", "action-tray"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "TELEMETRY GRID", "fontSize": 14, "fontWeight": 800, "letterSpacing": 2.0},
    {"id": "subtitle-tt", "component": "Text", "variant": "caption", "text": "REAL-TIME PERFORMANCE ANALYTICS", "fontSize": 10, "letterSpacing": 1.5, "color": "#66AAFF"},
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
    {"id": "export-btn-text", "component": "Text", "text": "Export CSV"},
    {"id": "refresh-btn", "component": "Button", "child": "refresh-btn-text", "variant": "secondary", "action": {"event": {"name": "refresh_analytics"}}},
    {"id": "refresh-btn-text", "component": "Text", "text": "Refresh"},
    {"id": "dashboard-btn", "component": "Button", "child": "dashboard-btn-text", "variant": "secondary", "action": {"event": {"name": "navigate", "context": {"text": "Show my agents"}}}},
    {"id": "dashboard-btn-text", "component": "Text", "text": "Dashboard"}
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
    {"id": "scan-btn-text", "component": "Text", "text": "Run Scan"},
    {"id": "rotate-btn", "component": "Button", "child": "rotate-btn-text", "variant": "secondary", "action": {"event": {"name": "rotate_api_keys"}}},
    {"id": "rotate-btn-text", "component": "Text", "text": "Rotate Keys"},
    {"id": "export-btn", "component": "Button", "child": "export-btn-text", "variant": "secondary", "action": {"event": {"name": "export_compliance"}}},
    {"id": "export-btn-text", "component": "Text", "text": "Export Report"}
  ]}}
]
```''';

  static const _createTravelAgentResponse =
      '''I'll help you set up a Travel Concierge agent! I've pre-filled the configuration with recommended tools for travel planning and the high-reasoning Opus 4.6 model.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-form-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "name-field", "model-picker", "tools-picker", "channels-picker", "save-btn"]},
    {"id": "title", "component": "Text", "text": "Create New Agent", "variant": "h4"},
    {"id": "name-field", "component": "TextField", "label": "Agent Name", "value": "Travel Concierge"},
    {"id": "model-picker", "component": "ChoicePicker", "label": "AI Model", "variant": "mutuallyExclusive", "options": [{"label": "Claude Opus 4.6", "value": "claude-opus-4-6"}, {"label": "Claude Sonnet 4.5", "value": "claude-sonnet-4-5"}, {"label": "GPT-4o", "value": "gpt-4o"}], "value": ["claude-opus-4-6"]},
    {"id": "tools-picker", "component": "ChoicePicker", "label": "Tools", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": ["browser", "code", "search", "api"]},
    {"id": "channels-picker", "component": "ChoicePicker", "label": "Channels", "variant": "multipleSelection", "options": [{"label": "Telegram", "value": "telegram"}, {"label": "Slack", "value": "slack"}, {"label": "Discord", "value": "discord"}], "value": ["telegram", "slack", "discord"]},
    {"id": "save-btn", "component": "Button", "child": "save-btn-text", "variant": "primary", "action": {"event": {"name": "save_agent", "context": {"name": {"path": "name-field.value"}, "model": {"path": "model-picker.value"}, "tools": {"path": "tools-picker.value"}, "channels": {"path": "channels-picker.value"}}}}},
    {"id": "save-btn-text", "component": "Text", "text": "Save Agent"}
  ]}}
]
```''';

  static const _catalogId =
      'https://a2ui.org/specification/v0_9/standard_catalog.json';

  static const _createAgentResponse =
      '''Configure your new agent's intelligence and capabilities below.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-form-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "subtitle-tt", "gap-top", "name-field", "gap-name", "intel-card", "gap-1", "cap-card", "gap-2", "deploy-note", "save-btn"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "CREATE AGENT", "fontSize": 14, "fontWeight": 800, "letterSpacing": 2.0},
    {"id": "subtitle-tt", "component": "Text", "variant": "caption", "text": "AGENT ASSEMBLY \u2022 STEP 1 OF 1", "fontSize": 10, "letterSpacing": 1.5, "color": "#66AAFF"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "name-field", "component": "TextField", "label": "Agent Name", "value": "My Agent"},
    {"id": "gap-name", "component": "Gap", "height": 12},

    {"id": "intel-card", "component": "Card", "child": "intel-col"},
    {"id": "intel-col", "component": "Column", "children": ["intel-tt", "model-picker"]},
    {"id": "intel-tt", "component": "Text", "variant": "h5", "text": "INTELLIGENCE CONFIG", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "model-picker", "component": "ChoicePicker", "label": "AI Model", "variant": "mutuallyExclusive", "options": [{"label": "Claude Opus 4.6", "value": "claude-opus-4-6"}, {"label": "Claude Sonnet 4.5", "value": "claude-sonnet-4-5"}, {"label": "GPT-4o", "value": "gpt-4o"}], "value": []},

    {"id": "gap-1", "component": "Gap", "height": 8},

    {"id": "cap-card", "component": "Card", "child": "cap-col"},
    {"id": "cap-col", "component": "Column", "children": ["cap-tt", "tools-picker", "channels-picker"]},
    {"id": "cap-tt", "component": "Text", "variant": "h5", "text": "CAPABILITY MATRIX", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "tools-picker", "component": "ChoicePicker", "label": "Tools", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": []},
    {"id": "channels-picker", "component": "ChoicePicker", "label": "Channels", "variant": "multipleSelection", "options": [{"label": "Telegram", "value": "telegram"}, {"label": "Slack", "value": "slack"}, {"label": "Discord", "value": "discord"}], "value": []},

    {"id": "gap-2", "component": "Gap", "height": 16},

    {"id": "deploy-note", "component": "Text", "variant": "caption", "text": "AGENT WILL BE CREATED AND DEPLOYED TO SELECTED CHANNELS", "fontSize": 8, "color": "#888888"},
    {"id": "save-btn", "component": "Button", "child": "save-btn-text", "variant": "primary", "action": {"event": {"name": "save_agent", "context": {"name": {"path": "name-field.value"}, "model": {"path": "model-picker.value"}, "tools": {"path": "tools-picker.value"}, "channels": {"path": "channels-picker.value"}}}}},
    {"id": "save-btn-text", "component": "Text", "text": "Create Agent"}
  ]}}
]
```''';

  static const _dashboardResponse =
      '''Here are your agents. Tap an agent to view details.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "dashboard-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "dashboard-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "subtitle-tt", "gap-top", "agent-1-card"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "MY AGENTS", "fontSize": 14, "fontWeight": 800, "letterSpacing": 2.0},
    {"id": "subtitle-tt", "component": "Text", "variant": "caption", "text": "1 AGENT DEPLOYED", "fontSize": 10, "letterSpacing": 1.5, "color": "#888888"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "agent-1-card", "component": "Card", "child": "agent-1-col"},
    {"id": "agent-1-col", "component": "Column", "children": ["agent-1-header", "agent-1-status", "agent-1-meta", "agent-1-spark", "agent-1-view-btn"]},
    {"id": "agent-1-header", "component": "Text", "variant": "h5", "text": "TRAVEL CONCIERGE", "fontSize": 12, "fontWeight": 800, "letterSpacing": 1.5},
    {"id": "agent-1-status", "component": "Text", "variant": "body", "text": "\u25cf ONLINE \u2022 OPUS 4.6", "fontSize": 10, "color": "#00FF88"},
    {"id": "agent-1-meta", "component": "Text", "variant": "caption", "text": "PERSONA-DRIVEN ITINERARY PLANNING \u2022 12 TRIPS \u2022 99.7% UPTIME", "fontSize": 9, "color": "#888888"},
    {"id": "agent-1-spark", "component": "HealthSparkline", "level": "nominal", "width": 200, "height": 24, "showGlow": true, "dataPoints": [0.7, 0.8, 0.75, 0.85, 0.9, 0.88, 0.82, 0.88, 0.92, 0.85, 0.9, 0.87]},
    {"id": "agent-1-view-btn", "component": "Button", "child": "agent-1-view-text", "variant": "secondary", "action": {"event": {"name": "navigate", "context": {"text": "Plan a trip"}}}},
    {"id": "agent-1-view-text", "component": "Text", "text": "Plan Trip \u2192"}
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
    {"id": "root", "component": "Column", "children": ["title", "qr-card", "instructions", "copy-btn"]},
    {"id": "title", "component": "Text", "text": "Pair Device", "variant": "h4"},
    {"id": "qr-card", "component": "Card", "child": "qr-content"},
    {"id": "qr-content", "component": "Column", "children": ["qr-label", "qr-code", "backup-code"]},
    {"id": "qr-label", "component": "Text", "text": "Scan with your phone", "variant": "body2"},
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
      '''Command Center online. Gateway is healthy and all systems are nominal.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "manage-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "manage-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "subtitle-tt", "gap-top", "main-grid", "gap-1", "config-card", "gap-2", "action-tray"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "COMMAND CENTER", "fontSize": 14, "fontWeight": 800, "letterSpacing": 2.0},
    {"id": "subtitle-tt", "component": "Text", "variant": "caption", "text": "OPENCLAW GATEWAY v2026.2.9", "fontSize": 10, "letterSpacing": 1.5, "color": "#66AAFF"},
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
    {"id": "logs-btn-text", "component": "Text", "text": "View Audit Trail"},

    {"id": "gap-2", "component": "Gap", "height": 16},

    {"id": "action-tray", "component": "Row", "children": ["update-btn", "restart-btn", "pair-btn"]},
    {"id": "update-btn", "component": "Button", "child": "update-btn-text", "variant": "primary", "action": {"event": {"name": "update_openclaw"}}},
    {"id": "update-btn-text", "component": "Text", "text": "Check for Updates"},
    {"id": "restart-btn", "component": "Button", "child": "restart-btn-text", "variant": "secondary", "action": {"event": {"name": "restart_openclaw"}}},
    {"id": "restart-btn-text", "component": "Text", "text": "Restart Gateway"},
    {"id": "pair-btn", "component": "Button", "child": "pair-btn-text", "variant": "secondary", "action": {"event": {"name": "pair_device"}}},
    {"id": "pair-btn-text", "component": "Text", "text": "Pair Device"}
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
    {"id": "url-field", "component": "TextField", "label": "Gateway URL", "value": "ws://localhost:18789"},
    {"id": "token-field", "component": "TextField", "label": "Gateway Token", "value": ""},
    {"id": "connect-btn", "component": "Button", "child": "connect-btn-text", "variant": "primary", "action": {"event": {"name": "connect_gateway", "context": {"gateway_url": {"path": "url-field.value"}, "gateway_token": {"path": "token-field.value"}}}}},
    {"id": "connect-btn-text", "component": "Text", "text": "Connect"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Setup concierge agent
  // ---------------------------------------------------------------------------

  static const _travelSetupResponse =
      '''Travel Concierge activated. Select your destination and persona to begin mission planning.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "travel-setup-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "travel-setup-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "subtitle-tt", "gap-top", "dest-card", "gap-1", "config-card", "gap-2", "plan-btn"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "TRAVEL CONCIERGE", "fontSize": 14, "fontWeight": 800, "letterSpacing": 2.0},
    {"id": "subtitle-tt", "component": "Text", "variant": "caption", "text": "OPUS 4.6 \u2022 PERSONA-DRIVEN ITINERARY PLANNING", "fontSize": 10, "letterSpacing": 1.5, "color": "#66AAFF"},
    {"id": "gap-top", "component": "Gap", "height": 16},

    {"id": "dest-card", "component": "Card", "child": "dest-col"},
    {"id": "dest-col", "component": "Column", "children": ["dest-tt", "city-picker"]},
    {"id": "dest-tt", "component": "Text", "variant": "h5", "text": "DESTINATION SELECT", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "city-picker", "component": "ChoicePicker", "label": "Recent Destinations", "variant": "mutuallyExclusive", "options": [{"label": "Tokyo", "value": "tokyo"}, {"label": "London", "value": "london"}, {"label": "Paris", "value": "paris"}, {"label": "New York", "value": "new-york"}, {"label": "San Francisco", "value": "san-francisco"}], "value": ["tokyo"]},

    {"id": "gap-1", "component": "Gap", "height": 8},

    {"id": "config-card", "component": "Card", "child": "config-col"},
    {"id": "config-col", "component": "Column", "children": ["config-tt", "persona-picker", "days-picker", "config-note"]},
    {"id": "config-tt", "component": "Text", "variant": "h5", "text": "MISSION PARAMETERS", "fontSize": 10, "letterSpacing": 1.5},
    {"id": "persona-picker", "component": "ChoicePicker", "label": "Travel Persona", "variant": "mutuallyExclusive", "options": [{"label": "Foodie", "value": "foodie"}, {"label": "Artsy", "value": "artsy"}, {"label": "Outdoorsy", "value": "outdoorsy"}, {"label": "Budget", "value": "budget"}], "value": ["foodie"]},
    {"id": "days-picker", "component": "ChoicePicker", "label": "Trip Duration", "variant": "mutuallyExclusive", "options": [{"label": "3 Days", "value": "3"}, {"label": "5 Days", "value": "5"}, {"label": "7 Days", "value": "7"}], "value": ["3"]},
    {"id": "config-note", "component": "Text", "variant": "caption", "text": "PERSONA SHAPES RESTAURANTS, ACTIVITIES, AND HOTEL SELECTION", "fontSize": 8, "color": "#888888"},

    {"id": "gap-2", "component": "Gap", "height": 16},

    {"id": "plan-btn", "component": "Button", "child": "plan-btn-text", "variant": "primary", "action": {"event": {"name": "generate_itinerary", "context": {"city": {"path": "city-picker.value"}, "persona": {"path": "persona-picker.value"}, "days": {"path": "days-picker.value"}}}}},
    {"id": "plan-btn-text", "component": "Text", "text": "Generate Itinerary"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Travel: Tokyo overview (Foodie default) — VideoPlayer at top
  // ---------------------------------------------------------------------------

  static const _tokyoOverviewResponse =
      '''Mission briefing complete. Here's your 3-day Tokyo foodie itinerary with flights and lodging.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "tokyo-itin-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "tokyo-itin-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "subtitle-tt", "gap-1", "video", "gap-2", "trip-map", "gap-3", "days-tt", "day1-card", "gap-d1d2", "day2-card", "gap-d2d3", "day3-card", "div-hotel", "hotel-card", "div-flights", "flights-tt", "ticket1-card", "gap-t1t2", "ticket2-card", "gap-t2book", "book-card"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "TOKYO \u2014 3 DAY FOODIE ITINERARY", "fontSize": 14, "fontWeight": 800, "letterSpacing": 2.0},
    {"id": "subtitle-tt", "component": "Text", "variant": "caption", "text": "MAR 20\u201323, 2026 \u2022 OPUS 4.6 \u2022 12 RESTAURANTS \u2022 3 MARKETS", "fontSize": 10, "letterSpacing": 1.5, "color": "#66AAFF"},
    {"id": "gap-1", "component": "Gap", "height": 20},
    {"id": "video", "component": "VideoPlayer", "tripId": "tokyo-foodie-3d"},
    {"id": "gap-2", "component": "Gap", "height": 24},
    {"id": "trip-map", "component": "TripMap", "center": [35.68, 139.76], "zoom": 12, "markers": [{"lat": 35.6654, "lng": 139.7707, "label": "Tsukiji Market"}, {"lat": 35.6812, "lng": 139.7671, "label": "Ramen Street"}, {"lat": 35.6717, "lng": 139.7650, "label": "Ginza Depachika"}, {"lat": 35.6600, "lng": 139.7300, "label": "Sukiyabashi Jiro"}, {"lat": 35.6852, "lng": 139.7100, "label": "Shinjuku Gyoen"}, {"lat": 35.6940, "lng": 139.7036, "label": "Golden Gai"}, {"lat": 35.6457, "lng": 139.7835, "label": "Toyosu Market"}, {"lat": 35.6712, "lng": 139.7639, "label": "Tempura Kondo"}, {"lat": 35.7148, "lng": 139.7967, "label": "Asakusa"}, {"lat": 35.6720, "lng": 139.7252, "label": "Narisawa"}]},
    {"id": "gap-3", "component": "Gap", "height": 8},
    {"id": "days-tt", "component": "Text", "variant": "h5", "text": "ITINERARY", "fontSize": 10, "fontWeight": 800, "letterSpacing": 1.5},

    {"id": "day1-card", "component": "Card", "child": "day1-col"},
    {"id": "day1-col", "component": "Column", "children": ["day1-img", "day1-ts", "day1-title", "day1-am", "day1-lunch", "day1-pm", "day1-dinner"]},
    {"id": "day1-img", "component": "Image", "url": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800&h=300&fit=crop&auto=format", "variant": "header"},
    {"id": "day1-ts", "component": "Text", "variant": "caption", "text": "THU MAR 20 \u2022 DAY 1 OF 3", "fontSize": 9, "color": "#66AAFF"},
    {"id": "day1-title", "component": "Text", "text": "Day 1 \u2014 Tsukiji & Ginza", "variant": "h5"},
    {"id": "day1-am", "component": "Text", "text": "\ud83c\udf05 **5:30 AM** \u2022 Tsukiji Outer Market \u2014 fresh sushi breakfast at Sushi Dai (arrive early!)"},
    {"id": "day1-lunch", "component": "Text", "text": "\u2615 **12:00 PM** \u2022 Ramen Street, Tokyo Station \u2014 Rokurinsha\u2019s tsukemen"},
    {"id": "day1-pm", "component": "Text", "text": "\ud83c\udfed **3:00 PM** \u2022 Ginza depachika food halls \u2014 wagashi tasting at Toraya"},
    {"id": "day1-dinner", "component": "Text", "text": "\ud83c\udf19 **7:00 PM** \u2022 Sukiyabashi Jiro (Roppongi) \u2014 20-piece omakase"},
    {"id": "gap-d1d2", "component": "Gap", "size": "md"},

    {"id": "day2-card", "component": "Card", "child": "day2-col"},
    {"id": "day2-col", "component": "Column", "children": ["day2-img", "day2-ts", "day2-title", "day2-am", "day2-lunch", "day2-pm", "day2-dinner"]},
    {"id": "day2-img", "component": "Image", "url": "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800&h=300&fit=crop&auto=format", "variant": "header"},
    {"id": "day2-ts", "component": "Text", "variant": "caption", "text": "FRI MAR 21 \u2022 DAY 2 OF 3", "fontSize": 9, "color": "#66AAFF"},
    {"id": "day2-title", "component": "Text", "text": "Day 2 \u2014 Shinjuku & Golden Gai", "variant": "h5"},
    {"id": "day2-am", "component": "Text", "text": "\ud83c\udf05 **9:00 AM** \u2022 Shinjuku Gyoen \u2014 matcha ceremony at the imperial tea house"},
    {"id": "day2-lunch", "component": "Text", "text": "\u2615 **12:30 PM** \u2022 Fuunji \u2014 famous fish-broth tsukemen (expect 30-min queue)"},
    {"id": "day2-pm", "component": "Text", "text": "\ud83c\udfed **3:00 PM** \u2022 Takashimaya food hall + Omoide Yokocho yakitori alley"},
    {"id": "day2-dinner", "component": "Text", "text": "\ud83c\udf19 **8:00 PM** \u2022 Golden Gai bar crawl \u2014 6 tiny bars, 6 different sake"},
    {"id": "gap-d2d3", "component": "Gap", "size": "md"},

    {"id": "day3-card", "component": "Card", "child": "day3-col"},
    {"id": "day3-col", "component": "Column", "children": ["day3-img", "day3-ts", "day3-title", "day3-am", "day3-lunch", "day3-pm", "day3-dinner"]},
    {"id": "day3-img", "component": "Image", "url": "https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=800&h=300&fit=crop&auto=format", "variant": "header"},
    {"id": "day3-ts", "component": "Text", "variant": "caption", "text": "SAT MAR 22 \u2022 DAY 3 OF 3", "fontSize": 9, "color": "#66AAFF"},
    {"id": "day3-title", "component": "Text", "text": "Day 3 \u2014 Toyosu & Asakusa", "variant": "h5"},
    {"id": "day3-am", "component": "Text", "text": "\ud83c\udf05 **6:00 AM** \u2022 Toyosu Fish Market \u2014 tuna auction viewing deck (reserve online)"},
    {"id": "day3-lunch", "component": "Text", "text": "\u2615 **12:00 PM** \u2022 Tempura Kondo, Ginza \u2014 Michelin-starred sweet potato tempura"},
    {"id": "day3-pm", "component": "Text", "text": "\ud83c\udfed **3:00 PM** \u2022 Asakusa \u2014 Nakamise-dori street food (melon pan, ningyo-yaki)"},
    {"id": "day3-dinner", "component": "Text", "text": "\ud83c\udf19 **7:30 PM** \u2022 Narisawa \u2014 #12 World\u2019s 50 Best, innovative satoyama cuisine"},

    {"id": "div-hotel", "component": "Gap", "size": "lg"},

    {"id": "hotel-card", "component": "Card", "child": "hotel-col"},
    {"id": "hotel-col", "component": "Column", "children": ["hotel-badge", "hotel-img", "hotel-name", "hotel-stars", "hotel-detail", "hotel-btn"]},
    {"id": "hotel-badge", "component": "Text", "variant": "caption", "text": "RECOMMENDED STAY", "fontSize": 9, "color": "#66AAFF"},
    {"id": "hotel-img", "component": "Image", "url": "https://images.unsplash.com/photo-1590073242678-70ee3fc28e8e?w=800&h=400&fit=crop&auto=format", "variant": "header"},
    {"id": "hotel-name", "component": "Text", "text": "Hoshinoya Tokyo", "variant": "h4"},
    {"id": "hotel-stars", "component": "Text", "text": "\u2605\u2605\u2605\u2605\u2605 \u2022 Otemachi \u2022 3 nights", "variant": "caption"},
    {"id": "hotel-detail", "component": "Text", "text": "Onsen ryokan in the heart of Tokyo \u2022 **\$420/night** \u2022 Private kaiseki dining \u2022 Rooftop hot spring bath"},
    {"id": "hotel-btn", "component": "Button", "child": "hotel-btn-text", "variant": "borderless", "action": {"event": {"name": "browser_open", "context": {"url": "https://hoshinoya.com/tokyo/en/"}}}},
    {"id": "hotel-btn-text", "component": "Text", "text": "View Hotel \u2192"},

    {"id": "div-flights", "component": "Gap", "size": "lg"},
    {"id": "flights-tt", "component": "Text", "variant": "h5", "text": "ROUND-TRIP FLIGHTS", "fontSize": 10, "fontWeight": 800, "letterSpacing": 1.5},

    {"id": "ticket1-card", "component": "Card", "child": "t1-col"},
    {"id": "t1-col", "component": "Column", "children": ["t1-logo", "t1-div1", "t1-out-label", "t1-out-route", "t1-out-detail", "t1-div2", "t1-ret-label", "t1-ret-route", "t1-ret-detail", "t1-div3", "t1-price", "t1-btn"]},
    {"id": "t1-logo", "component": "Image", "url": "https://images.kiwi.com/airlines/64/NH.png", "variant": "smallFeature"},
    {"id": "t1-div1", "component": "Divider"},
    {"id": "t1-out-label", "component": "Text", "text": "OUTBOUND \u2022 Thu, Mar 20", "variant": "caption"},
    {"id": "t1-out-route", "component": "Text", "text": "SFO \u2192 HND", "variant": "h4"},
    {"id": "t1-out-detail", "component": "Text", "text": "NH007 \u2022 Direct \u2022 11h 30m \u2022 Dep 1:15 PM \u2192 Arr 5:45 PM+1"},
    {"id": "t1-div2", "component": "Divider"},
    {"id": "t1-ret-label", "component": "Text", "text": "RETURN \u2022 Sun, Mar 23", "variant": "caption"},
    {"id": "t1-ret-route", "component": "Text", "text": "HND \u2192 SFO", "variant": "h4"},
    {"id": "t1-ret-detail", "component": "Text", "text": "NH008 \u2022 Direct \u2022 9h 15m \u2022 Dep 9:55 PM \u2192 Arr 2:10 PM (same day)"},
    {"id": "t1-div3", "component": "Divider"},
    {"id": "t1-price", "component": "Text", "text": "**\$2,360** round trip \u2022 Economy", "variant": "h5"},
    {"id": "t1-btn", "component": "Button", "child": "t1-btn-text", "variant": "primary", "value": true, "action": {"event": {"name": "book_flight", "context": {"flight": "NH007/NH008", "price": 2360}}}},
    {"id": "t1-btn-text", "component": "Text", "text": "Selected ANA"},
    {"id": "gap-t1t2", "component": "Gap", "size": "md"},

    {"id": "ticket2-card", "component": "Card", "child": "t2-col"},
    {"id": "t2-col", "component": "Column", "children": ["t2-logo", "t2-div1", "t2-out-label", "t2-out-route", "t2-out-detail", "t2-div2", "t2-ret-label", "t2-ret-route", "t2-ret-detail", "t2-div3", "t2-price", "t2-btn"]},
    {"id": "t2-logo", "component": "Image", "url": "https://images.kiwi.com/airlines/64/JL.png", "variant": "smallFeature"},
    {"id": "t2-div1", "component": "Divider"},
    {"id": "t2-out-label", "component": "Text", "text": "OUTBOUND \u2022 Thu, Mar 20", "variant": "caption"},
    {"id": "t2-out-route", "component": "Text", "text": "SFO \u2192 NRT", "variant": "h4"},
    {"id": "t2-out-detail", "component": "Text", "text": "JL005 \u2022 Direct \u2022 11h 15m \u2022 Dep 11:35 AM \u2192 Arr 3:50 PM+1"},
    {"id": "t2-div2", "component": "Divider"},
    {"id": "t2-ret-label", "component": "Text", "text": "RETURN \u2022 Sun, Mar 23", "variant": "caption"},
    {"id": "t2-ret-route", "component": "Text", "text": "NRT \u2192 SFO", "variant": "h4"},
    {"id": "t2-ret-detail", "component": "Text", "text": "JL006 \u2022 Direct \u2022 9h 30m \u2022 Dep 6:30 PM \u2192 Arr 11:00 AM (same day)"},
    {"id": "t2-div3", "component": "Divider"},
    {"id": "t2-price", "component": "Text", "text": "**\$2,480** round trip \u2022 Economy", "variant": "h5"},
    {"id": "t2-btn", "component": "Button", "child": "t2-btn-text", "variant": "primary", "action": {"event": {"name": "book_flight", "context": {"flight": "JL005/JL006", "price": 2480}}}},
    {"id": "t2-btn-text", "component": "Text", "text": "Select JAL"},
    {"id": "gap-t2book", "component": "Gap", "size": "md"},

    {"id": "book-card", "component": "Card", "child": "book-col"},
    {"id": "book-col", "component": "Column", "children": ["book-summary", "book-total", "book-btn"]},
    {"id": "book-summary", "component": "Text", "text": "3 nights at Hoshinoya Tokyo + round-trip ANA flights + 12 restaurant reservations", "variant": "body2"},
    {"id": "book-total", "component": "Text", "text": "Estimated total from **\$3,740**", "variant": "h5"},
    {"id": "book-btn", "component": "Button", "child": "book-btn-text", "variant": "primary", "action": {"event": {"name": "book_trip", "context": {"city": {"path": "city-picker.value"}, "days": {"path": "days-picker.value"}, "persona": {"path": "persona-picker.value"}, "flight": "ANA"}}}},
    {"id": "book-btn-text", "component": "Text", "text": "Book Trip"}
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
    {"id": "root", "component": "Column", "children": ["title", "gap-1", "video", "gap-2", "day1-card", "gap-d1d2", "day2-card", "gap-d2d3", "day3-card", "gap-d3h", "hotel-card", "gap-hf", "flights-title", "ticket1-card", "gap-t1t2", "ticket2-card", "gap-t2book", "book-btn"]},
    {"id": "gap-d1d2", "component": "Gap", "size": "md"},
    {"id": "gap-d2d3", "component": "Gap", "size": "md"},
    {"id": "gap-d3h", "component": "Gap", "size": "lg"},
    {"id": "gap-hf", "component": "Gap", "size": "lg"},
    {"id": "gap-t1t2", "component": "Gap", "size": "md"},
    {"id": "gap-t2book", "component": "Gap", "size": "md"},
    {"id": "title", "component": "Text", "text": "Tokyo \u2014 3 Day Art & Culture Itinerary", "variant": "h4"},
    {"id": "gap-1", "component": "Gap", "height": 20},
    {"id": "gap-2", "component": "Gap", "height": 24},
    {"id": "hotel-img", "component": "Image", "url": "https://images.unsplash.com/photo-1480796927426-f609979314bd?w=800&h=400&fit=crop&auto=format", "variant": "header"},
    {"id": "hotel-name", "component": "Text", "text": "Park Hyatt Tokyo \u2022 \u2605\u2605\u2605\u2605\u2605", "variant": "h6"},
    {"id": "hotel-detail", "component": "Text", "text": "Shinjuku \u2022 Iconic Lost in Translation hotel \u2022 \$380/night \u2022 Perfect for art lovers: views of Mt. Fuji, New York Bar"},
    {"id": "day1-title", "component": "Text", "text": "Day 1 \u2014 Roppongi Art Triangle", "variant": "h5"},
    {"id": "day1-am", "component": "Text", "text": "\ud83c\udf05 Morning: Mori Art Museum \u2014 contemporary exhibits on the 53rd floor"},
    {"id": "day1-lunch", "component": "Text", "text": "\u2615 Lunch: The National Art Center cafe \u2014 Kisho Kurokawa\u2019s undulating glass facade"},
    {"id": "day1-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: 21_21 Design Sight \u2014 Tadao Ando\u2019s design museum"},
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
    {"id": "day3-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: Florilege (Aoyama) \u2014 #39 World\u2019s 50 Best, French-Japanese fusion"},
    {"id": "book-btn-text", "component": "Text", "text": "Book Trip"}
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
    {"id": "root", "component": "Column", "children": ["title", "gap-1", "video", "gap-2", "day1-card", "gap-d1d2", "day2-card", "gap-d2d3", "day3-card", "gap-d3h", "hotel-card", "gap-hf", "flights-title", "ticket1-card", "gap-t1t2", "ticket2-card", "gap-t2book", "book-btn"]},
    {"id": "gap-d1d2", "component": "Gap", "size": "md"},
    {"id": "gap-d2d3", "component": "Gap", "size": "md"},
    {"id": "gap-d3h", "component": "Gap", "size": "lg"},
    {"id": "gap-hf", "component": "Gap", "size": "lg"},
    {"id": "gap-t1t2", "component": "Gap", "size": "md"},
    {"id": "gap-t2book", "component": "Gap", "size": "md"},
    {"id": "title", "component": "Text", "text": "Tokyo \u2014 3 Day Nature & Adventure Itinerary", "variant": "h4"},
    {"id": "gap-1", "component": "Gap", "height": 20},
    {"id": "gap-2", "component": "Gap", "height": 24},
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
    {"id": "day3-am", "component": "Text", "text": "\ud83c\udf05 Morning: Kegon Falls (97m) \u2014 one of Japan\u2019s top 3 waterfalls"},
    {"id": "day3-lunch", "component": "Text", "text": "\u2615 Lunch: Yuba (tofu skin) at Nikko\u2019s famous Buddhist restaurants"},
    {"id": "day3-pm", "component": "Text", "text": "\ud83c\udfed Afternoon: Lake Chuzenji kayaking + Senjogahara marshland boardwalk"},
    {"id": "day3-dinner", "component": "Text", "text": "\ud83c\udf19 Dinner: Onsen ryokan kaiseki \u2014 soak in volcanic hot springs after a full day"},
    {"id": "book-btn-text", "component": "Text", "text": "Book Trip"}
  ]}}
]
```''';

  static const _travelConciergeDetailResponse =
      '''Agent details for Travel Concierge.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-detail-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-detail-001", "components": [
    {"id": "root", "component": "Column", "children": ["header-tt", "status-row", "gap-1", "config-card", "gap-2", "actions"]},
    {"id": "header-tt", "component": "Text", "variant": "h4", "text": "AGENT: TRAVEL CONCIERGE", "fontSize": 14, "fontWeight": 800},
    {"id": "status-row", "component": "Row", "children": ["status-spark", "status-tt"]},
    {"id": "status-spark", "component": "HealthSparkline", "level": "nominal", "width": 60, "height": 20, "showGlow": true},
    {"id": "status-tt", "component": "Text", "variant": "body", "text": "NOMINAL \u2022 OPUS 4.6", "fontSize": 10, "color": "#00FF88"},
    {"id": "gap-1", "component": "Gap", "height": 16},
    {"id": "config-card", "component": "Card", "child": "config-col"},
    {"id": "config-col", "component": "Column", "children": ["cfg-tt", "cfg-desc"]},
    {"id": "cfg-tt", "component": "Text", "variant": "h5", "text": "CONFIGURATION", "fontSize": 10},
    {"id": "cfg-desc", "component": "Text", "text": "Specialized in high-reasoning itinerary planning and persona-driven discovery."},
    {"id": "gap-2", "component": "Gap", "height": 16},
    {"id": "actions", "component": "Row", "children": ["engage-btn", "delete-btn"]},
    {"id": "engage-btn", "component": "Button", "child": "engage-tt", "variant": "primary", "action": {"event": {"name": "navigate", "context": {"text": "Plan a trip"}}}},
    {"id": "engage-tt", "component": "Text", "variant": "body", "text": "ENGAGE"},
    {"id": "delete-btn", "component": "Button", "child": "delete-tt", "variant": "secondary", "action": {"event": {"name": "navigate", "context": {"text": "Delete agent"}}}},
    {"id": "delete-tt", "component": "Text", "variant": "body", "text": "DEcommission", "color": "#FF4444"}
  ]}}
]
```''';
}
