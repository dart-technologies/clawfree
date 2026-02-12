import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import '../ui/health/health_state.dart';
import 'gateway_client.dart';
import 'remote_session.dart';

/// Periodically polls the gateway `/health` endpoint and maps the response
/// to a [HealthState] for the UI layer.
class HealthPoller extends ChangeNotifier {
  HealthPoller({
    required GatewayClient gatewayClient,
    Duration interval = const Duration(seconds: 15),
    List<RemoteSession> demoSessions = const [],
    String? selfSessionId,
  })  : _gatewayClient = gatewayClient,
        _interval = interval,
        _demoSessions = demoSessions,
        _selfSessionId = selfSessionId;

  final GatewayClient _gatewayClient;
  final Duration _interval;
  final List<RemoteSession> _demoSessions;
  final String? _selfSessionId;
  Timer? _timer;

  HealthState _state = HealthState.nominal();
  int _consecutiveErrors = 0;
  List<RemoteSession> _sessions = [];
  int _consecutiveSessionErrors = 0;

  /// Current health state derived from the latest poll.
  HealthState get state => _state;

  /// Connected remote sessions from the latest poll.
  List<RemoteSession> get sessions => _sessions;

  /// Start polling: immediate first poll, then periodic.
  void start() {
    _poll();
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  /// Stop the periodic timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Perform a single poll (useful after connect).
  Future<void> pollOnce() => _poll();

  Future<void> _poll() async {
    // Fire health and sessions in parallel.
    final healthFuture = _gatewayClient.health();
    final sessionsFuture = _gatewayClient.fetchSessions().catchError(
      (Object _) => <Map<String, dynamic>>[],
    );

    final results = await Future.wait([
      healthFuture.then<Object?>((v) => v).catchError((Object e) => e),
      sessionsFuture,
    ]);

    // Process health result.
    final healthResult = results[0];
    if (healthResult is GatewayHealthResponse) {
      _consecutiveErrors = 0;
      _state = _mapResponseToState(healthResult);
    } else {
      _consecutiveErrors++;
      genUiLogger.warning(
        'Health poll failed ($_consecutiveErrors): $healthResult',
      );
      if (_consecutiveErrors >= 3) {
        _state = HealthState(
          gateway: const HealthSection(
            id: 'LINK',
            label: 'Connectivity',
            level: HealthLevel.error,
            detail: 'Unreachable',
          ),
        );
      }
    }

    // Process sessions result.
    final sessionMaps = results[1] as List<Map<String, dynamic>>;
    if (sessionMaps.isNotEmpty) {
      _consecutiveSessionErrors = 0;
      _sessions = sessionMaps
          .map(RemoteSession.fromJson)
          .where((s) => _selfSessionId == null || s.sessionId != _selfSessionId)
          .toList();
    } else {
      _consecutiveSessionErrors++;
      if (_consecutiveSessionErrors >= 3) {
        _sessions = _demoSessions;
      }
    }

    notifyListeners();
  }

  HealthState _mapResponseToState(GatewayHealthResponse response) {
    // Gateway section
    final gwLevel = response.status == 'ok'
        ? HealthLevel.nominal
        : response.status == 'degraded'
            ? HealthLevel.degraded
            : HealthLevel.error;
    final gateway = HealthSection(
      id: 'LINK',
      label: 'Connectivity',
      level: gwLevel,
      detail: '${response.latencyMs}ms',
    );

    // Thinking section — infer from status and agents count
    final llmLevel =
        response.status == 'ok' ? HealthLevel.nominal : HealthLevel.degraded;
    final llm = HealthSection(
      id: 'THINK',
      label: 'Thinking',
      level: llmLevel,
      detail: response.version,
    );

    // Reach section (channels)
    final channelMap = response.channels;
    final totalChannels = channelMap.length;
    final activeChannels =
        channelMap.values.where((v) => v == 'active').length;
    final chanLevel = totalChannels == 0
        ? HealthLevel.nominal
        : activeChannels == totalChannels
            ? HealthLevel.nominal
            : activeChannels > 0
                ? HealthLevel.degraded
                : HealthLevel.error;
    final channels = HealthSection(
      id: 'REACH',
      label: 'Reach',
      level: chanLevel,
      detail: totalChannels > 0 ? '$activeChannels/$totalChannels active' : '',
    );

    // Skills section — nominal when gateway is ok
    final tools = HealthSection(
      id: 'SKILL',
      label: 'Skills',
      level: gwLevel == HealthLevel.nominal
          ? HealthLevel.nominal
          : HealthLevel.degraded,
    );

    // Listening section — nominal when gateway is ok
    final voice = HealthSection(
      id: 'EAR',
      label: 'Listening',
      level: gwLevel == HealthLevel.nominal
          ? HealthLevel.nominal
          : HealthLevel.degraded,
    );

    return HealthState(
      gateway: gateway,
      llm: llm,
      channels: channels,
      tools: tools,
      voice: voice,
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
