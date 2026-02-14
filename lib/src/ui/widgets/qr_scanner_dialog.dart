import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();

  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Gateway QR'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                return switch (state.torchState) {
                  TorchState.off => const Icon(
                    Icons.flash_off,
                    color: Colors.grey,
                  ),
                  TorchState.on => const Icon(
                    Icons.flash_on,
                    color: Colors.yellow,
                  ),
                  TorchState.auto || TorchState.unavailable => const Icon(
                    Icons.flash_auto,
                    color: Colors.grey,
                  ),
                };
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                return switch (state.cameraDirection) {
                  CameraFacing.front => const Icon(Icons.camera_front),
                  _ => const Icon(Icons.camera_rear),
                };
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              _scanned = true;
              Navigator.of(context).pop(code);
            }
          }
        },
      ),
    );
  }
}
