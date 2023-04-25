import 'package:bilocator/bilocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef Property<T> = ValueNotifier<T>;

/// A ViewWidget with a builder for a ViewModel
///
/// Consumed like StatelessWidget. I.e., override its Widget build() function
///
///   class MyWidget extends ViewWidget<MyWidgetViewModel> {
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
@Deprecated('This class was renamed to [ViewWidget] due to a name collision in the Flutter beta channel')
typedef View<T extends ViewModel> = ViewWidget<T>;

abstract class ViewWidget<T extends ViewModel> extends StatefulWidget {
  ViewWidget({
    required T Function() builder,
    String? name,
    Location? location,
    super.key,
  })  : assert(T != ViewModel, _missingGenericError('ViewWidget constructor', 'ViewModel')),
        assert(location != Location.tree || name == null, 'ViewWidget cannot name a ViewModel that is not registered'),
        _name = name,
        _builder = builder,
        _location = location;
  final T Function() _builder;
  final _stateInstance = _StateInstance<T>();
  final Location? _location;
  final String? _name;

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

  /// Returns the [ViewModel] subclass bound to this [ViewWidget].
  T get viewModel => _stateInstance.value._viewModel;

  /// Same functionality as [State.context].
  BuildContext get context => _stateInstance.value.context;

  /// Same functionality as [State.mounted].
  bool get mounted => _stateInstance.value.mounted;

  /// Same functionality as [State.didUpdateWidget].
  @protected
  @mustCallSuper
  void didUpdateWidget(covariant ViewWidget<T> oldWidget) {}

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

  /// Gets the state associated with this ViewWidget class
  U getState<U extends ViewState<T>>() {
    assert(
      _stateInstance.value is U,
      'getState failed because the constructed State class is of type '
      '${_stateInstance.value.runtimeType} which does not match the generic type $U. Possible causes:\n'
      ' - You did not override the function `createState`. See the docs for `createState` for more information.'
      ' - The generic was omitted. E.g., you used `getState()` instead of `getState<MyWidgetState>().`',
    );
    return _stateInstance.value as U;
  }

  /// Same functionality as [StatelessWidget.build]. E.g., override this function to define the interface.
  @protected
  Widget build(BuildContext context);

  /// Builds the state than manages this [ViewWidget]
  ///
  /// This functions is already defined for this [ViewWidget] class so typically doesn't need to be overridden. An exception
  /// is when you need to add a mixin to the state class. To add a mixin, extend ViewState<ViewWidget<T>> with the mixin:
  ///
  ///    class MyWidget extends ViewWidget<MyWidgetViewModel> {
  ///      MyWidget({super.key}) : super(builder: () => MyWidgetViewModel());
  ///
  ///      // Overriding createState is only required when adding mixins
  ///      @override
  ///      MyWidgetState createState() => MyWidgetState();
  ///
  ///      @override
  ///      Widget build(BuildContext context) {
  ///      // Use `getState` to retrieve your custom ViewState/mixin object
  ///        return getState<MyWidgetState>().buildGreeting(viewModel.message.value);
  ///      }
  ///    }
  ///
  ///    // Extend `ViewState` and add your mixin
  ///    class MyWidgetState extends ViewState<MyWidgetViewModel> with MyMixin {}
  ///
  ///    mixin MyMixin {
  ///      buildGreeting(String message) => Text(message);
  ///    }
  ///
  ///    class MyWidgetViewModel extends ViewModel {
  ///      late final message = createProperty<String>('Hello');
  ///    }
  ///
  @override
  State<ViewWidget<T>> createState() => ViewState<T>();
}

/// [ViewState] stores the states of [ViewWidget], including its [ViewModel]
///
/// Use this public access wisely. MVVM+ uses this class for logic and states. Typically it does not need to be
/// accessed. An exception to extending this class for mixins. See [ViewWidget.createState] for more info.
class ViewState<T extends ViewModel> extends State<ViewWidget<T>> with BilocatorStateImpl<T> {
  late T _viewModel;

  @override
  @mustCallSuper
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
  @mustCallSuper
  void dispose() {
    disposeImpl(location: widget._location, name: widget._name, dispose: true);
    super.dispose();
  }

  void _buildView() {
    if (mounted) setState(() {});
  }

  T _buildViewModel() {
    final viewModel = widget._builder();
    viewModel.buildView = _buildView;
    viewModel._context = context;
    viewModel.addListener(viewModel.buildView);
    return viewModel;
  }

  @override
  void didUpdateWidget(covariant ViewWidget<T> oldWidget) {
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

/// Wrapper for [ViewState] to facilitate access by [ViewWidget]
class _StateInstance<T extends ViewModel> {
  late ViewState<T> value;
}

/// Base class for a [Model]
abstract class Model extends ChangeNotifier with Observer {
  @override
  @mustCallSuper
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  /// Creates a [Property] and adds a listener to it.
  ///
  /// [listener] is the listener to add. If listener is null, [Model.notifyListeners] is used.
  ///
  /// Requires the `late` keyword when used during initialization:
  ///
  ///   late final counter = createProperty<int>(0);
  ///
  /// If a property is required with no initial listeners, instantiate a ValueNotifier:
  ///
  ///   final counter = Property<int>(0);
  ///
  ValueNotifier<T> createProperty<T>(T initialValue, {VoidCallback? listener}) {
    final property = ValueNotifier<T>(initialValue);
    property.addListener(listener ?? notifyListeners);
    return property;
  }

  /// Creates a [FutureProperty] and adds a listener.
  ///
  /// [listener] is the listener to add. If listener is null, [Model.notifyListeners] is used.
  ///
  /// Requires the `late` keyword when used during initialization:
  ///
  ///   late final counter = createFutureProperty<int>(0);
  ///
  /// If a property is required with no initial listeners, instantiate a Property instead:
  ///
  ///   final counter = Property<int>(0);
  ///
  FutureProperty<T> createFutureProperty<T>(Future<T> initialValue, {VoidCallback? listener}) {
    final futureProperty = FutureProperty<T>(initialValue);
    futureProperty.addListener(listener ?? notifyListeners);
    return futureProperty;
  }

  /// Creates a [StreamProperty] and adds a listener.
  ///
  /// [listener] is the listener to add. If listener is null, [Model.notifyListeners] is used.
  ///
  /// Requires the `late` keyword when used during initialization:
  ///
  ///   late final counter = createStreamProperty<int>(createStream());
  ///
  /// If a stream is required with no initial listeners, instantiate a StreamProperty instead:
  ///
  ///   final counter = StreamProperty<String>(createStream());
  ///
  StreamProperty<T> createStreamProperty<T>(Stream<T> initialValue, {VoidCallback? listener}) {
    final streamProperty = StreamProperty<T>(initialValue);
    streamProperty.addListener(listener ?? notifyListeners);
    return streamProperty;
  }
}

/// Base class for ViewWidget Models
///
/// [register] is whether the subclass ([ViewModel], [ValueNotifier]) should "register", meaning that it can be located
/// using [ViewModel.get], [ViewWidget.get], [ViewModel.listenTo], or [ViewWidget.listenTo], Subclasses are typically only
/// registered when they need to be located by widgets "far away" (e.g., descendants or on another branch.)
/// [name] is the optional unique name of the registered ViewWidget Model. Typically registered ViewWidget Models are not named.
/// On rare occasions when multiple ViewWidget Models of the same type are registered, unique names uniquely identify them.
abstract class ViewModel extends Model {
  /// The BuildContext of the associated [ViewWidget]
  @nonVirtual
  @protected
  BuildContext get context => _context;
  late final BuildContext _context;

  /// Queues [ViewWidget] to rebuild.
  ///
  /// Typically called when data rendered in [ViewWidget] changed:
  ///
  ///     int _counter = 0;
  ///     void incrementCounter() {
  ///       _counter++;
  ///       buildView();
  ///     }
  ///
  /// or used to bind a [ViewModel] to a [ViewWidget]:
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
  /// [buildView]. When this [ViewModel] is registered, calling [notifyListeners] will queue [ViewWidget] to build AND
  /// will also notify the listeners of [ViewModel] of a change, while [buildView] will not notify other listeners.
  /// Therefore, to avoid accidentally notifying listeners, defer to [buildView] unless listeners need to be notified.
  ///
  /// Typically this method is not overridden.
  @protected
  late void Function() buildView = _defaultBuildView;

  /// Returns the number of calls to buildView when unit testing a ViewModel
  ///
  /// [buildViewCalls] is for unit testing a [ViewModel]. [ViewModel.buildView] is initialized with a simple counter
  /// function that counts the number of times the build function is called. [buildViewCalls] returns the number of
  /// calls made to this counter function.
  ///
  /// Returns -1 if [buildView] was overridden. E.g., when a ViewModel is pair with a ViewWidget.
  int buildViewCalls() => buildView == _defaultBuildView ? _buildViewCalls : -1;

  /// see the comments in [buildViewCalls]
  int _buildViewCalls = 0;
  void _defaultBuildView() => _buildViewCalls++;

  /// Creates a property and adds a listener to it.
  ///
  /// [listener] is the listener to add. If listener is null, [buildView] is used. (Note that the default of adding
  /// [buildView] is different than the [Model] base class which adds [notifyListeners] as a default.)
  ///
  /// This function cannot be called during initialization. So, use late:
  ///
  ///     late final myProperty = createProperty<int>(0);
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

  /// Creates a [FutureProperty] and adds a listener.
  ///
  /// [listener] is the listener to add. If listener is null, [Model.notifyListeners] is used.
  ///
  /// Requires the `late` keyword when used during initialization:
  ///
  ///   late final counter = createFutureProperty<int>(0);
  ///
  /// If a property is required with no initial listeners, instantiate a Property instead:
  ///
  ///   final counter = Property<int>(0);
  ///
  @override
  FutureProperty<T> createFutureProperty<T>(Future<T> initialValue, {VoidCallback? listener}) {
    final futureProperty = FutureProperty<T>(initialValue);
    futureProperty.addListener(listener ?? buildView);
    return futureProperty;
  }

  /// Creates a [StreamProperty] and adds a listener.
  ///
  /// [listener] is the listener to add. If listener is null, [Model.notifyListeners] is used.
  ///
  /// Requires the `late` keyword when used during initialization:
  ///
  ///   late final counter = createStreamProperty<int>(createStream());
  ///
  /// If a stream is required with no initial listeners, instantiate a StreamProperty instead:
  ///
  ///   final counter = StreamProperty<String>(createStream());
  ///
  @override
  StreamProperty<T> createStreamProperty<T>(Stream<T> initialValue, {VoidCallback? listener}) {
    final streamProperty = StreamProperty<T>(initialValue);
    streamProperty.addListener(listener ?? buildView);
    return streamProperty;
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

/// Empty ViewModel used by [StatelessViewWidget]
class _StatelessViewModel extends ViewModel {}

/// A [ViewWidget] with a predefined [ViewModel] that has no states.
///
/// This is a convenience class for creating Views that don't have any states but update on changes to registered
/// ChangeNotifiers. E.g., a widget that listens to a service but doesn't have its own states.
///
/// So, if a ViewWidget has no states but you want to listen to a registered ChangeNotifier, instead of creating an empty
/// ViewModel and a ViewWidget that consumes it:
///
///     class MyStatelessViewModel extends ViewModel {}
///
///     class MyView extends ViewWidget<MyStatelessViewModel> {
///       MyView({super.key}) : super(viewModelBuilder: () => MyStatelessViewModel());
///       Widget build(BuildContext context) => Container();
///     }
///
/// you can skip MyStatelessViewModel and its builder and instead write
///
///     class MyView extends StatelessView {
///       MyView({super.key});
///       @override
///       Widget build(BuildContext context) => Container();
///     }
///
/// Under the hood, an empty ViewModel is created for [StatelessViewWidget]
///
@Deprecated('This class was renamed to [StatelessViewWidget]')
typedef StatelessView = StatelessViewWidget;

/// Deprecated because of a name collision with [ViewWidget] in Flutter beta channel
@Deprecated('This class was renamed to [StatelessViewWidget]')
typedef ViewWithStatelessViewModel = StatelessViewWidget;

abstract class StatelessViewWidget extends ViewWidget<_StatelessViewModel> {
  StatelessViewWidget({super.key}) : super(builder: () => _StatelessViewModel());

  @override
  @protected
  Widget build(BuildContext context);
}

/// Property that manages a Future and notifies listeners when Future resolves.
///
/// [data] is the value of the resolved Future. Check if [hasData] is true before trying to retrieve the data as
/// calling [data] before the Future resolves will throw an exception.
///
/// The [value] field holds the [Future].
///
/// Typical usage:
///
///     @override
///     Widget build(BuildContext context) {
///       return futureName.hasData
///         ? Text('${futureName.data}')
///         : CircularProgressIndicator();
///     }
///
class FutureProperty<T extends Object?> extends ValueNotifier<Future<T>> {
  FutureProperty(super.value) {
    _getFuture(value);
  }

  /// Setter for a new Future.
  @override
  set value(Future<T> newValue) {
    if (super.value != newValue) {
      super.value = newValue;
      _getFuture(value);
      notifyListeners();
    }
  }

  /// Returns true if one ore more values in stream resolved (so [data] is value).
  bool get hasData => _hasData;
  bool _hasData = false;
  late T _data;

  /// The data in the resolved Future. Use [hasData] to see if Future resolved (so data is available.)
  T get data {
    if (!_hasData) {
      throw Exception('FutureProperty.data was called when the Future has not yet resolved.');
    }
    return _data;
  }

  void _getFuture(Future<T> future) async {
    _hasData = false;
    _data = await future;
    _hasData = true;
    notifyListeners();
  }
}

/// Property that manages a Stream and notifies listeners when its value updates.
///
/// [data] is the value of the resolved Stream. Check if [hasData] is true before trying to retrieve the data as
/// calling [data] before the Stream resolves will throw an exception.
///
/// The [value] field holds the [Stream].
///
/// Typical usage:
///
///     @override
///     Widget build(BuildContext context) {
///       return weatherConditionsStream.hasData
///         ? Text('${weatherConditionsStream.data}')
///         : CircularProgressIndicator();
///     }
///
class StreamProperty<T extends Object?> extends ValueNotifier<Stream<T>> {
  StreamProperty(super.value) {
    _getStream(value);
  }

  /// Setter for a new Stream.
  @override
  set value(Stream<T> newValue) {
    if (super.value != newValue) {
      super.value = newValue;
      _getStream(value);
      notifyListeners();
    }
  }

  /// Returns true if one ore more values in stream resolved (so [data] is value).
  bool get hasData => _hasData;
  late T _data;
  bool _hasData = false;

  /// Current stream value. Use [hasData] to see if data is available.
  T get data {
    if (!_hasData) {
      throw Exception('StreamProperty.data was called when the Stream has not yet resolved.');
    }
    return _data;
  }

  void _getStream(Stream<T> stream) async {
    _hasData = false;
    await for (final value in stream) {
      _data = value;
      _hasData = true;
      notifyListeners();
    }
  }
}

String _missingGenericError(String function, String type) =>
    'Missing generic error: "$function" called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
