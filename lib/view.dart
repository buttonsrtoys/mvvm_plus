import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A widget that builds a View and a View Model
///
/// Consumed the same way as StatelessWidget. I.e., override its Widget build() function. The only difference
/// is you also give it a generic and a builder for your ViewModel subclass:
///
///   class MyWidget extends View<MyWidgetViewModel> {
///     MyWidget({super.key}) : super(viewModelBuilder: () => MyWidgetViewModel);
///     @override
///     Widget build() {
///       return Text(viewModel.text);  // <- viewModel is the instance of your ViewModel subclass
///     }
///   }
///
/// [viewModelBuilder] is a builder for a [ViewModel] subclass.
/// [registerViewModel] is whether the built [ViewModel] is "registered", meaning that it can be located with
/// [View.get]. View Models are typically only registered when they need to be located by a descendant of this widget
/// or by a widget on another branch of the widget tree. Note that the [View] has member [viewModel], so doesn't
/// need [View.get].
/// [name] is the optional unique name of the registered View Model. Typically registered View Models are not named.
/// On rare occasions when multiple View Models of the same type are registered, unique names are required to register
/// and retrieve them.
abstract class View<T extends ViewModel> extends StatefulWidget {
  View({
    required this.viewModelBuilder,
    this.registerViewModel = false,
    this.name,
    super.key,
  })  : assert(
            registerViewModel || name == null,
            'Error: View was called with "name" set but not "registerViewModel". You must '
            'also set "registerViewModel" when "name" is set.'),
        assert(T != ViewModel, _missingGenericError('View constructor', 'ViewModel'));
  final T Function() viewModelBuilder;
  final bool registerViewModel;
  final String? name;

  /// Returns the custom [ViewModel] associated with this [View].
  ///
  /// This getter should only be called within the overridden [build] function.
  @protected
  T get viewModel => _viewModelInstance.value!;

  final _viewModelInstance = _ViewModelInstance<T>();

  /// Same functionality as [StatelessWidget.build]. E.g., override this function to define your interface.
  ///
  /// [View] is extended like a [StatefulWidget]. E.g., you override this [build] function. However, [View] as a
  /// [StatefulWidget]. Therefore, [createState] builds this widget and [build] is instead called from
  /// [_ViewState.build].
  Widget build(BuildContext context);

  /// DO NOT OVERRIDE
  ///
  /// [createState] provides the logic for this [View] class so should not be overridden. Instead, override the [build]
  /// function to extend this class.
  @nonVirtual
  @override
  State<View<T>> createState() => _ViewState<T>();

  /// Register a [ChangeNotifier] for retrieving with [View.get]
  ///
  /// [View], [ChangeNotifierRegistrar], and [MultiChangeNotifierRegistrar] automatically call [register] and
  /// [unregister] so this function is not typically used. It is only used to manually register or unregister
  /// a [ChangeNotifier]. E.g., if you could register/unregister a [ValueNotifier].
  static void register<U extends ChangeNotifier>(ChangeNotifier changeNotifier, {String? name}) {
    if (View.isRegistered<U>(name: name)) {
      throw Exception(
        'Error: Tried to register an instance of type $U with name $name but it is already registered.',
      );
    }
    if (!_registeredChangeNotifiers.containsKey(U)) {
      _registeredChangeNotifiers[U] = <String?, ChangeNotifier>{};
    }
    _registeredChangeNotifiers[U]![name] = changeNotifier;
  }

  /// Unregister a [ChangeNotifier] so that it can no longer be retrieved with [View.get]
  ///
  /// Calling this function does not call the [dispose] function of the [ChangeNotifier].
  /// See [register] for more information about when this function is needed.
  ///
  /// Returns the unregistered [ChangeNotifier].
  static ChangeNotifier? unregister<U extends ChangeNotifier>({String? name}) {
    if (!View.isRegistered<U>(name: name)) {
      throw Exception(
        'Error: Tried to unregister an instance of type $U with name $name but it is not registered.',
      );
    }
    final changeNotifier = _registeredChangeNotifiers[U]!.remove(name);
    if (_registeredChangeNotifiers[U]!.isEmpty) {
      _registeredChangeNotifiers.remove(U);
    }
    return changeNotifier;
  }

  /// Determines whether a [ChangeNotifier] is registered and therefore retrievable with [View.get]
  static bool isRegistered<U extends ChangeNotifier>({String? name}) {
    assert(U != ChangeNotifier, _missingGenericError('isRegistered', 'ChangeNotifier'));
    return _registeredChangeNotifiers.containsKey(U) && _registeredChangeNotifiers[U]!.containsKey(name);
  }

  /// Get a registered [ChangeNotifier]
  static U get<U extends ChangeNotifier>({String? name}) {
    if (!View.isRegistered<U>(name: name)) {
      throw Exception(
        'View error. Tried to get an instance of type $U with name $name but it is not registered.',
      );
    }
    return _registeredChangeNotifiers[U]![name] as U;
  }
}

class _ViewState<T extends ViewModel> extends State<View<T>> {
  late T _viewModel;

  @override
  void initState() {
    super.initState();
    _initViewModel();
    _viewModel.initState();
  }

  @override
  void dispose() {
    if (widget.registerViewModel) {
      View.unregister<T>(name: widget.name);
    }
    _viewModel.dispose();
    super.dispose();
  }

  void _initViewModel() {
    _viewModel = widget.viewModelBuilder();
    if (widget.registerViewModel) {
      View.register<T>(_viewModel, name: widget.name);
    }
    _viewModel._buildView = () => setState(() {});
    _viewModel.addListener(_viewModel._buildView);
  }

  @override
  Widget build(BuildContext context) {
    widget._viewModelInstance.value = _viewModel;
    return widget.build(context);
  }
}

/// Wrapper for ViewModel instance that is assigned in [_ViewState] and accessed in [View]
class _ViewModelInstance<T> {
  T? value;
}

/// [ChangeNotifier] subscription
class Subscription {
  Subscription({required this.changeNotifier, required this.listener});
  final void Function() listener;
  final ChangeNotifier changeNotifier;
  void unsubscribe() {
    changeNotifier.removeListener(listener);
  }
}

/// Base class for View Models
abstract class ViewModel extends ChangeNotifier {
  @protected
  late void Function() _buildView;

  final _subscriptions = <Subscription>[];

  /// Called when instance is created.
  @protected
  void initState() {}

  /// Called when instance is disposed.
  @override
  @mustCallSuper
  void dispose() {
    for (Subscription subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    super.dispose();
  }

  /// Listen to [ChangeNotifier]
  ///
  /// If [listener] is null then [View] is queued to build when [T] calls [notifyListeners]. When [listener] is
  /// non-null, the listener is called instead. Note that when [listener] is non-null, [View] is not implicitly queued
  /// to build when [notifyListeners] is called. Rather, if you want to queue a build after [listener] finishes, you
  /// must add a call [notifyListeners] to your [listener].
  void listenTo<T extends ChangeNotifier>({String? name, void Function()? listener}) {
    assert(T != ChangeNotifier, _missingGenericError('listenTo', 'ChangeNotifier'));
    final changeNotifier = View.get<T>(name: name);
    final void Function() listenerToAdd = listener ?? _buildView;
    changeNotifier.addListener(listenerToAdd);
    _subscriptions.add(Subscription(changeNotifier: changeNotifier, listener: listenerToAdd));
  }
}

/// Register a [ChangeNotifier] so it can be retrieved with [View.get]
///
/// [changeNotifierBuilder] builds the [ChangeNotifier].
/// [name] is a unique name key and only needed when more than one [ChangeNotifier] is registered of the same type.
/// [child] is the child widget.
class ChangeNotifierRegistrar<T extends ChangeNotifier> extends StatefulWidget {
  ChangeNotifierRegistrar({
    required this.changeNotifierBuilder,
    this.name,
    required this.child,
    super.key,
  }) : assert(T != ChangeNotifier, _missingGenericError('ChangeNotifierRegistrar constructor', 'ChangeNotifier'));
  final T Function() changeNotifierBuilder;
  final String? name;
  final Widget child;

  @override
  State<ChangeNotifierRegistrar> createState() => _ChangeNotifierRegistrarState<T>();
}

class _ChangeNotifierRegistrarState<T extends ChangeNotifier> extends State<ChangeNotifierRegistrar> {
  @override
  void initState() {
    super.initState();
    View.register<T>(widget.changeNotifierBuilder(), name: widget.name);
  }

  @override
  void dispose() {
    final changeNotifier = View.unregister<T>(name: widget.name);
    changeNotifier!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Register multiple [ChangeNotifier]s so they can be retrieved with [View.get]
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

  final List<ChangeNotifierRegistrarDelegate> registrars;
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
    View.register<T>(changeNotifierBuilder(), name: name);
  }

  void _unregister() {
    View.unregister<T>(name: name);
  }
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';

final _registeredChangeNotifiers = <Type, Map<String?, ChangeNotifier>>{};
