# mvvm_get

`mvvm_get` is a state management package for Flutter that implements MVVM. 

`mvvm_get` is effectively syntactic sugar for a `StatefulWidget` with support to share business logic across widgets. It employs `ChangeNotifiers` and optionally stores models in gettable singletons, so will feel familiar to most Flutter developers.

As with every implementation of MVVM, `mvvm_get` divides responsibilities into an immutable rendering (called the *View*) and a presentation model (called the *View Model*):

      [View] <--> [View Model] <--> [Model]

With `mvvm_get`, the View is a Flutter widget and the View Model is a Dart model. 

`mvvm_get` goals:
- Provide a state management framework that clearly separates business logic from the presentation.
- Optionally provide access to View Models from anywhere in the widget tree.
- Work well alone or with other state management packages (RxDart, Provider, GetIt, ...).
- Be scalable and performant, so suitable for both indy and production apps.
- Be simple.
- Be small.

## Views and View Models

The heart of `mvvm_get` is its `mvvm_get` class, which is a stateful widget that maintains its state in a separate `ViewModel` instance:

    class MyWidget extends View<MyWidgetViewModel> {
      MyWidget({super.key}) : super(viewModelBuilder: () => MyWidgetViewModel());
      Widget build(BuildContext context) {
        return Text(viewModel.someText); // <- state maintained in your custom "viewModel" instance
      }
    }

The `mvvm_get` class follows the same pattern as a `StatelessWidget` widget. E.g., you override the `build` function (shown above). Your custom `ViewModel` is a Dart class that inherits from `ViewModel`:

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

`ViewModel` inherits from `ChangeNotifier`, so you call `notifyListeners()` from your `ViewModel` when you want to rebuild your `mvvm_get`:

    class MyWidgetViewModel extends ViewModel {
      int counter;
      void incrementCounter() {
        counter++;
        notifyListeners(); // <- queues View to rebuild
      }
    }

## Retrieving View Models from anywhere

Occasionally you need to access another widget's `ViewModel` instance (e.g., if it's an ancestor or on another branch of the widget tree). This is accomplished by "registering" the View Model with the "registerViewModel" parameter of the `mvvm_get` constructor (similar to how `get_it` works):

    class MyOtherWidget extends View<MyOtherWidgetViewModel> {
      MyOtherWidget(super.key) : super(
        viewModelBuilder: () => MyOtherWidgetViewModel(),
        registerViewModel: true, // <- registers the View Model so other widgets and models can access
      );
    }

Widgets and models can then "get" the registered View Model with the `mvvm_get` static function `get`:

    final otherViewModel = View.get<MyOtherWidgetViewModel>();

Like `get_it`, `mvvm_get` uses singletons that are not managed by `InheritedWidget`. So, widgets don't need to be children of a `mvvm_get` widget to get its registered View Model. This is a big plus for use cases where the accessed View Model is not an ancestor.

Unlike `get_it` the lifecycle of all `ViewModel` instances (including registered) are bound to the lifecycle of the `mvvm_get` instances that instantiated them. So, when a `mvvm_get` instance is removed from the widget tree, its `ViewModel` is disposed.

On rare occasions when you need to register multiple View Models of the same type, just give each View Model instance a unique name:

    class MyOtherWidget extends View<MyOtherWidgetViewModel> {
      MyOtherWidget(super.key) : super(
        viewModelBuilder: () => MyOtherWidgetViewModel(),
        registerViewModel: true,
        name: 'Header', // <- distinguishes View Model from other registered View Models of the same type
      );
    }

and then get the `ViewModel` by type and name:

    final headerText = View.get<MyOtherWidgetViewModel>(name: 'Header').someText;
    final footerText = View.get<MyOtherWidgetViewModel>(name: 'Footer').someText;

## Adding additional ChangeNotifiers 

The `mvvm_get` constructor optionally registers a View Model, but sometimes you want registered models that are not associated with Views. `mvvm_get` supports this with its `ChangeNotifierRegistrar`:

    ChangeNotifierRegistrar<MyChangeNotifier>(
      changeNotifierBuilder: () => MyChangeNotifier(),
      child: MyWidget(),
    );

The `ChangeNotifierRegistar` registers the `ChangeNotifier` when added to the widget tree and unregisters them when removed. To register multiple `ChangeNotifier`s with a single widget, check out `MultiChangeNotifierRegistrar`.

## Listening to ViewModels and ChangeNotifiers

`View.get` retrieves a View Model but does not queue a View build or call a listener. For that use `ViewModel.listenTo`:

    class MyWidgetViewModel extends ViewModel {
      @override
      void initState() {
        super.initState();
        listenTo<MyOtherWidgetViewModel>();
      }
    }

The above queues `mvvm_get` to build every time `MyOtherWidgetViewModel.notifyListeners()` is called. If you want to do more than just queue a build, you can give `listenTo` a listener function that is called when `notifyListeners` is called:

    @override
    void initState() {
      super.initState();
      listenTo<MyWidgetViewModel>(listener: myListener);
    }

If you want to rebuild your View after your custom listener finishes, just call `notifyListeners` within your listener:

    @override
    void myListener() {
      // do some stuff
      notifiyListeners(); 
    }

Either way, listeners passed to `listenTo` are automatically removed when your ViewModel instance is disposed.

## That's it! 

The [example app](https://github.com/buttonsrtoys/view/tree/main/example) demos much of the above functionality and shows how small and organized `mvvm_get` classes typically are.

If you have questions or suggestions on anything `mvvm_get`, please do not hesitate to contact me.