import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:genui/genui.dart';

import '../core/platform_config.dart';
import 'video_image_downloader.dart';

/// Progress callback: fraction 0.0–1.0 and a human-readable stage label.
typedef VideoGenerationProgress = void Function(double fraction, String stage);

/// Generates an MP4 video from downloaded itinerary images using FFmpeg.
///
/// On iOS (iPhone), FFmpeg is stubbed out because the ffmpeg_kit binary
/// lacks an arm64-simulator slice, causing linker failures on Apple Silicon.
/// All other platforms (macOS, Android, web) use the real FFmpeg pipeline.
class ItineraryVideoGenerator {
  /// Duration each slide is shown, in seconds.
  static const _slideDuration = 3;

  /// Output video framerate.
  static const _fps = 30;

  static Future<String> outputPath() async {
    final cacheDir = await VideoImageDownloader.getCacheDir();
    return '$cacheDir/tokyo_preview.mp4';
  }

  static Future<String> generate({
    required List<String> imagePaths,
    VideoGenerationProgress? onProgress,
  }) async {
    // iOS stub: FFmpeg binary is not available on iPhone simulators (arm64).
    if (PlatformConfig.isIOS) {
      genUiLogger.info(
        'ItineraryVideoGenerator: Stubbed on iOS (no FFmpeg arm64-sim slice).',
      );
      onProgress?.call(1.0, 'Video generation unavailable on iOS');
      throw UnsupportedError(
        'Video generation is not available on iOS. '
        'FFmpeg lacks an arm64-simulator slice.',
      );
    }

    if (imagePaths.isEmpty) {
      throw ArgumentError('imagePaths must not be empty');
    }

    final outPath = await outputPath();
    final outFile = File(outPath);
    if (outFile.existsSync()) {
      genUiLogger.info('ItineraryVideoGenerator: Cache hit — $outPath');
      onProgress?.call(1.0, 'Using cached video');
      return outPath;
    }

    onProgress?.call(0.0, 'Preparing FFmpeg pipeline');

    // Build a concat demuxer input file listing each image for _slideDuration.
    final cacheDir = await VideoImageDownloader.getCacheDir();
    final concatFile = File('$cacheDir/concat.txt');
    final concatLines = StringBuffer();
    for (final path in imagePaths) {
      concatLines.writeln("file '$path'");
      concatLines.writeln('duration $_slideDuration');
    }
    // Repeat last image to avoid FFmpeg cutting it short.
    concatLines.writeln("file '${imagePaths.last}'");
    await concatFile.writeAsString(concatLines.toString());

    onProgress?.call(0.1, 'Encoding video');

    // FFmpeg command: concat demuxer → scale to 1280x720 → H.264 MP4.
    final command = [
      '-y',
      '-f', 'concat',
      '-safe', '0',
      '-i', concatFile.path,
      '-vf', 'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2',
      '-c:v', 'libx264',
      '-pix_fmt', 'yuv420p',
      '-r', '$_fps',
      '-preset', 'ultrafast',
      '-crf', '23',
      outPath,
    ].join(' ');

    genUiLogger.info('ItineraryVideoGenerator: Running FFmpeg');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      genUiLogger.info('ItineraryVideoGenerator: Success — $outPath');
      onProgress?.call(1.0, 'Video ready');
      return outPath;
    }

    final logs = await session.getLogsAsString();
    genUiLogger.severe('ItineraryVideoGenerator: FFmpeg failed\n$logs');
    throw Exception('FFmpeg encoding failed (code: ${returnCode?.getValue()})');
  }
}
