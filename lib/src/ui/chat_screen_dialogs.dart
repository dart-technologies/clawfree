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
                        : 'SETTINGS',
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (activeAgent != null)
                    Text(
                      'ACTIVE AGENT',
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 9,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(ClawfreeIcons.add),
            title: Text(
              'NEW AGENT',
              style: ClawfreeTheme.technicalStyle(context: context, fontSize: 13),
            ),
            onTap: () {
              Navigator.pop(context);
              onSend('Create a new agent');
            },
          ),
          ListTile(
            leading: const Icon(ClawfreeIcons.settings),
            title: Text(
              'MANAGE OPENCLAW',
              style: ClawfreeTheme.technicalStyle(context: context, fontSize: 13),
            ),
            onTap: () {
              Navigator.pop(context);
              onSend('Manage OpenClaw');
            },
          ),
          ListTile(
            leading: const Icon(ClawfreeIcons.watch),
            title: Text(
              'PAIR WATCH',
              style: ClawfreeTheme.technicalStyle(context: context, fontSize: 13),
            ),
            onTap: () {
              Navigator.pop(context);
              onShowPairing(session.pairingUrl);
            },
          ),
          ListTile(
            leading: const Icon(ClawfreeIcons.skills),
            title: Text(
              'SKILL LIBRARY',
              style: ClawfreeTheme.technicalStyle(context: context, fontSize: 13),
            ),
            onTap: () {
              Navigator.pop(context);
              onSend('Show skill library');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(ClawfreeIcons.download),
            title: Text(
              'EXPORT AGENT CONFIG',
              style: ClawfreeTheme.technicalStyle(context: context, fontSize: 13),
            ),
            onTap: () {
              Navigator.pop(context);
              onExportConfig();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0-OPUS4.6',
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 9,
                color: ClawfreeTheme.hudTextFaint,
              ),
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
                  const SnackBar(content: Text('COPIED TO CLIPBOARD')),
                );
              },
              icon: const Icon(ClawfreeIcons.copy, size: 16),
              label: Text(
                'COPY',
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CLOSE',
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
              Text(
                'PAIR A DEVICE',
                style: ClawfreeTheme.technicalStyle(
                  context: ctx,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
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
                    'SCAN WITH YOUR DEVICE TO PAIR.',
                    style: ClawfreeTheme.technicalStyle(
                      context: ctx,
                      fontSize: 10,
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
                label: Text(
                  'SCAN QR',
                  style: ClawfreeTheme.technicalStyle(
                    context: ctx,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pairingUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PAIRING LINK COPIED')),
                );
              },
              icon: const Icon(ClawfreeIcons.copy, size: 16),
              label: Text(
                'COPY LINK',
                style: ClawfreeTheme.technicalStyle(
                  context: ctx,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'DONE',
                style: ClawfreeTheme.technicalStyle(
                  context: ctx,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(ctx).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
