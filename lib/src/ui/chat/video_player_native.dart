import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../video/itinerary_video_generator.dart';
import '../../video/video_image_downloader.dart';
import '../theme.dart';

/// Native-only video player: downloads images → FFmpeg → plays .mp4.
///
/// This file is conditionally imported only on platforms that have dart:io.
class NativeVideoPlayer extends StatefulWidget {
  const NativeVideoPlayer({super.key, this.tripId, this.filePath});

  final String? tripId;
  final String? filePath;

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

enum _NativeState { generating, playing, error }

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  _NativeState _state = _NativeState.generating;
  double _progress = 0;
  String _stage = 'Preparing...';
  String? _errorMessage;

  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      String videoPath;

      if (widget.filePath != null && File(widget.filePath!).existsSync()) {
        videoPath = widget.filePath!;
      } else {
        setState(() {
          _stage = 'Downloading images...';
          _progress = 0;
        });

        final imagePaths = await VideoImageDownloader.downloadAll(
          onProgress: (current, total, _) {
            if (mounted) {
              setState(() {
                _progress = current / total * 0.3;
                _stage = 'Downloading image $current/$total';
              });
            }
          },
        );

        videoPath = await ItineraryVideoGenerator.generate(
          imagePaths: imagePaths,
          onProgress: (fraction, stage) {
            if (mounted) {
              setState(() {
                _progress = 0.3 + fraction * 0.7;
                _stage = stage;
              });
            }
          },
        );
      }

      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      controller.addListener(_onVideoTick);
      await controller.play();

      if (mounted) {
        setState(() {
          _controller = controller;
          _state = _NativeState.playing;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _NativeState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: ClawfreeBorderRadius.element,
        child: switch (_state) {
          _NativeState.generating => _buildGenerating(),
          _NativeState.playing => _buildPlayer(),
          _NativeState.error => _buildError(),
        },
      ),
    );
  }

  Widget _buildGenerating() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.movie_creation_outlined,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _stage,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: ClawfreeBorderRadius.tiny,
                child: LinearProgressIndicator(
                  value: _progress.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.cyanAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final position = controller.value.position;
    final duration = controller.value.duration;
    final isPlaying = controller.value.isPlaying;

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: Colors.cyanAccent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0,
                  onChanged: (v) {
                    controller.seekTo(
                      Duration(
                        milliseconds: (v * duration.inMilliseconds).toInt(),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      isPlaying ? controller.pause() : controller.play();
                    },
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmt(position)} / ${_fmt(duration)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Video generation failed',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _state = _NativeState.generating;
                  _progress = 0;
                  _stage = 'Retrying...';
                });
                _initVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
