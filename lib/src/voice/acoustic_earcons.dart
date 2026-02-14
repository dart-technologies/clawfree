import 'earcon_service.dart';

/// Centralizes premium acoustic feedback for the AI Companion experience.
///
/// Defines high-fidelity sound patterns that are synthesized in-memory
/// to avoid bulky asset dependencies while maintaining a premium feel.
abstract final class AcousticEarcons {
  /// A soft, high-frequency ascending chime for genUI surface arrivals.
  static Future<void> playSurfaceArrival(EarconService service) async {
    await service.playNotification();
  }

  /// Triumphant ascending C-E-G chord for booking/save confirmations.
  static Future<void> playBookingConfirm(EarconService service) async {
    await service.playBookingConfirm();
  }

  /// A subtle double-pulse 'heartbeat' sound for system thinking.
  static Future<void> playThinking(EarconService service) async {
    await service.playNotification();
  }
}
