# mvvm_plus (mvvm+)

![mvvm plus logo](https://github.com/buttonsrtoys/mvvm_plus/blob/main/assets/MvvmPlusLogo.png)

MVVM+ is a Flutter implementation of MVVM, plus support for sharing business logic across widgets.

MVVM+ extends ChangeNotifier, ValueNotifier, and StatefulWidget. So, if you are familiar with these
Flutter classes, MVVM+ will feel very familiar you.

## Model-View-View Model (MVVM)

As with all MVVM implementations, MVVM+ organizes UI into an object called the View. The business
logic associated with the View is organized into an object called the View Model. And states that
span two or more View Models are organized into one or more Models.

![mvvm flow](https://github.com/buttonsrtoys/mvvm_plus/blob/main/assets/MvvmFlow.png)

States are mutated in the View Model and the Model, but not the View. With MVVM+, the View is a
Flutter widget and the View Model and Model are Dart models that extend ChangeNotifier.

MVVM+ goals:

- Clearly separate business logic from UI.
- Optionally support access to View Models from anywhere in the widget tree.
- Work well alone or with other state management packages (BLoC, RxDart, Provider, GetIt, ...).
- Be scalable and performant, so suitable for both indy and production apps.
- Be simple.
- Be small.

## API

MVVM+'s API introduces only three methods to existing Flutter APIs: `get`, `listenTo`,
and `buildView`:

### Model API:###

- Extends ChangeNotifier and adds:
    - get
    - listenTo

### View API:###

- Extends StatefulWidget/State and adds:
    - get
    - listenTo

### ViewModel API:###

- Extends Model and adds:
    - buildView

### Property API:###

- `typedef` of ValueNotifier, so adds nothing.

Do not be fooled by MVVM+'s minimal interface. As documented below, it a full implementation of
MVVM.

## Views and View Models

To create a View Model, extend ViewModel:

```dart 
class MyWidgetViewModel extends ViewModel {
  String someText;
}
```

To create a View, extend View. You give the super constructor a builder for your ViewModel (via
the "viewModelBuilder" parameter) and you override View's `build` function (just like
StatelessWidget):

```dart
class MyWidget extends View<MyWidgetViewModel> {
  MyWidget({super.key}) : super(viewModelBuilder: () => MyWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Text(viewModel.someText); // <- your "viewModel" getter
  }
}
```

Views are frequently nested and can be large, like an app page or feature. Or small, like a password
field or a button.

## Rebuilding a View

ViewModel includes a `buildView` method for rebuilding the View. You can call it explicitly:

```dart
class MyWidgetViewModel extends ViewModel {
  int counter;

  void incrementCounter() {
    counter++;
    buildView(); // <- queues View to build
  }
}
```

Or use `buildView` as a listener to bind the ViewModel to the View with a ValueNotifier:

```dart

late final counter = ValueNotifier<int>(0)
  ..addListener(buildView);
```

## initState and dispose

Like the Flutter State class associated with StatefulWidget, the ViewModel class has `initState`
and `dispose` member functions which are handy for subscribing to and canceling listeners:

    class MyWidgetViewModel extends ViewModel {
      late final StreamSubscription<bool> _streamSubscription;

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
    }

## Retrieving ViewModels from anywhere

Occasionally you need to access another widget's ViewModel instance (e.g., if it's an ancestor or on
another branch of the widget tree). This is accomplished by "registering" the ViewModel with the "
register" parameter of the ViewModel constructor (similar to how GetIt works):

    class MyOtherWidget extends View<MyOtherWidgetViewModel> {
      MyOtherWidget(super.key) : super(
        viewModelBuilder: () => MyOtherWidgetViewModel(
          register: true, // <- registers ViewModel instance
        ),
      );
    }

ViewModels can then "get" the other registered ViewModel:

    final otherViewModel = get<MyOtherWidgetViewModel>();

Like GetIt, registered ViewModels are not managed by InheritedWidget. So, widgets don't need to be
children of a View widget to get its registered ViewModel. This is a big plus for use cases where
the accessed ViewModel is not an ancestor.

Unlike GetIt the lifecycle of all ViewModel instances (including registered) are bound to the
lifecycle of the View instances that instantiated them. So, when a View instance is removed from the
widget tree, its ViewModel is disposed.

On rare occasions when you need to register multiple ViewModels of the same type, just give each
ViewModel instance a unique name:

    class MyOtherWidget extends View<MyOtherWidgetViewModel> {
      MyOtherWidget(super.key) : super(
        viewModelBuilder: () => MyOtherWidgetViewModel(
          register: true,
          name: 'Header', // <- unique name
        ),
      );
    }

and then get the ViewModel by type and name:

    final headerText = get<MyOtherWidgetViewModel>(name: 'Header').someText;
    final footerText = get<MyOtherWidgetViewModel>(name: 'Footer').someText;

## Models

The Model class is a super class of ViewModel with much of the functionality of ViewModel. MVVM+
uses the [Registrar](https://pub.dev/packages/registrar) package under the hood which has a widget
named "Registrar" that adds Models to the widget tree:

    Registrar<MyModel>(
      builder: () => MyModel(),
      child: MyWidget(),
    );

The Registrar widget registers the model when added to the widget tree and unregisters it when
removed. To register multiple models with a single widget, check
out [MultiRegistrar](https://pub.dev/packages/registrar#registering-models).

## Listening to other widget's ViewModels

The `get` method of View and ViewModel retrieves registered ViewModels but does not listen for
future changes. For that, use `listenTo` from within your ViewModel:

    final text = listenTo<MyOtherWidgetViewModel>().someText;

`listenTo` performs a one-time add of the `buildView` method as a listener that is called every time
the `notifyListeners` method of MyOtherWidgetViewModel is called. If you want to do more than just
queue a build, you can give `listenTo` a listener function:

    listenTo<MyWidgetViewModel>(listener: myListener);

If you want to rebuild your View after your custom listener finishes, just call `buildView` within
your listener:

    void myListener() {
      // do some stuff
      buildView(); 
    }

Either way, listeners added by `listenTo` are automatically removed when your ViewModel instance is
disposed.

## notifyListeners vs buildView

When your View and ViewModel classes are instantiated, `buildView` is added as a listener to your
ViewModel. So, calling `buildView` or `notifyListeners` from within your ViewModel will both rebuild
your View. So, what's the difference between calling `buildView` and `notifyListeners`? Nothing,
unless your ViewModel is registered--any listeners to your registered ViewModel will be called
on `notifyListeners` but not on `buildView`. So, to eliminate unnecessary View builds, it is a best
practice to use `buildView` unless your use case requires listeners to be notified of a change.

## ValueNotifiers are your MVVM Properties!

The MVVM pattern uses the term "Properties" to describe public values of View Models that are bound
to Views and other objects. I.e., when the Property is changed, listeners are notified:

    class MyViewModel {
      final counter = Property<int>(0);
    }

In Flutter, this is how ValueNotifiers work. So, MVVM+ added a `typedef` that equates Property with
ValueNotifier. As you use MVVM+, feel free to call your public members of ViewModels "Properties"
or "ValueNotifiers", whichever is more comfortable to you. (In the MVVM+ documentation, I use "
ValueNotifier" to be more transparent with the Flutter underpinnings, but in practice, I prefer to
use "Property" because it clarifies its purpose and because "Property" has fewer characters! :)

So, for more granularity than listening to an entire registered Model, you can listen to one of its
ValueNotifiers. So, if you have a Model that notifies in more than one place:

    class CloudService extends Model {
      CloudService({super.register, super.name});
      late final currentUser = ValueNotifier<User>(null)..addListener(buildView);
      void doSomething() {
        // do something
        notifyListeners();
      }
    }

you can listen to just one of its ValueNotifiers:

    final cloud = get<CloudService>();
    final currentUser = listenTo<ValueNotifier<User>>(notifier: cloud.currentUser).value;

# Additional documentation

For an in-the-weeds discussion of the code behind MVVM+, see my medium
article [How to Extend StatefulWidget into an MVVM Workhorse](https://medium.com/@buttonsrtoys/mvvm-with-flutter-e162a59984cf)
.

For an *slightly* higher level introduction to MVVM+, see my
article [Flutter State Management with MVVM+](https://medium.com/@buttonsrtoys/flutter-state-management-with-mvvm-1b55e6911975)
. Please note that most of this ReadMe page overlaps with this article.

# Example

(The source code for the repo example is under the Pub.dev "Example" tab and in the
GitHub `example/lib/main.dart` file.)

This example increments a number (0, 1, 2, ...) and a letter character (a, b, c, ...) using a single
increment floating action button (FAB) that toggles between incrementing the number and the letter.
When the FAB displays "+1" a press increments the number and when it displays "+a" the character
will increment.

Two View widgets are used in this example. One for the increment button/FAB which maintains the
state ("+1"/"+a") and one for the page which maintains current count and other states.

The page listens to two services: one that changes the number color and another that changes the
letter color. The number color service has a stream that emits a new color every N seconds. The
letter color service is a ChangeNotifier with a timer that changes the current letter color and then
calls `notifyListeners`.

![example](https://github.com/buttonsrtoys/mvvm_plus/blob/main/example/example.gif)

## That's it!

The [example app](https://github.com/buttonsrtoys/view/tree/main/example/lib) demos much of the
above functionality and shows how small and organized MVVM+ classes typically are.

If you have questions or suggestions on anything MVVM+, please do not hesitate to contact me.