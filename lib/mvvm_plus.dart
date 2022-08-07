import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:registrar/registrar.dart';

/// A View widget with a builder for a ViewModel
///
/// Consumed like StatelessWidget. I.e., override its Widget build() function
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
  /// On calls to [U.notifyListeners], queues [build]. Note that unlike [ViewModel.listenTo], [View.listenTo] has
  /// no "listener" parameter that receives a custom listener. If you need a custom listener, please define it in your
  /// custom [ViewModel] and use [ViewModel.listenTo] so that your business logic is relegated to your [ViewModel].
  /// (See [ViewModel.listenTo] for more details.)
  ///
  /// [name] is the optional name assigned to the ChangeNotifier when it was registered.
  @protected
  U listenTo<U extends ChangeNotifier>({String? name}) => viewModel.listenTo<U>(name: name);

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

/// mvvm_plus implementation.
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

/// Wrapper for ViewModel so that [View] can access the ViewModel in [_ViewState].
class _StateInstance<T extends ViewModel> {
  late _ViewState<T> value;
}

/// ChangeNotifier subscription.
///
/// A subscription to a ChangeNotifier that is managed.
class _Subscription extends Equatable {
  const _Subscription({required this.changeNotifier, required this.listener});

  final void Function() listener;
  final ChangeNotifier changeNotifier;

  void unsubscribe() {
    changeNotifier.removeListener(listener);
  }

  @override
  List<Object?> get props => [changeNotifier, listener];
}

/// Base class for View Models
///
/// [register] is whether the built [ViewModel] should "register", meaning that it can be located using
/// [ViewModel.get], [View.get], [ViewModel.listenTo], or [View.listenTo], Models are typically only registered when
/// they need to be located by a descendant of this widget or by a widget on another branch of the widget tree. Note
/// that the [View] uses member [viewModel] to access its [ViewModel], so doesn't need the registry or to use [get].
/// [name] is the optional unique name of the registered View Model. Typically registered View Models are not named.
/// On rare occasions when multiple View Models of the same type are registered, unique names uniquely identify them.
abstract class ViewModel extends ChangeNotifier {
  ViewModel({
    this.register = false,
    this.name,
  }) : assert(
            register || name == null,
            'Constructor was called with "name" set but not "registerViewModel". You must '
            'also set "registerViewModel" when "name" is set.');

  final bool register;
  final String? name;
  final _subscriptions = <_Subscription>[];

  /// Queues [View] to rebuild.
  ///
  /// Typically called when data rendered in [View] changed:
  ///
  ///     void incrementCounter() {
  ///       _counter++;
  ///       buildView();
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

  /// Get a registered ChangeNotifier and listens to future calls to [T.notifyListeners].
  ///
  /// [name] is the optional name assigned to the ChangeNotifier when it was registered.
  /// [listener] is the optional listener that is added one time and called every time [T.notifyListeners] is called.
  /// If [listener] is null then [buildView] is added as a listener. Usages like below result in [View] being queued to
  /// rebuild every time [SomeChangeNotifier.notifyListeners] is called:
  ///
  ///     int get someInt => listenTo<SomeChangeNotifier>().someInt;
  ///
  /// or another example:
  ///
  ///     int doubleSomeInt() {
  ///       return 2 * listenTo<SomeChangeNotifier>().someInt;
  ///     }
  ///
  /// To rebuild the view from a custom listener call [buildView]:
  ///
  ///     void myListener() {
  ///       // do something
  ///       buildView();
  ///     }
  ///
  /// Specifying a [listener] would typically be done in a constructor or initState:
  ///
  ///     late final SomeChangeNotifier someChangeNotifier;
  ///
  ///     @override
  ///     void initState() {
  ///       super.initState();
  ///       someChangeNotifier = listenTo<SomeChangeNotifier>(listener: myListener);
  ///     }
  ///
  /// Listeners are only added to [T] once regardless of the number of times [listenTo] is called.
  @protected
  T listenTo<T extends ChangeNotifier>({String? name, void Function()? listener}) {
    assert(T != ChangeNotifier, _missingGenericError('listenTo', 'ChangeNotifier'));
    final notifier = Registrar.get<T>(name: name);
    final listenerToAdd = listener ?? buildView;
    final subscription = _Subscription(changeNotifier: notifier, listener: listenerToAdd);
    if (!_subscriptions.contains(subscription)) {
      notifier.addListener(listenerToAdd);
      _subscriptions.add(subscription);
    }
    return notifier;
  }

  /// Called when instance is created.
  @protected
  @mustCallSuper
  void initState() {
    if (register) {
      Registrar.registerByRuntimeType(instance: this, name: name);
    }
  }

  /// Called when instance is disposed.
  @override
  @mustCallSuper
  void dispose() {
    for (_Subscription subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    if (register) {
      Registrar.unregisterByRuntimeType(runtimeType: runtimeType, name: name, dispose: false);
    }
    super.dispose();
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
///       @override
///       Widget build(BuildContext context) {
///         return Text(get<SomeNotifier>().text);
///       }
///     }
///
/// you can instead write
///
///     class MyView extends ViewWithStatelessViewModel {
///       MyView({super.key});
///       @override
///       Widget build(BuildContext context) {
///         return Text(get<SomeNotifier>().text);
///       }
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
