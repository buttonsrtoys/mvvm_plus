# mvvm_plus

`mvvm_plus` is a Flutter implementation of MVVM that supports sharing business logic across widgets.

`mvvm_plus` employs `ChangeNotifiers` and cherry picks the best bits of [provider](https://pub.dev/packages/provider), [get_it](https://pub.dev/packages/get_it), and [mvvm](https://pub.dev/packages/mvvm) (while fixing the not-so-good bits), so will be familiar to most Flutter developers.

## Model-View-View Model (MVVM)

As with all MVVM implementations, `mvvm_plus` divides responsibilities into an immutable rendering (called the *View*) and a presentation model (called the *View Model*):

      [View] <--> [View Model] <--> [Model]

With `mvvm_plus`, the View is a Flutter widget and the View Model is a Dart model. 

`mvvm_plus` goals:
- Provide a state management framework that clearly separates business logic from UI.
- Optionally provide access to View Models from anywhere in the widget tree.
- Work well alone or with other state management packages (RxDart, Provider, GetIt, ...).
- Be scalable and performant, so suitable for both indy and production apps.
- Be simple.
- Be small.

## Views and View Models

With `mvvm_plus` you extend the `View` the way your extend a `StatelessWidget` widget. E.g., you override the `build` function:

    class MyWidget extends View<MyWidgetViewModel> {
      MyWidget({super.key}) : super(viewModelBuilder: () => MyWidgetViewModel());
      Widget build(BuildContext context) {
        return Text(viewModel.someText); // <- state is stored in your custom "viewModel" instance
      }
    }

Your `ViewModel` subclass is a Dart class that inherits from `ViewModel`:

    class MyWidgetViewModel extends ViewModel {
      String someText;
    }

Views are frequently nested and can be large, like an app page, feature, or even an entire app. Or small, like a password field or a button.

Like the Flutter `State` class associated with `StatefulWidget`, the `ViewModel` class provides `initState()` and `dispose()` which is handy for subscribing to and canceling listeners to streams, subjects, change notifiers, etc.:

    class MyWidgetViewModel extends ViewModel {
      @override
      initState() {
        super.initState();
        _streamSubscription = Services.someStream.listen(myListener);
      }
      @override
      void dispose() {
        _streamSubscription.cancel();
        super.dispose();
      }
      late final StreamSubscription<bool> _streamSubscription;
    }

## Rebuilding the View

`ViewModel` includes a `buildView` method for when you want to rebuild `View`:

    class MyWidgetViewModel extends ViewModel {
      int counter;
      void incrementCounter() {
        counter++;
        buildView(); // <- queues View to rebuild
      }
    }

## Retrieving View Models from anywhere

Occasionally you need to access another widget's `ViewModel` instance (e.g., if it's an ancestor or on another branch of the widget tree). This is accomplished by "registering" the View Model with the "register" parameter of the `ViewModel` constructor (similar to how `get_it` works):

    class MyOtherWidget extends View<MyOtherWidgetViewModel> {
      MyOtherWidget(super.key) : super(
        viewModelBuilder: () => MyOtherWidgetViewModel(
          register: true, // <- registers the View Model so other widgets and models can access
        ),
      );
    }

Widgets and models can then "get" the registered View Model with the `Mvvm` static function `get`:

    final otherViewModel = Mvvm.get<MyOtherWidgetViewModel>();

Like `get_it`, `mvvm_plus` uses singletons that are not managed by `InheritedWidget`. So, widgets don't need to be children of a `View` widget to get its registered View Model. This is a big plus for use cases where the accessed View Model is not an ancestor.

Unlike `get_it` the lifecycle of all `ViewModel` instances (including registered) are bound to the lifecycle of the `View` instances that instantiated them. So, when a `View` instance is removed from the widget tree, its `ViewModel` is disposed.

On rare occasions when you need to register multiple View Models of the same type, just give each View Model instance a unique name:

    class MyOtherWidget extends View<MyOtherWidgetViewModel> {
      MyOtherWidget(super.key) : super(
        viewModelBuilder: () => MyOtherWidgetViewModel(
          register: true,
          name: 'Header', // <- distinguishes View Model from other registered View Models of the same type
        ),
      );
    }

and then get the `ViewModel` by type and name:

    final headerText = Mvvm.get<MyOtherWidgetViewModel>(name: 'Header').someText;
    final footerText = Mvvm.get<MyOtherWidgetViewModel>(name: 'Footer').someText;

## Adding additional ChangeNotifiers 

The `ViewModel` constructor optionally registers a View Model, but sometimes you want registered models that are not associated with Views. `mvvm_plus` with the `Registrar` widget from the `Registrar` package:

    Registrar<MyModel>(
      builder: () => MyModel(),
      child: MyWidget(),
    );

The `Registar` widget registers the model when added to the widget tree and unregisters it when removed. To register multiple models with a single widget, check out `MultiRegistrar`.

## Listening to other widget's View Models

`ViewModel` has a `get` method that retrieves models registered by another `ViewModels`. (Or registered with a `Registrar` widget)

    final text = get<MyOtherWidgetViewModel>().someText;

`get` retrieves a registered `MyOtherWidgetViewModel` but does not listen for future changes. For that, use `listenTo` from within your `ViewModel`:

    final text = listenTo<MyOtherWidgetViewModel>().someText;

`listenTo` adds the `buildView` method as a listener to queue `View` to build every time `MyOtherWidgetViewModel.notifyListeners()` is called. If you want to do more than just queue a build, you can give `listenTo` a listener function that is called when `notifyListeners` is called:

    @override
    void initState() {
      super.initState();
      listenTo<MyWidgetViewModel>(listener: myListener);
    }

If you want to rebuild your View after your custom listener finishes, just call `buildView` within your listener:

    @override
    void myListener() {
      // do some stuff
      buildView(); 
    }

Either way, listeners passed to `get` are automatically removed when your ViewModel instance is disposed.

## notifyListeners vs buildView

When your `View` and `ViewModel` classes are instantiated, `buildView` is added as a listener to your `ViewModel`. So, calling `buildView` or `notifyListeners` from within your `ViewModel` will both rebuild your `View`. So, what's the difference between calling `buildView` and `notifyListeners`? Nothing, except if your `ViewModel` is registered. Any listeners to your registered `ViewModel` will be called on `notifyListeners` but not on `buildView`. Therefore, to prevent accidentally notifying listeners, it is a best practice to use `buildView` unless your use case requires listeners to be notified of a change.

## But what about ValueNotifiers?

Rather than listening to a whole model, sometimes you want more granularity and only want to listen to a value in a model. That's where the Flutter `ValueNotifier` comes in. You can register a `ValueNotifier`:

    Registrar.register<MyValueNotifier>(instance: myValueNotifier);

And you `get` or `listenTo` to the `ValueNotifier` the same as a registered `ViewModel` (because they are both subclasses of `ChangeNotifier`):

    final myValue = listenTo<MyValueNotifier>().value;

## That's it! 

The [example app](https://github.com/buttonsrtoys/view/tree/main/example) demos much of the above functionality and shows how small and organized `mvvm_plus` classes typically are.

If you have questions or suggestions on anything `mvvm_plus`, please do not hesitate to contact me.