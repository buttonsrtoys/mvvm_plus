import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:bilocator/bilocator.dart';

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
/// [builder] is a builder for a [ViewModel] subclass.
/// [name] is the optional name for the [ViewModel] if registered.
/// [location] is [Location.registry] to make the [ViewModel] globally available as a single service that is gettable
/// from anywhere, [Location.tree] to add the [ViewModel] to the widget tree to be accessible by descendants, or null
/// (the default) to not make the [ViewModel] accessible by other widgets and models. See [get] and
/// [listenTo] for how to get and listen to models added to the registry or widget tree.
abstract class View<T extends ViewModel> extends StatefulWidget {
  View({
    required T Function() builder,
    String? name,
    Location? location,
    super.key,
  })  : assert(T != ViewModel, _missingGenericError('View constructor', 'ViewModel')),
        assert(location != Location.tree || name == null, 'View cannot name a ViewModel that is not registered'),
        _name = name,
        _builder = builder,
        _location = location;
  final T Function() _builder;
  final _stateInstance = _StateInstance<T>();
  final Location? _location;
  final String? _name;

  /// Returns the [ViewModel] subclass bound to this [View].
  T get viewModel => _stateInstance.value._viewModel;

  /// Get a registered object.
  ///
  /// Uses [ViewModel.get] to get a registered object. (See [ViewModel.get] for more details.)
  @protected
  U get<U extends Object>({BuildContext? context, String? name}) => viewModel.get<U>(context: context, name: name);

  /// Get a registered ChangeNotifier and adds a [ViewModel.buildView] listener to [U].
  ///
  /// See [Model.listenTo] for more details.
  @protected
  U listenTo<U extends ChangeNotifier>({BuildContext? context, U? notifier, String? name}) =>
      viewModel.listenTo<U>(context: context, notifier: notifier, name: name);

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
class _ViewState<T extends ViewModel> extends State<View<T>> with BilocatorStateImpl<T> {
  late T _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = _buildViewModel();
    _viewModel.initState();
    initStateImpl(
      location: widget._location,
      name: widget._name,
      instance: _viewModel,
    );
  }

  @override
  void dispose() {
    disposeImpl(location: widget._location, name: widget._name, dispose: true);
    super.dispose();
  }

  T _buildViewModel() {
    final viewModel = widget._builder();
    viewModel.buildView = () => setState(() {});
    viewModel._context = context;
    viewModel.addListener(viewModel.buildView);
    return viewModel;
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
    return buildImpl(location: widget._location, child: widget.build(context));
  }
}

/// Wrapper for [_ViewState] to facilitate access by [View]
class _StateInstance<T extends ViewModel> {
  late _ViewState<T> value;
}

/// Base class for a [Model]
abstract class Model extends ChangeNotifier with Observer {
  @override
  @mustCallSuper
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  /// Creates a property and adds a listener to it.
  ///
  /// [listener] is the listener to add. If listener is null, [Model.notifyListeners] is used.
  ///
  /// Requires the `late` keyword when used during initialization:
  ///
  ///   late final counter = createProperty<int>(0);
  ///
  /// If a property is required with no initial listeners, instantiate a ValueNotifier:
  ///
  ///   final firstName = ValueNotifier<String>('');
  ///
  /// or its typedef equivalent:
  ///
  ///   final lastName = Property<String>('');
  ///
  ValueNotifier<T> createProperty<T>(T initialValue, {VoidCallback? listener}) {
    final property = ValueNotifier<T>(initialValue);
    property.addListener(listener ?? notifyListeners);
    return property;
  }
}

/// Base class for View Models
///
/// [register] is whether the subclass ([ViewModel], [ValueNotifier]) should "register", meaning that it can be located
/// using [ViewModel.get], [View.get], [ViewModel.listenTo], or [View.listenTo], Subclasses are typically only
/// registered when they need to be located by widgets "far away" (e.g., descendants or on another branch.)
/// [name] is the optional unique name of the registered View Model. Typically registered View Models are not named.
/// On rare occasions when multiple View Models of the same type are registered, unique names uniquely identify them.
abstract class ViewModel extends Model {
  /// The BuildContext of the associated [View]
  @nonVirtual
  @protected
  BuildContext get context => _context;
  late final BuildContext _context;

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
  late void Function() buildView = unusedBuildView;

  /// Returns the number of calls to buildView when unit testing a ViewModel
  ///
  /// [buildView] is initialized with a simple counter function that counts the number of times the build function is
  /// called primarily for using for unit testing. [_buildViewCalls] returns the number of calls made to [buildView].
  ///
  /// Returns -1 for the invalid usage of calling this function after [buildView] was overridden. E.g., during View
  /// initialization for a ViewModel that is pair with a View.
  int buildViewCalls() => buildView == unusedBuildView ? _buildViewCalls : -1;

  /// see the comments in [buildViewCalls]
  int _buildViewCalls = 0;

  /// see the comments in [buildViewCalls]
  void unusedBuildView() => _buildViewCalls++;

  /// Creates a property and adds a listener to it.
  ///
  /// [listener] is the listener to add. If listener is null, [buildView] is used. (Note that the default of adding
  /// [buildView] is different than the [Model] base class which adds [notifyListeners] as a default.)
  ///
  /// This function cannot be called during initialization. So, use late:
  ///
  ///     late final myProperty = createProporty<int>(0);
  ///
  /// Or call from within initState:
  ///
  ///     late final myProperty;
  ///     @override
  ///     void initState() {
  ///         super.initState();
  ///         myProperty = createProperty<int>(0);
  ///     }
  ///
  /// See [Model.createProperty] for more information.
  @override
  ValueNotifier<T> createProperty<T>(T initialValue, {VoidCallback? listener}) {
    final property = ValueNotifier<T>(initialValue);
    property.addListener(listener ?? buildView);
    return property;
  }

  /// Adds a listener to a ChangeNotifier.
  ///
  /// If [listener] is null then [buildView] is used as the listener. See [Model.listenTo] for more details.
  @protected
  @override
  T listenTo<T extends ChangeNotifier>({BuildContext? context, T? notifier, String? name, void Function()? listener}) {
    final listenerToAdd = listener ?? buildView;
    return super.listenTo(context: context, name: name, notifier: notifier, listener: listenerToAdd);
  }

  @protected
  @mustCallSuper
  void initState() {}
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
  ViewWithStatelessViewModel({super.key}) : super(builder: () => _StatelessViewModel());

  @override
  @protected
  Widget build(BuildContext context);
}

/// Property class, which is identical to a ValueNotifier class but with some error functionality.
///
/// [this._value] is the initial value.
/// [onInvalid] is called when the [value] getter is called when [valid] is false. Ideally, [onInvalid] should never
/// be called because because the consumer should check the state of [valid] before using the [value] getter
/// (assuming, of course, that the value is invalid-able). The default value for [onInvalid] is a function that
/// throws an exception.
class Property<T extends Object> extends ValueNotifier<T> {
  Property(super.value, {VoidCallback? onGetInvalidValue}) {
    if (onGetInvalidValue != null) {
      _onGetInvalidValue = onGetInvalidValue!;
    }
  }

  bool valid = true;
  VoidCallback _onGetInvalidValue = () => throw Exception('Property.value called when Property.valid == false');

  @override
  T get value {
    if (!valid) {
      _onGetInvalidValue();
    }
    return super.value;
  }
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
