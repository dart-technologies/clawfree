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
/// This version supports the iOS arm64-simulator through a patched XCFramework.
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
    if (imagePaths.isEmpty) {
      throw ArgumentError('imagePaths must not be empty');
    }

    // Verify all input images exist before starting
    for (final path in imagePaths) {
      if (!File(path).existsSync()) {
        throw FileSystemException('Input image does not exist', path);
      }
    }

    final outPath = await outputPath();
    final outFile = File(outPath);
    if (outFile.existsSync()) {
      genUiLogger.info('ItineraryVideoGenerator: Cache hit — $outPath');
      onProgress?.call(1.0, 'Using cached video');
      return outPath;
    }

    onProgress?.call(0.0, 'Preparing FFmpeg pipeline');

    final cacheDir = await VideoImageDownloader.getCacheDir();
    final concatFile = File('$cacheDir/concat.txt');
    
    try {
      // Build a concat demuxer input file listing each image for _slideDuration.
      final concatLines = StringBuffer();
      for (final path in imagePaths) {
        // Paths in concat file must be escaped/quoted for FFmpeg
        final escapedPath = path.replaceAll("'", "'\\''");
        concatLines.writeln("file '$escapedPath'");
        concatLines.writeln('duration $_slideDuration');
      }
      // Repeat last image to avoid FFmpeg cutting it short (required by concat demuxer)
      final lastEscapedPath = imagePaths.last.replaceAll("'", "'\\''");
      concatLines.writeln("file '$lastEscapedPath'");
      
      await concatFile.writeAsString(concatLines.toString());

      onProgress?.call(0.1, 'Encoding video');

      final escapedConcatPath = concatFile.path.replaceAll("'", "'\\''");
      final escapedOutPath = outPath.replaceAll("'", "'\\''");

      // FFmpeg command: concat demuxer → scale to 1280x720 → H.264 MP4.
      // We quote all paths for safety against spaces/special characters.
      final command = [
        '-y',
        '-f', 'concat',
        '-safe', '0',
        '-i', "'$escapedConcatPath'",
        '-vf', '"scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2"',
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        '-r', '$_fps',
        '-preset', 'ultrafast',
        '-crf', '23',
        "'$escapedOutPath'",
      ].join(' ');

      genUiLogger.info('ItineraryVideoGenerator: Running FFmpeg command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        genUiLogger.info('ItineraryVideoGenerator: Success — $outPath');
        onProgress?.call(1.0, 'Video ready');
        return outPath;
      }

      final logs = await session.getLogsAsString();
      genUiLogger.severe('ItineraryVideoGenerator: FFmpeg failed (code: ${returnCode?.getValue()})\n$logs');
      throw Exception('FFmpeg encoding failed. See logs for details.');
    } catch (e, stack) {
      genUiLogger.severe('ItineraryVideoGenerator: Unexpected error', e, stack);
      rethrow;
    } finally {
      // Cleanup the temporary concat file
      if (concatFile.existsSync()) {
        try {
          await concatFile.delete();
        } catch (cleanupError) {
          genUiLogger.warning('ItineraryVideoGenerator: Failed to cleanup concat file', cleanupError);
        }
      }
    }
  }
}
