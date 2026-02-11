/// Minimal service locator for decoupling service wiring from widgets.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object> _services = {};

  /// Register a service instance by type.
  void register<T extends Object>(T service) {
    _services[T] = service;
  }

  /// Retrieve a registered service. Throws if not found.
  T get<T extends Object>() {
    final service = _services[T];
    if (service == null) {
      throw StateError('Service $T not registered in ServiceLocator');
    }
    return service as T;
  }

  /// Retrieve a registered service, or null if not found.
  T? tryGet<T extends Object>() => _services[T] as T?;

  /// Remove all registered services.
  void reset() => _services.clear();
}

/// Convenience accessor for the singleton.
final sl = ServiceLocator.instance;
