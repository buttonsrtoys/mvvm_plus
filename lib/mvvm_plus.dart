import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:registrar/registrar.dart';

typedef Property<T> = ValueNotifier<T>;

/// A View widget with a builder for a ViewModel
///
/// Consumed like StatelessWidget. I.e., override its Widget build() function
///
///   class MyWidget extends View<MyWidgetViewModel> {
///     MyWidget({super.key}) : super(viewModelBuilder: () => MyWidgetViewModel);
///     @override
///     Widget build() {
///       return Text(viewModel.text);  // <- "viewModel" getter
///     }
///   }
///
/// [viewModelBuilder] is a builder for a [ViewModel] subclass.
abstract class View<T extends ViewModel> extends StatefulWidget {
  View({
    required this.viewModelBuilder,
    super.key,
  }) : assert(T != ViewModel, _missingGenericError('View constructor', 'ViewModel'));
  final T Function() viewModelBuilder;
  final _stateInstance = _StateInstance<T>();

  /// Returns the [ViewModel] subclass bound to this [View].
  T get viewModel => _stateInstance.value._viewModel;

  /// Get a registered object.
  ///
  /// Uses [ViewModel.get] to get a registered object. (See [ViewModel.get] for more details.)
  @protected
  U get<U extends Object>({String? name}) => viewModel.get<U>(name: name);

  /// Get a registered ChangeNotifier and adds a [ViewModel.buildView] listener to [U].
  ///
  /// See [Model.listenTo] for more details.
  @protected
  U listenTo<U extends ChangeNotifier>({U? notifier, String? name}) =>
      viewModel.listenTo<U>(notifier: notifier, name: name);

  /// Same functionality as [State.context].
  BuildContext get context => _stateInstance.value.context;

  /// Same functionality as [State.mounted].
  bool get mounted => _stateInstance.value.mounted;

  /// Same functionality as [State.didUpdateWidget].
  @protected
  @mustCallSuper
  void didUpdateWidget(covariant View<T> oldWidget) {}

  /// Same functionality as [State.reassemble].
  @protected
  @mustCallSuper
  void reassemble() {}

  /// Same functionality as [State.deactivate].
  @protected
  @mustCallSuper
  void deactivate() {}

  /// Same functionality as [State.activate].
  @protected
  @mustCallSuper
  void activate() {}

  /// Same functionality as [State.didChangeDependencies].
  @protected
  @mustCallSuper
  void didChangeDependencies() {}

  /// Same functionality as [StatelessWidget.build]. E.g., override this function to define the interface.
  @protected
  Widget build(BuildContext context);

  /// [createState] provides the logic for this [View] class and typically would not be overridden. To specify the
  /// interface, override [build].
  @override
  @mustCallSuper
  State<View<T>> createState() => _ViewState<T>();
}

/// [_ViewState] does the heavy lifting of extending StatefulWidget into MVVM
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
    _viewModel.dispose();
    super.dispose();
  }

  void _initViewModel() {
    _viewModel = widget.viewModelBuilder();
    _viewModel.buildView = () => setState(() {});
    _viewModel.addListener(_viewModel.buildView);
  }

  @override
  void didUpdateWidget(covariant View<T> oldWidget) {
    widget.didUpdateWidget(oldWidget);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void reassemble() {
    widget.reassemble();
    super.reassemble();
  }

  @override
  void deactivate() {
    widget.deactivate();
    super.deactivate();
  }

  @override
  void activate() {
    widget.activate();
    super.activate();
  }

  @override
  void didChangeDependencies() {
    widget.didChangeDependencies();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    widget._stateInstance.value = this;
    return widget.build(context);
  }
}

/// Wrapper for [_ViewState] to facilitate access by [View]
class _StateInstance<T extends ViewModel> {
  late _ViewState<T> value;
}

/// Manages a listener that subscribes to a ChangeNotifier
class _Subscription extends Equatable {
  const _Subscription({required this.changeNotifier, required this.listener});

  final void Function() listener;
  final ChangeNotifier changeNotifier;

  void subscribe() => changeNotifier.addListener(listener);
  void unsubscribe() => changeNotifier.removeListener(listener);

  @override
  List<Object?> get props => [changeNotifier, listener];
}

/// Base class for a [Model]
///
/// This class manages listeners that are added with its [listenTo] member function. E.g., added listeners
/// are removed when this class is disposed.
abstract class Model extends ChangeNotifier {
  final _subscriptions = <_Subscription>[];

  /// Get a registered object.
  ///
  /// This method gets a registered object and does not listen to future changes. To listen for future changes,
  /// see [listenTo].
  ///
  /// [name] is the optional name assigned to the object when it was registered.
  @protected
  T get<T extends Object>({String? name}) {
    assert(T != Object, _missingGenericError('get', 'Object'));
    return Registrar.get<T>(name: name);
  }

  /// Adds a listener to a ChangeNotifier.
  ///
  /// [notifier] is an optional instance to listen to. A common use case for passing an instance is using [get] to
  /// retrieve a registered [Model] and [notifier] to listen to one of its ValueNotifiers:
  ///
  ///     final user = listenTo<ValueNotifier<User>>(notifier: get<CloudService>().currentUser, listener: buildView);
  ///
  /// If [notifier] is non-null, a registered ChangeNotifier is retrieved with type [T] and [name].
  /// [name] is the optional name assigned to the ChangeNotifier when it was registered (i.e., [notifier] is null).
  /// [listener] is the listener that is added. A one-time check is made sa that the same [listener] cannot be added
  /// to the same [notifier].
  ///
  ///     int doubleCounter() {
  ///       return 2 * listenTo<MyModel>(listener: buildView).counter;
  ///     }
  ///
  @protected
  T listenTo<T extends ChangeNotifier>({T? notifier, String? name, required void Function() listener}) {
    assert(notifier == null || name == null, 'listenTo can only receive parameters "instance" or "name" but not both.');
    final notifierToAdd = notifier ?? Registrar.get<T>(name: name);
    final subscription = _Subscription(changeNotifier: notifierToAdd, listener: listener);
    if (!_subscriptions.contains(subscription)) {
      subscription.subscribe();
      _subscriptions.add(subscription);
    }
    return notifierToAdd;
  }

  @override
  @mustCallSuper
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    _subscriptions.clear();
    super.dispose();
  }
}

/// Base class for View Models
///
/// See [_Registerable] for descriptions of [register] and [name].
abstract class ViewModel extends Model with _Registerable {
  ViewModel({
    bool register = false,
    String? name,
  }) {
    this.register = register || name != null;
    this.name = name;
  }

  /// Queues [View] to rebuild.
  ///
  /// Typically called when data rendered in [View] changed:
  ///
  ///     int _counter = 0;
  ///     void incrementCounter() {
  ///       _counter++;
  ///       buildView();
  ///     }
  ///
  /// or used to bind a [ViewModel] to a [View]:
  ///
  ///     final counter = ValueNotifier<int>(0);
  ///     @override
  ///     void initState() {
  ///       super.initState();
  ///       counter.addListener(buildView);
  ///     }
  ///
  /// Note that [buildView] is automatically added as a listener to [ViewModel], so [buildView] is called every time
  /// [notifyListeners] is called. However, there is an important distinction between calling [notifyListeners] and
  /// [buildView]. When this [ViewModel] is registered, calling [notifyListeners] will queue [View] to build AND
  /// will also notify the listeners of [ViewModel] of a change, while [buildView] will not notify other listeners.
  /// Therefore, to avoid accidentally notifying listeners, defer to [buildView] unless listeners need to be notified.
  ///
  /// Typically this method is not overridden.
  @protected
  late void Function() buildView;

  /// Adds a listener to a ChangeNotifier.
  ///
  /// If [listener] is null then [buildView] is used as the listener. See [Model.listenTo] for more details.
  @protected
  @override
  T listenTo<T extends ChangeNotifier>({T? notifier, String? name, void Function()? listener}) {
    final listenerToAdd = listener ?? buildView;
    return super.listenTo(notifier: notifier, listener: listenerToAdd);
  }

  @protected
  @mustCallSuper
  void initState() {
    registerIfNecessary();
  }

  @override
  @mustCallSuper
  void dispose() {
    unregisterIfNecessary();
    super.dispose();
  }
}

/// Mixed in with [ViewModel] to make it registerable
///
/// [register] is whether the subclass ([ViewModel], [ValueNotifier]) should "register", meaning that it can be located
/// using [ViewModel.get], [View.get], [ViewModel.listenTo], or [View.listenTo], Subclasses are typically only
/// registered when they need to be located by widgets "far away" (e.g., descendants or on another branch.)
/// [name] is the optional unique name of the registered View Model. Typically registered View Models are not named.
/// On rare occasions when multiple View Models of the same type are registered, unique names uniquely identify them.
mixin _Registerable {
  bool register = false;
  String? name;

  void registerIfNecessary() {
    if (register) {
      Registrar.registerByRuntimeType(instance: this, name: name);
    }
  }

  void unregisterIfNecessary() {
    if (register) {
      Registrar.unregisterByRuntimeType(runtimeType: runtimeType, name: name, dispose: false);
    }
  }
}

/// Empty ViewModel used by [ViewWithStatelessViewModel]
class _StatelessViewModel extends ViewModel {}

/// A [View] with a predefined [ViewModel] that has no states.
///
/// This is a convenience class for creating Views that don't have any states but update on changes to registered
/// ChangeNotifiers. E.g., a widget that listens to a service but doesn't have its own states.
///
/// So, if a View has no states but you want to listen to a registered ChangeNotifier, instead of creating an empty
/// ViewModel and a View that consumes it:
///
///     class MyStatelessViewModel extends ViewModel {}
///
///     class MyView extends View<MyStatelessViewModel> {
///       MyView({super.key}) : super(viewModelBuilder: () => MyStatelessViewModel());
///       Widget build(BuildContext context) => Container();
///     }
///
/// you can skip MyStatelessViewModel and its builder and instead write
///
///     class MyView extends ViewWithStatelessViewModel {
///       MyView({super.key});
///       @override
///       Widget build(BuildContext context) => Container();
///     }
///
/// Under the hood, an empty ViewModel is created for [ViewWithStatelessViewModel]
abstract class ViewWithStatelessViewModel extends View<_StatelessViewModel> {
  ViewWithStatelessViewModel({super.key}) : super(viewModelBuilder: () => _StatelessViewModel());

  @override
  @protected
  Widget build(BuildContext context);
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
