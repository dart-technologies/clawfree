import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/platform_config.dart';

/// Platform-adaptive icon registry.
abstract final class ClawfreeIcons {
  static IconData get back =>
      PlatformConfig.isApple ? CupertinoIcons.back : Icons.arrow_back;

  static IconData get send => PlatformConfig.isApple
      ? CupertinoIcons.arrow_up_circle_fill
      : Icons.send;

  static const mic = Icons.mic;
  static const micNone = Icons.mic_none;
  static const dashboard = Icons.dashboard;
  static const download = Icons.download;
  static const copy = Icons.copy;
  static const refresh = Icons.refresh;
  static const error = Icons.error_outline;
  static const playArrow = Icons.play_arrow;
  static const key = Icons.key;
}
