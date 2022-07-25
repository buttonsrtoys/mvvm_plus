import 'package:flutter/widgets.dart';

/// A widget that registers singletons lazily
///
/// The lifecycle of the [Object] is bound to this widget.
///
/// [builder] builds the [Object].
/// [name] is a unique name key and only needed when more than one [Object] is registered of the same type.
/// [child] is the child widget.
class Registrar <T extends Object> extends StatefulWidget {
  Registrar({
    required this.builder,
    this.name,
    required this.child,
    super.key,
  }) : assert(T != Object, _missingGenericError('Registrar constructor', 'Object'));
  final T Function() builder;
  final String? name;
  final Widget child;

  @override
  State<Registrar> createState() => _RegistrarState<T>();

  /// Register an [Object] for retrieving with [Registrar.get]
  ///
  /// [Registrar] and [MultiRegistrar] automatically call [register] and [unregister] so this function
  /// is not typically used. It is only used to manually register or unregister an [Object]. E.g., if
  /// you could register/unregister a [ValueNotifier].
  static void register<T extends Object>(Object object, {String? name}) {
    if (Registrar.isRegistered<T>(name: name)) {
      throw Exception(
        'Error: Tried to register an instance of type $T with name $name but it is already registered.',
      );
    }
    if (!_registry.containsKey(T)) {
      _registry[T] = <String?, Object>{};
    }
    _registry[T]![name] = object;
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
    final object = _registry[T]!.remove(name);
    if (_registry[T]!.isEmpty) {
      _registry.remove(T);
    }
    if (object is ChangeNotifier) {
      object.dispose();
    }
  }

  /// Determines whether an [Object] is registered and therefore retrievable with [Registrar.get]
  static bool isRegistered<T extends Object>({String? name}) {
    assert(T != Object, _missingGenericError('isRegistered', 'Object'));
    return _registry.containsKey(T) && _registry[T]!.containsKey(name);
  }

  /// Get a registered [Object]
  static T get<T extends Object>({String? name}) {
    // Rich, this is where we need the lazy logic re: Registry
    if (!Registrar.isRegistered<T>(name: name)) {
      throw Exception(
        'Registrar error. Tried to get an instance of type $T with name $name but it is not registered.',
      );
    }
    return _registry[T]![name] as T;
  }
}

class _RegistrarState<T extends Object> extends State<Registrar> {
  @override
  void initState() {
    super.initState();
    Registrar.register<T>(widget.builder(), name: widget.name);
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
/// The lifecycles of the [Object]s are bound to this widget.
///
/// usage:
///   MultiRegistrar(
///     delegates: [
///       RegistrarDelegate<MyService>(builder: () => MyService()),
///       RegistrarDelegate<MyOtherService>(builder: () => MyOtherService()),
///     ],
///     child: MyWidget(),
///   );
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
/// [name] is a unique name key and only needed when more than one [Object] is registered of the same type.
class RegistrarDelegate<T extends Object> {
  RegistrarDelegate({
    required this.builder,
    this.name,
  }) : assert(
  T != Object, _missingGenericError('RegistrarDelegate constructor', 'Object'));

  final Object Function() builder;
  final String? name;

  void _register() {
    Registrar.register<T>(builder(), name: name);
  }

  void _unregister() {
    Registrar.unregister<T>(name: name);
  }
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';

// Rich, need something like
// class RegistryEntry {
//   RegistryEntry(this.builder, this.instance) : assert(builder != instance && builder == null || instance == null);
//   T Function() builder?;
//   T instance?;
// }
// final _registry = <Type, Map<String?, RegistryEntry>>{};
final _registry = <Type, Map<String?, Object>>{};