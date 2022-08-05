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
/// As shown, you specify a generic and a builder for your ViewModel subclass.
///
/// [viewModelBuilder] is a builder for a [ViewModel] subclass.
///
/// See the [README](https://github.com/buttonsrtoys/mvvm_plus/blob/main/README.md) for more information.
abstract class View<T extends ViewModel> extends StatefulWidget {
  View({
    required this.viewModelBuilder,
    super.key,
  }) : assert(T != ViewModel, _missingGenericError('View constructor', 'ViewModel'));
  final T Function() viewModelBuilder;
  final _stateInstance = _StateInstance<T>();

  /// Returns the [ViewModel] subclass associated with this [View].
  T get viewModel => _stateInstance.value._viewModel;

  /// See [State.context] for details.
  BuildContext get context => _stateInstance.value.context;

  /// See [State.mounted] for details.
  bool get mounted => _stateInstance.value.mounted;

  /// See [State.didUpdateWidget] for details.
  @protected
  @mustCallSuper
  void didUpdateWidget(covariant View<T> oldWidget) {}

  /// See [State.reassemble] for details.
  @protected
  @mustCallSuper
  void reassemble() {}

  /// See [State.deactivate] for details.
  @protected
  @mustCallSuper
  void deactivate() {}

  /// See [State.activate] for details.
  @protected
  @mustCallSuper
  void activate() {}

  /// See [State.didChangeDependencies] for details.
  @protected
  @mustCallSuper
  void didChangeDependencies() {}

  /// Same functionality as [StatelessWidget.build]. E.g., override this function to define the interface.
  Widget build(BuildContext context);

  /// [createState] provides the logic for this [View] class and typically would not be overridden. To specify the
  /// interface, override [build].
  @override
  @mustCallSuper
  State<View<T>> createState() => _ViewState<T>();
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

/// Wrapper for ViewModel to transfer from [_ViewState] to [View]
class _StateInstance<T extends ViewModel> {
  late _ViewState<T> value;
}

/// [ChangeNotifier] subscription
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
/// [register] is whether the built [ViewModel] is "registered", meaning that it can be located with from other widgets
/// by using [ViewModel.get] (which uses [Registrar.get] under the hood, so you can use [Registrar.get] as well). View
/// Models are typically only registered when they need to be located by a descendant of this
/// widget or by a widget on another branch of the widget tree. Note that the [View] uses member [viewModel] to access
/// its [ViewModel], so doesn't need the registry or to use [get].
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

  /// Gets a registered object.
  ///
  /// This method performs a one-time retrieval and does not listen to future changes. To listen for future changes,
  /// see [listenTo].
  ///
  /// [name] is the optional name assigned to the object when it was registered.
  @protected
  T get<T extends Object>({String? name}) {
    assert(T != Object, _missingGenericError('get', 'Object'));
    return Registrar.get<T>(name: name);
  }

  /// Gets a registered ChangeNotifier and listens to future calls to [T.notifyListeners].
  ///
  /// [name] is the optional name assigned to the object when it was registered.
  /// [listener] is the optional listener that is called every time [T.notifyListeners] is called. If [listener] is
  /// null then [buildView] is added as a listener. Usages like below result in [View] being queued to rebuild every
  /// time [SomeChangeNotifier.notifyListeners] is called:
  ///
  ///     int get someInt => listenTo<SomeChangeNotifier>().someInt;
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
  /// Specifying a [listener] would typically be done in a constructor or initState and the returned ChangeNotifier
  /// would typically be ignored:
  ///
  ///    @override
  ///    void initState() {
  ///      super.initState();
  ///      listenTo<SomeChangeNotifier>(listener: myListener);
  ///    }
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

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
