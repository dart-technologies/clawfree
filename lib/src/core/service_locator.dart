/// Minimal service locator for decoupling service wiring from widgets.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object> _services = {};
  final Map<Type, Object Function()> _factories = {};

  /// Register a service instance by type.
  void register<T extends Object>(T service) {
    _services[T] = service;
  }

  /// Register a lazy factory that creates the service on first [get] call.
  void registerLazy<T extends Object>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Retrieve a registered service. Throws if not found.
  T get<T extends Object>() {
    final service = _services[T];
    if (service != null) return service as T;

    final factory = _factories[T];
    if (factory != null) {
      final instance = factory() as T;
      _services[T] = instance;
      _factories.remove(T);
      return instance;
    }

    throw StateError('Service $T not registered in ServiceLocator');
  }

  /// Retrieve a registered service, or null if not found.
  T? tryGet<T extends Object>() {
    if (_services.containsKey(T)) return _services[T] as T;
    if (_factories.containsKey(T)) return get<T>();
    return null;
  }

  /// Remove all registered services and factories.
  void reset() {
    _services.clear();
    _factories.clear();
  }
}

/// Convenience accessor for the singleton.
final sl = ServiceLocator.instance;
