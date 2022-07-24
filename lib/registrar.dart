import 'package:flutter/widgets.dart';

/// A widget that registers a registers singletons lazily
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

  /// Register a [Object] for retrieving with [Registrar.get]
  ///
  /// [Registrar], [ChangeNotifierRegistrar], and [MultiObjectRegistrar] automatically call [register] and
  /// [unregister] so this function is not typically used. It is only used to manually registor or unregister
  /// a [Object]. E.g., if you could register/unregister a [ValueNotifier].
  static void register<U extends Object>(Object object, {String? name}) {
    if (Registrar.isRegistered<U>(name: name)) {
      throw Exception(
        'Error: Tried to register an instance of type $U with name $name but it is already registered.',
      );
    }
    if (!_registeredObjects.containsKey(U)) {
      _registeredObjects[U] = <String?, Object>{};
    }
    _registeredObjects[U]![name] = object;
  }

  /// Unregister a [Object] so that it can no longer be retrieved with [Registrar.get]
  ///
  /// Returns the unregistered [Object].
  static Object? unregister<U extends Object>({String? name}) {
    if (!Registrar.isRegistered<U>(name: name)) {
      throw Exception(
        'Error: Tried to unregister an instance of type $U with name $name but it is not registered.',
      );
    }
    final object = _registeredObjects[U]!.remove(name);
    if (_registeredObjects[U]!.isEmpty) {
      _registeredObjects.remove(U);
    }
    return object;
  }

  /// Determines whether a [Object] is registered and therefore retrievable with [Registrar.get]
  static bool isRegistered<U extends Object>({String? name}) {
    assert(U != Object, _missingGenericError('isRegistered', 'Object'));
    return _registeredObjects.containsKey(U) && _registeredObjects[U]!.containsKey(name);
  }

  /// Get a registered [Object]
  static U get<U extends Object>({String? name}) {
    if (!Registrar.isRegistered<U>(name: name)) {
      throw Exception(
        'Registrar error. Tried to get an instance of type $U with name $name but it is not registered.',
      );
    }
    return _registeredObjects[U]![name] as U;
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
///       RegistrarDelegate<MyService>(changeNotifierBuilder: () => MyService()),
///       RegistrarDelegate<MyOtherService>(changeNotifierBuilder: () => MyOtherService()),
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
    for (final changeNotifierRegistrar in widget.delegates) {
      changeNotifierRegistrar._register();
    }
  }

  @override
  void dispose() {
    for (final changeNotifierRegistrar in widget.delegates) {
      changeNotifierRegistrar._unregister();
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
/// [changeNotifierBuilder] builds the [ChangeNotifier].
/// [name] is a unique name key and only needed when more than one [ChangeNotifier] is registered of the same type.
/// [child] is the child widget.
class RegistrarDelegate<T extends ChangeNotifier> {
  RegistrarDelegate({
    required this.changeNotifierBuilder,
    this.name,
  }) : assert(
  T != ChangeNotifier, _missingGenericError('RegistrarDelegate constructor', 'ChangeNotifier'));

  final ChangeNotifier Function() changeNotifierBuilder;
  final String? name;

  void _register() {
    Registrar.register<T>(changeNotifierBuilder(), name: name);
  }

  void _unregister() {
    Registrar.unregister<T>(name: name);
  }
}

/// Register a [ChangeNotifier] so it can be retrieved with [Registrar.get]
///
/// [changeNotifierBuilder] builds the [ChangeNotifier].
/// [name] is a unique name key and only needed when more than one [ChangeNotifier] is registered of the same type.
/// [child] is the child widget.
class ChangeNotifierRegistrar<T extends ChangeNotifier> extends Registrar<T> {
  ChangeNotifierRegistrar({
    required super.builder,
    super.name,
    required super.child,
    super.key,
  }) : assert(T != ChangeNotifier, _missingGenericError('ChangeNotifierRegistrar constructor', 'ChangeNotifier'));

  @override
  State<ChangeNotifierRegistrar> createState() => _ChangeNotifierRegistrarState<T>();
}

class _ChangeNotifierRegistrarState<T extends ChangeNotifier> extends State<ChangeNotifierRegistrar> {
  @override
  void initState() {
    super.initState();
    Registrar.register<T>(widget.builder(), name: widget.name);
  }

  @override
  void dispose() {
    final changeNotifier = Registrar.unregister<T>(name: widget.name) as ChangeNotifier;
    changeNotifier!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Register multiple [ChangeNotifier]s so they can be retrieved with [Registrar.get]
///
/// The lifecycles of the [ChangeNotifier]s are bound to this widget.
///
/// usage:
///   ChangeNotifierRegistrarWidget(
///     registrars: [
///       ChangeNotifierRegistrar<MyService>(changeNotifierBuilder: () => MyService()),
///       ChangeNotifierRegistrar<MyOtherService>(changeNotifierBuilder: () => MyOtherService()),
///     ],
///     child: MyWidget(),
///   );
class MultiChangeNotifierRegistrar extends StatefulWidget {
  const MultiChangeNotifierRegistrar({
    required this.registrars,
    required this.child,
    super.key,
  });

  final List<RegistrarDelegate> registrars;
  final Widget child;

  @override
  State<MultiChangeNotifierRegistrar> createState() => _MultiChangeNotifierRegistrarState();
}

class _MultiChangeNotifierRegistrarState extends State<MultiChangeNotifierRegistrar> {
  @override
  void initState() {
    super.initState();
    for (final changeNotifierRegistrar in widget.registrars) {
      changeNotifierRegistrar._register();
    }
  }

  @override
  void dispose() {
    for (final changeNotifierRegistrar in widget.registrars) {
      changeNotifierRegistrar._unregister();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Delegate for [ChangeNotifierRegistrar]. See [MultiChangeNotifierRegistrar] for more information.
///
/// [changeNotifierBuilder] builds the [ChangeNotifier].
/// [name] is a unique name key and only needed when more than one [ChangeNotifier] is registered of the same type.
/// [child] is the child widget.
class ChangeNotifierRegistrarDelegate<T extends ChangeNotifier> {
  ChangeNotifierRegistrarDelegate({
    required this.changeNotifierBuilder,
    this.name,
  }) : assert(
            T != ChangeNotifier, _missingGenericError('ChangeNotifierRegistrarDelegate constructor', 'ChangeNotifier'));

  final ChangeNotifier Function() changeNotifierBuilder;
  final String? name;

  void _register() {
    Registrar.register<T>(changeNotifierBuilder(), name: name);
  }

  void _unregister() {
    Registrar.unregister<T>(name: name);
  }
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';

final _registeredObjects = <Type, Map<String?, Object>>{};

/// [ChangeNotifier] subscription
class Subscription {
  Subscription({required this.changeNotifier, required this.listener});
  final void Function() listener;
  final ChangeNotifier changeNotifier;
  void unsubscribe() {
    changeNotifier.removeListener(listener);
  }
}





