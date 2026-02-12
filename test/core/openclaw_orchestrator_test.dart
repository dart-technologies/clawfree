import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/openclaw_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AgentStore agentStore;
  late OpenClawOrchestrator orchestrator;

  setUp(() {
    agentStore = AgentStore();
    orchestrator = OpenClawOrchestrator(agentStore: agentStore);
  });

  group('commandForAction', () {
    test('returns command for update_system', () {
      final cmd = orchestrator.commandForAction('update_system', {});
      expect(cmd, isNotNull);
      expect(cmd!.cliCommand, 'openclaw upgrade');
      expect(cmd.logMessage, contains('openclaw upgrade'));
    });

    test('returns command for check_health', () {
      final cmd = orchestrator.commandForAction('check_health', {});
      expect(cmd, isNotNull);
      expect(cmd!.cliCommand, 'openclaw status --json');
    });

    test('returns command for update_api_key (no CLI)', () {
      final cmd = orchestrator.commandForAction('update_api_key', {});
      expect(cmd, isNotNull);
      expect(cmd!.cliCommand, isNull);
      expect(cmd.ttsMessage, contains('API key'));
    });

    test('returns command for restart_channel', () {
      final cmd = orchestrator.commandForAction('restart_channel', {});
      expect(cmd, isNotNull);
      expect(cmd!.cliCommand, contains('install-daemon'));
    });

    test('returns command for show_logs', () {
      final cmd = orchestrator.commandForAction('show_logs', {});
      expect(cmd, isNotNull);
      expect(cmd!.displayMessage, contains('log'));
    });

    test('clear_agents clears the agent store', () {
      agentStore.addAgent({'name': 'TestBot'});
      expect(agentStore.count, 1);
      orchestrator.commandForAction('clear_agents', {});
      expect(agentStore.count, 0);
    });

    test('returns command for system_restart', () {
      final cmd = orchestrator.commandForAction('system_restart', {});
      expect(cmd, isNotNull);
      expect(cmd!.ttsMessage, contains('Restarting'));
    });

    test('returns command for system_upgrade', () {
      final cmd = orchestrator.commandForAction('system_upgrade', {});
      expect(cmd, isNotNull);
      expect(cmd!.cliCommand, 'openclaw upgrade');
    });

    test('returns command for system_notify', () {
      final cmd = orchestrator.commandForAction('system_notify', {});
      expect(cmd, isNotNull);
      expect(cmd!.displayMessage, contains('Notification'));
    });

    test('returns command for system_run', () {
      final cmd = orchestrator.commandForAction('system_run', {});
      expect(cmd, isNotNull);
      expect(cmd!.ttsMessage, contains('approval'));
    });

    test('returns command for location_request', () {
      final cmd = orchestrator.commandForAction('location_request', {});
      expect(cmd, isNotNull);
      expect(cmd!.ttsMessage, contains('location'));
    });

    test('returns null for unknown action', () {
      final cmd = orchestrator.commandForAction('unknown_action', {});
      expect(cmd, isNull);
    });
  });

  group('buildOnboardCommand', () {
    test('without API key', () {
      final cmd = orchestrator.buildOnboardCommand();
      expect(cmd, contains('--mode anthropic'));
      expect(cmd, contains('--auth key'));
      expect(cmd, contains('--install-daemon'));
      expect(cmd, contains('--non-interactive'));
      expect(cmd, contains('--json'));
      expect(cmd, isNot(contains('--api-key')));
    });

    test('with API key', () {
      final cmd = orchestrator.buildOnboardCommand(apiKey: 'sk-test-123');
      expect(cmd, contains('--api-key sk-test-123'));
    });

    test('with empty API key omits flag', () {
      final cmd = orchestrator.buildOnboardCommand(apiKey: '');
      expect(cmd, isNot(contains('--api-key')));
    });
  });
}
