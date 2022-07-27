import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:registrar/registrar.dart';

/// A widget that builds a View and has a View Model
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
/// See the [README](https://github.com/buttonsrtoys/get_mvvm/blob/main/README.md) for more information.
abstract class View<T extends ViewModel> extends StatefulWidget {
  View({
    required this.viewModelBuilder,
    super.key,
  }) : assert(T != ViewModel, _missingGenericError('View constructor', 'ViewModel'));
  final T Function() viewModelBuilder;
  final _viewModelInstance = _ViewModelInstance<T>();

  /// Returns the [ViewModel] subclass associated with this [View].
  T get viewModel {
    assert(
        _viewModelInstance.value != null,
        'It appears that "createState" was overridden, which which is forbidden. '
        'See the comments in "createState" for more detail.');
    return _viewModelInstance.value!;
  }

  /// Same functionality as [StatelessWidget.build]. E.g., override this function to define the interface.
  Widget build(BuildContext context);

  /// [createState] provides the logic for this [View] class so should not be overridden. To specify the interface, o
  /// override [build] instead.
  @nonVirtual
  @override
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
  Widget build(BuildContext context) {
    widget._viewModelInstance.value = _viewModel;
    return widget.build(context);
  }
}

/// Wrapper for ViewModel to transfer from [_ViewState] to [View]
class _ViewModelInstance<T> {
  T? value;
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
/// by using [ViewModel.get] (which uses [Registrar.get] under the hood, so you can use [Registrar.get] as well. View
/// Models are typically only registered when they need to be located by a descendant of this
/// widget or by a widget on another branch of the widget tree. Note that the [View] uses member [viewModel] to access
/// its [ViewModel], so doesn't need the registry or to use [get].
/// [name] is the optional unique name of the registered View Model. Typically registered View Models are not named.
/// On rare occasions when multiple View Models of the same type are registered, unique names are uniquely identify
/// them.
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
  /// Typically called when data shown in [View] changed:
  ///
  ///     void incrementCounter() {
  ///       _counter++;
  ///       buildView();
  ///     }
  ///
  /// Note that [buildView] is automatically added as a listener to [ViewModel], so [buildView] is called every time
  /// [notifyListeners] is called. However, there is an important distinction between calling [notifyListeners] and
  /// [buildView]. When this [ViewModel] is registered, calling [notifyListeners] will queue [View] to build AND
  /// will also notify the other listeners of a change. [buildView] will not notify other listeners of a change.
  /// Therefore, to avoid accidentally notifying listeners, defer to [buildView] unless listeners need to be notified.
  ///
  /// Typically this method is not overriden.
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
  ChangeNotifier listenTo<T extends ChangeNotifier>({String? name, void Function()? listener}) {
    assert(T != ChangeNotifier, _missingGenericError('listenTo', 'ChangeNotifier'));
    final changeNotifier = Registrar.get<T>(name: name);
    final listenerToAdd = listener ?? buildView;
    final subscription = _Subscription(changeNotifier: changeNotifier, listener: listenerToAdd);
    if (!_subscriptions.contains(subscription)) {
      changeNotifier.addListener(listenerToAdd);
      _subscriptions.add(subscription);
    }
    return changeNotifier;
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
      Registrar.unregisterByRuntimeType(runtimeType: runtimeType, name: name);
    }
    super.dispose();
  }

// Rich, need to add other stateless functions here

}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
