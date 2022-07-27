import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:registrar/registrar.dart';

/// A widget that builds a View and a View Model
///
/// Consumed the same way as StatelessWidget. I.e., override its Widget build() function
///
///   class MyWidget extends View<MyWidgetViewModel> {
///     MyWidget({super.key}) : super(viewModelBuilder: () => MyWidgetViewModel);
///     @override
///     Widget build() {
///       return Text(viewModel.text);  // <- viewModel is the instance of your ViewModel subclass
///     }
///   }
///
/// As shown, you must also specify a generic and a builder for your ViewModel subclass.
///
/// [viewModelBuilder] is a builder for a [ViewModel] subclass.
abstract class View<T extends ViewModel> extends StatefulWidget {
  View({
    required this.viewModelBuilder,
    super.key,
  }) : assert(T != ViewModel, _missingGenericError('View constructor', 'ViewModel'));
  final T Function() viewModelBuilder;
  final _viewModelInstance = _ViewModelInstance<T>();

  /// Returns the custom [ViewModel] associated with this [View].
  T get viewModel {
    assert(
        _viewModelInstance.value != null,
        'It appears that "createState" was overridden, which which is forbidden. '
        'See the comments in "createState" for more detail.');
    return _viewModelInstance.value!;
  }

  // Rich, need to add other stateless functions here

  /// Same functionality as [StatelessWidget.build]. E.g., override this function to define the interface.
  ///
  /// [View] is extended like a [StatefulWidget]. E.g., override this [build] function. However, [View] as a
  /// [StatefulWidget]. Therefore, [createState] builds this widget and [build] is instead called from
  /// [_ViewState.build].
  Widget build(BuildContext context);

  /// [createState] provides the logic for this [View] class so should not be overridden. Instead, override the [build]
  /// function to extend this class.
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
    _viewModel._buildView = () => setState(() {});
    _viewModel.addListener(_viewModel._buildView);
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
/// [register] is whether the built [ViewModel] is "registered", meaning that it can be located with
/// [Registrar.get]. View Models are typically only registered when they need to be located by a descendant of this
/// widget or by a widget on another branch of the widget tree. Note that the [View] has member [viewModel], so doesn't
/// need [Registrar.get].
/// [name] is the optional unique name of the registered View Model. Typically registered View Models are not named.
/// On rare occasions when multiple View Models of the same type are registered, unique names are required to register
/// and retrieve them.
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

  @protected
  late void Function() _buildView;

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
  /// [listener] is the optional listener that is called every time [T.notifyListeners] is called. Do not specify
  /// [listener] when you only want to rebuild [View] when [T.notifyListeners] is called.
  ///
  /// Usages like below rebuild [View] every time [SomeChangeNotifier.notifyListeners] is called:
  ///
  ///     int get someInt => listenTo<SomeChangeNotifier>().someInt;
  ///
  ///     int doubleSomeInt() {
  ///       return 2 * listenTo<SomeChangeNotifier>().someInt;
  ///     }
  ///
  /// Note that a custom listener will need to call [notifyListeners] to rebuild [View]:
  ///
  ///     void myListener() {
  ///       // do something
  ///       notifyListeners();
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
  /// Listener are only added to [T] once regardless of the number of times [listenTo] is called.
  @protected
  ChangeNotifier listenTo<T extends ChangeNotifier>({String? name, void Function()? listener}) {
    assert(T != ChangeNotifier, _missingGenericError('listenTo', 'ChangeNotifier'));
    final changeNotifier = Registrar.get<T>(name: name);
    final listenerToAdd = listener ?? _buildView;
    final subscription = _Subscription(changeNotifier: changeNotifier, listener: listenerToAdd);
    if (!_subscriptions.contains(subscription)) {
      changeNotifier.addListener(listenerToAdd);
      _subscriptions.add(subscription);
    }
    return changeNotifier;
  }
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
