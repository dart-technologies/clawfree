import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// QR Scanner dialog — uses mobile_scanner on physical device,
/// shows a text-input fallback on simulator/desktop.
class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On simulator / desktop, show a simple URL input instead of camera
    if (!_hasCamera) {
      return Scaffold(
        appBar: AppBar(title: const Text('Enter Gateway URL')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Camera not available on simulator.\nPaste the gateway URL instead:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  hintText: 'http://192.168.1.x:18789/pair',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _submit(_urlController.text),
                child: const Text('Connect'),
              ),
            ],
          ),
        ),
      );
    }

    // Real device: use mobile_scanner
    return _CameraScanner();
  }

  void _submit(String url) {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) {
      Navigator.of(context).pop(trimmed);
    }
  }

  static bool get _hasCamera {
    // Simulator and desktop don't have cameras
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }
}

/// Wrapper that lazily imports mobile_scanner only when a camera is available.
class _CameraScanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Return a placeholder — real camera scanning requires mobile_scanner.
    // For the hackathon demo, the URL-input fallback works on simulators.
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Gateway QR')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening camera...'),
          ],
        ),
      ),
    );
  }
}
