import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:clawfree/src/video/video_image_downloader.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProviderPlatform(this.tempPath);
  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  late MockHttpClient mockClient;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() async {
    mockClient = MockHttpClient();
    tempDir = await Directory.systemTemp.createTemp('video_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VideoImageDownloader', () {
    test('downloadAll downloads images to cache directory', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('fake-image-data', 200),
      );

      final paths = await VideoImageDownloader.downloadAll(client: mockClient);

      expect(paths.length, VideoImageDownloader.segmentCount);
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue);
        expect(await File(path).readAsString(), 'fake-image-data');
      }
      
      // Verify second call uses cache (no more HTTP calls)
      reset(mockClient);
      final cachedPaths = await VideoImageDownloader.downloadAll(client: mockClient);
      expect(cachedPaths, paths);
      verifyNever(() => mockClient.get(any()));
    });

    test('downloadAll throws on HTTP error', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => VideoImageDownloader.downloadAll(client: mockClient),
        throwsA(isA<HttpException>()),
      );
    });

    test('getCacheDir creates directory', () async {
      final cacheDir = await VideoImageDownloader.getCacheDir();
      expect(Directory(cacheDir).existsSync(), isTrue);
      expect(cacheDir, contains('clawfree_video'));
    });
  });
}
