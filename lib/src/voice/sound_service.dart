import 'earcon_service.dart';

/// Thin facade over [EarconService] for convenient integration.
class SoundService {
  SoundService({required EarconService earcon}) : _earcon = earcon;
  final EarconService _earcon;

  Future<void> init() => _earcon.init();
  Future<void> success() => _earcon.playSuccess();
  Future<void> error() => _earcon.playError();
  Future<void> notification() => _earcon.playNotification();
  Future<void> micOpen() => _earcon.playMicOpen();
  Future<void> micClose() => _earcon.playMicClose();
  void dispose() => _earcon.dispose();
}
