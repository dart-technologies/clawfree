import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/video/itinerary_video_generator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

class MockPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

class MockFFmpegSession extends Mock implements FFmpegSession {}

class MockFFmpegExecutor extends Mock implements FFmpegExecutor {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockFFmpegExecutor mockExecutor;

  setUpAll(() {
    PathProviderPlatform.instance = MockPathProvider();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('itinerary_video_test');
    mockExecutor = MockFFmpegExecutor();
    
    // Clean up shared cache directory to avoid test interference
    final cacheDir = Directory('${Directory.systemTemp.path}/clawfree_video');
    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ItineraryVideoGenerator', () {
    test('throws ArgumentError if imagePaths is empty', () async {
      expect(
        () => ItineraryVideoGenerator.generate(imagePaths: []),
        throwsArgumentError,
      );
    });

    test('throws FileSystemException if an image does not exist', () async {
      final missingPath = '${tempDir.path}/missing.jpg';
      expect(
        () => ItineraryVideoGenerator.generate(imagePaths: [missingPath]),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('returns cached path if video already exists', () async {
      final image = File('${tempDir.path}/image.jpg')..createSync();
      
      final cacheDir = Directory('${Directory.systemTemp.path}/clawfree_video');
      if (!cacheDir.existsSync()) await cacheDir.create(recursive: true);
      
      final outPath = '${cacheDir.path}/tokyo_preview.mp4';
      final outFile = File(outPath);
      await outFile.writeAsString('fake video data');

      final result = await ItineraryVideoGenerator.generate(
        imagePaths: [image.path],
        executor: mockExecutor,
      );

      expect(result, outPath);
      verifyNever(() => mockExecutor.execute(any()));
    });

    test('generates video successfully with escaping', () async {
      final image1 = File('${tempDir.path}/image 1.jpg')..createSync();
      final image2 = File("${tempDir.path}/image'2.jpg")..createSync();
      
      final mockSession = MockFFmpegSession();
      when(() => mockSession.getReturnCode()).thenAnswer((_) async => ReturnCode(0));
      when(() => mockExecutor.execute(any())).thenAnswer((_) async => mockSession);

      final progressStages = <String>[];
      final result = await ItineraryVideoGenerator.generate(
        imagePaths: [image1.path, image2.path],
        executor: mockExecutor,
        onProgress: (fraction, stage) => progressStages.add(stage),
      );

      expect(result, contains('tokyo_preview.mp4'));
      
      final captured = verify(() => mockExecutor.execute(captureAny())).captured.single as String;
      expect(captured, contains('-f concat'));
      expect(captured, contains('concat.txt'));
      expect(captured, contains('tokyo_preview.mp4'));
      
      expect(progressStages, contains('Encoding video'));
      expect(progressStages, contains('Video ready'));
    });

    test('throws exception if FFmpeg fails', () async {
      final image = File('${tempDir.path}/image.jpg')..createSync();
      final mockSession = MockFFmpegSession();
      when(() => mockSession.getReturnCode()).thenAnswer((_) async => ReturnCode(1));
      when(() => mockSession.getLogsAsString()).thenAnswer((_) async => 'Error: invalid codec');
      when(() => mockExecutor.execute(any())).thenAnswer((_) async => mockSession);

      expect(
        ItineraryVideoGenerator.generate(
          imagePaths: [image.path],
          executor: mockExecutor,
        ),
        throwsA(predicate((e) => e.toString().contains('FFmpeg encoding failed'))),
      );
    });

    test('cleans up concat.txt file after execution', () async {
      final image = File('${tempDir.path}/image.jpg')..createSync();
      final mockSession = MockFFmpegSession();
      when(() => mockSession.getReturnCode()).thenAnswer((_) async => ReturnCode(0));
      when(() => mockExecutor.execute(any())).thenAnswer((_) async => mockSession);
      
      final cacheDir = Directory('${Directory.systemTemp.path}/clawfree_video');
      final concatFile = File('${cacheDir.path}/concat.txt');

      await ItineraryVideoGenerator.generate(
        imagePaths: [image.path],
        executor: mockExecutor,
      );

      expect(concatFile.existsSync(), isFalse);
    });
  });
}
