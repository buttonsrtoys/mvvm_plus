import 'package:flutter/widgets.dart';

/// A widget that registers singletons lazily
///
/// The lifecycle of the [T] object is bound to this widget. The object is registered when this widget is added to the
/// widget tree and unregistered when removed. If [T] is of type [ChangeNotifier] then its [ChangeNotifier.dispose]
/// is called when it is unregistered.
///
/// [builder] builds the [T].
/// [instance] is an instance of [T]
/// [name] is a unique name key and only needed when more than one [Object] is registered of the same type.
/// [child] is the child widget.
///
/// You can pass [builder] or [instance] but not both. Passing [builder] is recommended, as it makes the implementation
/// lazy. I.e., the instance will only be created the first time it is used. If you already have an instance, then
/// use [instance].
class Registrar<T extends Object> extends StatefulWidget {
  Registrar({
    this.builder,
    this.instance,
    this.name,
    required this.child,
    super.key,
  })  : assert(T != Object, _missingGenericError('Registrar constructor', 'Object')),
        assert(builder == null ? instance != null : instance == null);
  final T Function()? builder;
  final T? instance;
  final String? name;
  final Widget child;

  @override
  State<Registrar<T>> createState() => _RegistrarState<T>();

  /// Register an [Object] for retrieving with [Registrar.get]
  ///
  /// [Registrar] and [MultiRegistrar] automatically call [register] and [unregister] so this function
  /// is not typically used. It is only used to manually register or unregister an [Object]. E.g., if
  /// you could register/unregister a [ValueNotifier].
  static void register<T extends Object>({T? instance, T Function()? builder, String? name}) {
    if (Registrar.isRegistered<T>(name: name)) {
      throw Exception(
        'Error: Tried to register an instance of type $T with name $name but it is already registered.',
      );
    }
    if (!_registry.containsKey(T)) {
      _registry[T] = <String?, _RegistryEntry<T>>{};
    }
    _registry[T]![name] = _RegistryEntry<T>(instance: instance, builder: builder);
  }

  /// Unregister an [Object] so that it can no longer be retrieved with [Registrar.get]
  ///
  /// If [T] is a ChangeNotifier then its `dispose()` method is called.
  static void unregister<T extends Object>({String? name}) {
    if (!Registrar.isRegistered<T>(name: name)) {
      throw Exception(
        'Error: Tried to unregister an instance of type $T with name $name but it is not registered.',
      );
    }
    final registryEntry = _registry[T]!.remove(name);
    if (_registry[T]!.isEmpty) {
      _registry.remove(T);
    }
    if (registryEntry!.instance is ChangeNotifier) {
      registryEntry.instance.dispose();
    }
  }

  /// Determines whether an [Object] is registered and therefore retrievable with [Registrar.get]
  static bool isRegistered<T extends Object>({String? name}) {
    assert(T != Object, _missingGenericError('isRegistered', 'Object'));
    return _registry.containsKey(T) && _registry[T]!.containsKey(name);
  }

  /// Get a registered [Object]
  static T get<T extends Object>({String? name}) {
    if (!Registrar.isRegistered<T>(name: name)) {
      throw Exception(
        'Registrar error. Tried to get an instance of type $T with name $name but it is not registered.',
      );
    }
    return _registry[T]![name]!.instance as T;
  }
}

class _RegistrarState<T extends Object> extends State<Registrar<T>> {
  @override
  void initState() {
    super.initState();
    Registrar.register<T>(instance: widget.instance, builder: widget.builder, name: widget.name);
  }

  @override
  void dispose() {
    Registrar.unregister<T>(name: widget.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Register multiple [Object]s so they can be retrieved with [Registrar.get]
///
/// The lifecycle of each [Object] is bound to this widget. Each object is registered when this widget is added to the
/// widget tree and unregistered when removed. If an [Object] is of type [ChangeNotifier] then its
/// [ChangeNotifier.dispose] when it is unregistered.
///
/// usage:
///   MultiRegistrar(
///     delegates: [
///       RegistrarDelegate<MyService>(builder: () => MyService()),
///       RegistrarDelegate<MyOtherService>(builder: () => MyOtherService()),
///     ],
///     child: MyWidget(),
///   );
///
class MultiRegistrar extends StatefulWidget {
  const MultiRegistrar({
    required this.delegates,
    required this.child,
    super.key,
  });

  final List<RegistrarDelegate> delegates;
  final Widget child;

  @override
  State<MultiRegistrar> createState() => _MultiRegistrarState();
}

class _MultiRegistrarState extends State<MultiRegistrar> {
  @override
  void initState() {
    super.initState();
    for (final delegate in widget.delegates) {
      delegate._register();
    }
  }

  @override
  void dispose() {
    for (final delegate in widget.delegates) {
      delegate._unregister();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Delegate for [Registrar]. See [MultiRegistrar] for more information.
///
/// [builder] builds the [Object].
/// [instance] is an instance of [T]
/// [name] is a unique name key and only needed when more than one [Object] is registered of the same type.
///
/// See [Registrar] for the difference between using [builder] and [instance]
class RegistrarDelegate<T extends Object> {
  RegistrarDelegate({
    this.builder,
    this.instance,
    this.name,
  }) : assert(T != Object, _missingGenericError('RegistrarDelegate constructor', 'Object'));

  final T Function()? builder;
  final String? name;
  final T? instance;

  void _register() {
    Registrar.register<T>(instance: instance, builder: builder, name: name);
  }

  void _unregister() {
    Registrar.unregister<T>(name: name);
  }
}

/// A lazy registry entry
///
/// [instance] is a value of type [T]
/// [builder] is a function that builds [instance]
///
/// The constructor can receive either [instance] or [builder] but not both. Passing [builder] is recommended as it
/// makes the implementation lazy. I.e., [builder] is executed on the first get.
class _RegistryEntry<T> {
  _RegistryEntry({
    this.builder,
    T? instance,
  })  : _instance = instance,
        assert(T != Object, _missingGenericError('Registrar constructor', 'Object')),
        assert(builder == null ? instance != null : instance == null);
  final T Function()? builder;
  T? _instance;
  T get instance => _instance == null ? _instance = builder!() : _instance!;
}

final _registry = <Type, Map<String?, _RegistryEntry>>{};

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
