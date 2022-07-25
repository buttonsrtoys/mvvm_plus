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
/// [registerViewModel] is whether the built [ViewModel] is "registered", meaning that it can be located with
/// [Registrar.get]. View Models are typically only registered when they need to be located by a descendant of this
/// widget or by a widget on another branch of the widget tree. Note that the [View] has member [viewModel], so doesn't
/// need [Registrar.get].
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
            'Constructor was called with "name" set but not "registerViewModel". You must '
            'also set "registerViewModel" when "name" is set.'),
        assert(T != ViewModel, _missingGenericError('View constructor', 'ViewModel'));
  final T Function() viewModelBuilder;
  final bool registerViewModel;
  final String? name;

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
    if (widget.registerViewModel) {
      Registrar.unregister<T>(name: widget.name);
    } else {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _initViewModel() {
    _viewModel = widget.viewModelBuilder();
    if (widget.registerViewModel) {
      Registrar.register<T>(instance: _viewModel, name: widget.name);
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
abstract class ViewModel extends ChangeNotifier {
  @protected
  late void Function() _buildView;

  final _subscriptions = <_Subscription>[];

  /// Called when instance is created.
  @protected
  void initState() {}

  /// Called when instance is disposed.
  @override
  @mustCallSuper
  void dispose() {
    for (_Subscription subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    super.dispose();
  }

  /// getter for registered models.
  ///
  /// If [listener] is null then [View] is queued to build when [T] calls [notifyListeners]. When [listener] is
  /// non-null, the listener is called instead. Note that when [listener] is non-null, [View] is not implicitly queued
  /// to build when [notifyListeners] is called. To queue a build after [listener] finishes, add [notifyListeners] to
  /// the [listener].
  @protected
  T get<T extends Object>({String? name, bool listen = true, void Function()? listener}) {
    assert(T != Object, _missingGenericError('listenTo', 'Object'));
    assert(listen || listener == null, '"listen" must be true if "listener" is non-null.');
    final object = Registrar.get<T>(name: name);
    assert(object is ChangeNotifier || listener == null, 'You can only add listeners to a "ChangeNotifier"');
    if (listen && object is ChangeNotifier) {
      final listenerToAdd = listener ?? _buildView;
      final subscription = _Subscription(changeNotifier: object, listener: listenerToAdd);
      if (!_subscriptions.contains(subscription)) {
        object.addListener(listenerToAdd);
        _subscriptions.add(subscription);
      }
    }
    return object;
  }
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
