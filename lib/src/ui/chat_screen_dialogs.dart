import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/chat_session.dart';
import '../core/platform_config.dart';
import 'clawfree_assets.dart';
import 'clawfree_icons.dart';
import 'theme.dart';
import 'widgets/qr_scanner_dialog.dart';

/// Static dialog and drawer builders extracted from ChatScreen.
class ChatScreenDialogs {
  ChatScreenDialogs._();

  /// Builds the navigation drawer.
  static Widget buildDrawer(
    BuildContext context, {
    required ChatSession session,
    required ValueChanged<String> onSend,
    required VoidCallback onExportConfig,
    required void Function(String pairingUrl) onShowPairing,
  }) {
    final agents = session.agentStore.agents;
    final activeAgent =
        agents.isNotEmpty ? agents.last['name'] as String? : null;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClawfreeLogo(size: 48),
                  const SizedBox(height: 12),
                  Text(
                    activeAgent != null
                        ? activeAgent.toUpperCase()
                        : 'clawfree settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (activeAgent != null)
                    Text(
                      'ACTIVE AGENT',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New Agent'),
            onTap: () {
              Navigator.pop(context);
              onSend('Create a new agent');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Manage OpenClaw'),
            onTap: () {
              Navigator.pop(context);
              onSend('Manage OpenClaw');
            },
          ),
          ListTile(
            leading: const Icon(Icons.watch),
            title: const Text('Pair Watch'),
            onTap: () {
              Navigator.pop(context);
              onShowPairing(session.pairingUrl);
            },
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Skill Library'),
            onTap: () {
              Navigator.pop(context);
              onSend('Show skill library');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(ClawfreeIcons.download),
            title: const Text('Export Agent Config'),
            onTap: () {
              Navigator.pop(context);
              onExportConfig();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0-opus4.6',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows an export config dialog or snackbar if no config exists.
  static void showExportConfig(BuildContext context, ChatSession session) {
    HapticFeedback.lightImpact();
    final config = session.exportAgentConfig();
    if (config != null) {
      final json = const JsonEncoder.withIndent('  ').convert(config);
      final agentName = config['name'] ?? 'Agent';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$agentName (OpenClaw)'),
          content: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: json));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(ClawfreeIcons.copy, size: 16),
              label: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No agent config to export. Create an agent first.'),
        ),
      );
    }
  }

  /// Shows the QR pairing modal dialog.
  static void showPairingModal(
    BuildContext context, {
    required String pairingUrl,
    required ChatSession session,
    required void Function(String link) onHandlePairingLink,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final screenWidth = MediaQuery.sizeOf(ctx).width;
        final qrSize = (screenWidth * 0.65).clamp(200.0, 320.0);

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.qr_code_2, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Pair a Device'),
            ],
          ),
          content: SizedBox(
            width: qrSize + 40,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: ClawfreeBorderRadius.element,
                    ),
                    child: QrImageView(
                      data: pairingUrl,
                      version: QrVersions.auto,
                      size: qrSize,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.circle,
                        color: Color(0xFF1A1A2E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    pairingUrl,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan with your device to pair.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (PlatformConfig.hasCamera)
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const QrScannerDialog()),
                  );
                  if (result != null && ctx.mounted) {
                    onHandlePairingLink(result);
                    Navigator.pop(ctx);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pairingUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pairing link copied')),
                );
              },
              icon: const Icon(ClawfreeIcons.copy, size: 16),
              label: const Text('Copy Link'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}
