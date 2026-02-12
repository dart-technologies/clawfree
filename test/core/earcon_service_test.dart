import 'package:clawfree/src/voice/earcon_service.dart';
import 'package:clawfree/src/voice/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EarconService', () {
    late EarconService earcon;

    setUp(() {
      earcon = EarconService();
    });

    tearDown(() {
      earcon.dispose();
    });

    // Note: init() requires native AudioPlayer plugin, so we test it via
    // the _RecordingEarconService mock below. Here we verify that the
    // play methods are safe to call without init (no crash).

    test('playSuccess does not throw before init', () async {
      await expectLater(earcon.playSuccess(), completes);
    });

    test('playError does not throw before init', () async {
      await expectLater(earcon.playError(), completes);
    });

    test('playNotification does not throw before init', () async {
      await expectLater(earcon.playNotification(), completes);
    });

    test('playMicOpen does not throw before init', () async {
      await expectLater(earcon.playMicOpen(), completes);
    });

    test('playMicClose does not throw before init', () async {
      await expectLater(earcon.playMicClose(), completes);
    });

    test('dispose does not throw', () {
      expect(() => earcon.dispose(), returnsNormally);
    });

    test('double dispose does not throw', () {
      earcon.dispose();
      expect(() => earcon.dispose(), returnsNormally);
    });
  });

  group('SoundService', () {
    test('delegates to EarconService', () async {
      final recorder = _RecordingEarconService();
      final sound = SoundService(earcon: recorder);

      await sound.init();
      await sound.success();
      await sound.error();
      await sound.notification();
      await sound.micOpen();
      await sound.micClose();
      sound.dispose();

      expect(recorder.calls, [
        'init',
        'playSuccess',
        'playError',
        'playNotification',
        'playMicOpen',
        'playMicClose',
        'dispose',
      ]);
    });
  });
}

/// Records method calls for verifying delegation.
class _RecordingEarconService extends EarconService {
  final List<String> calls = [];

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<void> playMicOpen() async => calls.add('playMicOpen');

  @override
  Future<void> playMicClose() async => calls.add('playMicClose');

  @override
  Future<void> playSuccess() async => calls.add('playSuccess');

  @override
  Future<void> playError() async => calls.add('playError');

  @override
  Future<void> playNotification() async => calls.add('playNotification');

  @override
  void dispose() => calls.add('dispose');
}
