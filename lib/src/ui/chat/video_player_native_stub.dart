import 'package:flutter/material.dart';

/// Stub for web compilation — never instantiated at runtime (kIsWeb guard).
class NativeVideoPlayer extends StatelessWidget {
  const NativeVideoPlayer({super.key, this.tripId, this.filePath});

  final String? tripId;
  final String? filePath;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
