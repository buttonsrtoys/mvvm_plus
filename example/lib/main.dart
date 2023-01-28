import 'dart:async';

import 'package:bilocator/bilocator.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

void main() => runApp(const MyApp());

/*
Widget myApp() => Bilocators(delegates: [
      BilocatorDelegate<ColorService>(builder: () => ColorService(milliSeconds: 1500), name: 'letter'),
      BilocatorDelegate<ColorService>(builder: () => ColorService(milliSeconds: 1500), name: 'number'),
    ], child: MaterialApp(debugShowCheckedModeBanner: false, home: CounterPage()));

class CounterPage extends View<CounterPageViewModel> {
  CounterPage({super.key}) : super(location: Location.registry, builder: () => CounterPageViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Text(viewModel.letterCount.value,
                style: TextStyle(fontSize: 64, color: listenTo<ColorService>(name: 'letter').color.value)),
            Text(viewModel.numberCounter.value.toString(),
                style: TextStyle(fontSize: 64, color: listenTo<ColorService>(name: 'number').color.value)),
          ]),
        ])),
        floatingActionButton: IncrementButton());
  }
}

class CounterPageViewModel extends ViewModel {
  late final numberCounter = createProperty<int>(0);
  late final letterCount = createProperty<String>('a');

  void incrementNumber() => numberCounter.value = numberCounter.value == 9 ? 0 : numberCounter.value + 1;
  void incrementLetter() =>
      letterCount.value = letterCount.value == 'z' ? 'a' : String.fromCharCode(letterCount.value.codeUnits[0] + 1);
}

class ColorService extends Model {
  ColorService({required int milliSeconds}) {
    _timer = Timer.periodic(Duration(milliseconds: milliSeconds), (_) {
      color.value = <Color>[Colors.red, Colors.black, Colors.blue, Colors.orange][++_counter % 4];
    });
  }

  int _counter = 0;
  late final color = createProperty<Color>(Colors.orange);
  late Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class IncrementButton extends View<IncrementButtonViewModel> {
  IncrementButton({super.key}) : super(builder: () => IncrementButtonViewModel());

  @override
  MyIncrementButtonState createState() => MyIncrementButtonState();

  @override
  Widget build(BuildContext context) {
    getState<MyIncrementButtonState>().saySomething();

    return FloatingActionButton(
      onPressed: viewModel.incrementCounter,
      child: Text(viewModel.buttonText, style: const TextStyle(fontSize: 24)),
    );
  }
}

class MyIncrementButtonState extends ViewState<IncrementButtonViewModel> with MyMixin {}

class IncrementButtonViewModel extends ViewModel {
  late final isNumber = createProperty<bool>(false);
  String get buttonText => isNumber.value ? '+1' : '+a';
  void incrementCounter() {
    isNumber.value ? get<CounterPageViewModel>().incrementNumber() : get<CounterPageViewModel>().incrementLetter();
    isNumber.value = !isNumber.value;
  }
}

// Rich, mixin test below
mixin MyMixin {
  void saySomething() => debugPrint('Hello from MyMixin');
}
*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class MyClass {
  late final count = Property<int>(0);
}

class MyModel extends Model {
  int count = 0;
  void incrementCount() {
    count++;
    notifyListeners();
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Bilocators(
      delegates: [
        BilocatorDelegate<MyClass>(builder: () => MyClass()),
        BilocatorDelegate<MyModel>(builder: () => MyModel()),
      ],
      child: Bilocator(
        location: Location.tree,
        builder: () => MyModel(),
        child: Scaffold(
          appBar: AppBar(title: const Text('Counter example')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Parameter, Get, Listen, Mixin, Inherited, Context, Future, Stream'),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: BuildViewWidget()),
                    Expanded(child: PropertyWidget()),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: GetListenToWidget()),
                    Expanded(child: ModelWidget()),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: ContextOfWidget()),
                    Expanded(child: PropertyWidget()),
                  ],
                ),
                const Spacer(),
                Row(
                  children: const [
                    Expanded(child: FutureWidget()),
                    Expanded(child: StreamWidget()),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }
}

/// Demonstrates the [Property] class
class PropertyWidget extends View<PropertyWidgetViewModel> {
  PropertyWidget({super.key}) : super(builder: () => PropertyWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Property'),
        Text(viewModel.count.value.toString()),
        const SizedBox(height: 10),
        _Fab(onPressed: () => viewModel.count.value++),
      ],
    );
  }
}

class PropertyWidgetViewModel extends ViewModel {
  // The three lines below are identical
  // late final count = ValueNotifier<int>(0)..addListener(buildView);
  // late final count = Property<int>(0)..addListener(buildView);
  late final count = createProperty<int>(0);
}

/// Demonstrates the [buildView] function.
class BuildViewWidget extends View<BuildViewWidgetViewModel> {
  BuildViewWidget({super.key}) : super(builder: () => BuildViewWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('buildView'),
        Text('${viewModel.count}'),
        const SizedBox(height: 10),
        _Fab(onPressed: viewModel.incrementCount),
      ],
    );
  }
}

class BuildViewWidgetViewModel extends ViewModel {
  int count = 0;
  incrementCount() {
    count++;
    buildView();
  }
}

/// Demonstrates [get] and [listenTo]
class GetListenToWidget extends ViewWithStatelessViewModel {
  GetListenToWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('get/listenTo'),
        Text('${listenTo(notifier: get<MyClass>().count).value}'),
        const SizedBox(height: 10),
        _Fab(onPressed: () {
          get<MyClass>().count.value++;
        }),
      ],
    );
  }
}

class ModelWidget extends ViewWithStatelessViewModel {
  ModelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Model'),
        Text('${listenTo<MyModel>().count}'),
        const SizedBox(height: 10),
        _Fab(onPressed: get<MyModel>().incrementCount),
      ],
    );
  }
}

class ContextOfWidget extends ViewWithStatelessViewModel {
  ContextOfWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Context.of'),
        Text('${context.of<MyModel>().count}'),
        const SizedBox(height: 10),
        _Fab(onPressed: () => get<MyModel>(context: context).incrementCount()),
      ],
    );
  }
}

Future<int> setNumberSlowly(int number) async => Future.delayed(const Duration(milliseconds: 500), () => number);

class FutureWidget extends StatefulWidget {
  const FutureWidget({Key? key}) : super(key: key);

  @override
  State<FutureWidget> createState() => _FutureWidgetState();
}

class _FutureWidgetState extends State<FutureWidget> {
  int count = 0;
  late final futureProperty = FutureProperty<int>(setNumberSlowly(count))..addListener(() => setState(() {}));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Future'),
        Text(futureProperty.hasData ? futureProperty.data.toString() : 'Loading...'),
        const SizedBox(height: 10),
        _Fab(onPressed: () => futureProperty.value = setNumberSlowly(++count)),
      ],
    );
  }
}

int streamCounter = 0;
Stream<int> addToSlowly(int increment) async* {
  int i = streamCounter;
  streamCounter += increment;
  await Future.delayed(const Duration(milliseconds: 500));
  for (; i <= streamCounter; i++) {
    await Future.delayed(const Duration(milliseconds: 200));
    yield i;
  }
}

class StreamWidget extends StatefulWidget {
  const StreamWidget({Key? key}) : super(key: key);

  @override
  State<StreamWidget> createState() => _StreamWidgetState();
}

class _StreamWidgetState extends State<StreamWidget> {
  late final streamProperty = StreamProperty<int>(addToSlowly(streamCounter))..addListener(() => setState(() {}));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Stream'),
        Text(streamProperty.hasData ? streamProperty.data.toString() : 'Loading...'),
        const SizedBox(height: 10),
        _Fab(onPressed: () {
          streamProperty.value = addToSlowly(5);
        }),
      ],
    );
  }
}

class FutureProperty<T extends Object?> extends ValueNotifier<Future<T>> {
  FutureProperty(super.value) {
    _getFuture(value);
  }

  void _getFuture(Future<T> future) async {
    _hasData = false;
    _data = await future;
    _hasData = true;
    notifyListeners();
  }

  @override
  set value(Future<T> newValue) {
    if (super.value != newValue) {
      super.value = newValue;
      _getFuture(value);
      notifyListeners();
    }
  }

  bool get hasData => _hasData;
  bool _hasData = false;
  late T _data;
  T get data {
    if (!_hasData) {
      throw Exception('FutureProperty.resolvedValue was called when the Future has not yet resolved.');
    }
    return _data;
  }
}

class StreamProperty<T extends Object?> extends ValueNotifier<Stream<T>> {
  StreamProperty(super.value) {
    _getStream(value);
  }

  @override
  set value(Stream<T> newValue) {
    if (super.value != newValue) {
      super.value = newValue;
      _getStream(value);
      notifyListeners();
    }
  }

  void _getStream(Stream<T> stream) async {
    _hasData = false;
    await for (final value in stream) {
      _data = value;
      _hasData = true;
      notifyListeners();
    }
  }

  bool get hasData => _hasData;
  bool _hasData = false;
  late T _data;
  T get data {
    if (!_hasData) {
      throw Exception('FutureProperty.resolvedValue was called when the Future has not yet resolved.');
    }
    return _data;
  }
}
