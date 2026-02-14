import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Progress callback: current index (0-based), total count, file path.
typedef DownloadProgress = void Function(int current, int total, String path);

/// Downloads hardcoded Unsplash images for the Tokyo foodie itinerary preview.
///
/// Images are cached in a `clawfree_video` subdirectory of the temp directory.
/// If a file already exists it is skipped (instant replay during demo).
class VideoImageDownloader {
  static const _imageSpecs = <_ImageSpec>[
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_0.jpg',
      label: 'Tokyo skyline at dusk',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_1.jpg',
      label: 'Tsukiji fish market',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_2.jpg',
      label: 'Fresh sushi close-up',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_3.jpg',
      label: 'Steaming ramen bowl',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_4.jpg',
      label: 'Shinjuku neon lights',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_5.jpg',
      label: 'Japanese garden matcha',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1554797589-7241bb691973?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_6.jpg',
      label: 'Golden Gai bar alley',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1580442151529-343f2f6e0e27?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_7.jpg',
      label: 'Fish market interior',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1523539693385-e5e891eb4465?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_8.jpg',
      label: 'Tuna auction scene',
    ),
    _ImageSpec(
      url:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1280&h=720&fit=crop&auto=format',
      filename: 'slide_9.jpg',
      label: 'Fine dining plating',
    ),
  ];

  /// Text overlays for each segment (line 1 / line 2).
  static const overlayLabels = <(String, String)>[
    ('Tokyo', '3 Day Foodie Adventure'),
    ('Day 1 — Tsukiji & Ginza', ''),
    ('Sushi Dai', 'Arrive 5:30 AM'),
    ('Ramen Street', 'Rokurinsha'),
    ('Day 2 — Shinjuku & Golden Gai', ''),
    ('Shinjuku Gyoen', 'Matcha Tea'),
    ('Golden Gai', '6 Bars, 6 Sake'),
    ('Day 3 — Toyosu & Asakusa', ''),
    ('Toyosu', 'Tuna Auction Deck'),
    ('Narisawa', 'No.12 Worlds 50 Best'),
  ];

  /// Number of images / segments.
  static int get segmentCount => _imageSpecs.length;

  /// Returns the cache directory path, creating it if needed.
  static Future<String> getCacheDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/clawfree_video');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Downloads all images, returning the list of local file paths.
  ///
  /// Skips images that already exist on disk (cache hit).
  static Future<List<String>> downloadAll({
    DownloadProgress? onProgress,
  }) async {
    final cacheDir = await getCacheDir();
    final paths = <String>[];
    final client = http.Client();

    try {
      for (var i = 0; i < _imageSpecs.length; i++) {
        final spec = _imageSpecs[i];
        final filePath = '$cacheDir/${spec.filename}';
        final file = File(filePath);

        if (!file.existsSync()) {
          final response = await client.get(Uri.parse(spec.url));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            throw HttpException(
              'Failed to download ${spec.label}: HTTP ${response.statusCode}',
            );
          }
        }

        paths.add(filePath);
        onProgress?.call(i + 1, _imageSpecs.length, filePath);
      }
    } finally {
      client.close();
    }

    return paths;
  }
}

class _ImageSpec {
  const _ImageSpec({
    required this.url,
    required this.filename,
    required this.label,
  });

  final String url;
  final String filename;
  final String label;
}
