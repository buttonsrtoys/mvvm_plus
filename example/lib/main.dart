import 'dart:async';

import 'package:bilocator/bilocator.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

void main() => runApp(myApp());

Widget myApp() => const MaterialApp(debugShowCheckedModeBanner: false, home: Home());

/// Counter model that extends [Model]. (Observers listen to class.)
class CounterModel extends Model {
  int count = 0;
  void incrementCount() {
    count++;
    notifyListeners();
  }
}

/// Counter model that does not extend [Model]. (Observers listen to member values.)
class Counter {
  late final count = Property<int>(0);
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    /// Add a class and a model to the global registry
    return Bilocators(
        key: const ValueKey('Bilocators'), // <- supports hot reloading
        delegates: [
          BilocatorDelegate<Counter>(builder: () => Counter()),
          BilocatorDelegate<CounterModel>(builder: () => CounterModel()),
        ],
        /// For demo purposes, also add a class and model to the widget tree.
        child: Bilocator(
            location: Location.tree,
            builder: () => CounterModel(),
            child: Bilocator(
              location: Location.tree,
              builder: () => Counter(),
              child: const _GridOfCounters(),
            )));
  }
}

/// Demonstrates [StatefulWidget] and [State] classes for comparison to [ViewWidget] and [ViewModel].
class StatefulAndStateWidget extends StatefulWidget {
  const StatefulAndStateWidget({super.key});

  @override
  State<StatefulAndStateWidget> createState() => _StatefulAndStateWidgetState();
}

class _StatefulAndStateWidgetState extends State<StatefulAndStateWidget> {
  int count = 0;
  incrementCount() {
    setState(() {
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('StatefulWidget/State'),
        Text('$count'),
        const SizedBox(height: 10),
        Fab(onPressed: incrementCount),
      ],
    );
  }
}

/// Demonstrates the [ViewWidget], [ViewModel] classes and the [buildView] function.
class MyViewWidget extends ViewWidget<ViewWidgetViewModel> {
  MyViewWidget({super.key}) : super(builder: () => ViewWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('ViewWidget/ViewModel'),
        Text('${viewModel.count}'),
        const SizedBox(height: 10),
        Fab(onPressed: viewModel.incrementCount),
      ],
    );
  }
}

class ViewWidgetViewModel extends ViewModel {
  int count = 0;
  incrementCount() {
    count++;
    buildView();
  }
}

/// Demonstrates the [buildView] function.
class PropertyWidget extends ViewWidget<PropertyWidgetViewModel> {
  PropertyWidget({super.key}) : super(builder: () => PropertyWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Property'),
        Text('${viewModel.count.value}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => viewModel.count.value++),
      ],
    );
  }
}

class PropertyWidgetViewModel extends ViewModel {
  /// The below lines are identical
  // late final count = ValueNotifier<int>(0)..addListener(buildView);
  // late final count = Property<int>(0)..addListener(buildView);
  late final count = createProperty<int>(0);
}

/// Demonstrates [get] and [listenTo] for a [Property]
class GetListenToWidget extends StatelessViewWidget {
  GetListenToWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('get/listenTo Property'),
        Text('${listenTo(notifier: get<Counter>().count).value}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => get<Counter>().count.value++),
      ],
    );
  }
}

/// Demonstrates [get] and [listenTo] for a [Model]
class ModelWidget extends StatelessViewWidget {
  ModelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('get/listenTo Model'),
        Text('${listenTo<CounterModel>().count}'),
        const SizedBox(height: 10),
        Fab(onPressed: get<CounterModel>().incrementCount),
      ],
    );
  }
}

/// Demonstrates exposing [ViewState] to use a mixin.
class MixinWidget extends ViewWidget<MixinWidgetViewModel> {
  MixinWidget({super.key}) : super(builder: () => MixinWidgetViewModel());

  /// To use a mix, we need to override [createState]. (Otherwise this override is not required.)
  @override
  MixinWidgetState createState() => MixinWidgetState();

  /// Use [getState] to access the mixin.
  late final color = getState<MixinWidgetState>().color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Mixin'),
        Text('${viewModel.count.value}', style: TextStyle(color: getState<MixinWidgetState>().color)),
        const SizedBox(height: 10),
        Fab(onPressed: () => viewModel.count.value++),
      ],
    );
  }
}

class MixinWidgetViewModel extends ViewModel {
  late final count = createProperty<int>(0);
}

/// Sample mixin
mixin ColorMixin {
  final color = Colors.red;
}

/// Extend [ViewState] with mixin.
class MixinWidgetState extends ViewState<MixinWidgetViewModel> with ColorMixin {}

/// Demonstrates [BuildContext.of] extension
class ContextOfWidget extends StatelessViewWidget {
  ContextOfWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Context.of'),
        Text('${context.of<CounterModel>().count}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => context.of<CounterModel>().incrementCount()),
      ],
    );
  }
}

/// Demonstrates [get] and [listenTo] with [BuildContext]
class GetListenToContextWidget extends StatelessViewWidget {
  GetListenToContextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final countProperty = get<Counter>(context: context).count;
    return Column(
      children: [
        const Text('get/listenTo(context)'),
        Text('${listenTo(notifier: countProperty).value}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => get<Counter>(context: context).count.value++),
      ],
    );
  }
}

/// Demonstrates [FutureProperty] by using a future to delay a counter.
Future<int> setNumberSlowly(int number) async => Future.delayed(const Duration(milliseconds: 350), () => number);

class FutureWidget extends ViewWidget<FutureWidgetViewModel> {
  FutureWidget({super.key}) : super(builder: () => FutureWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Future'),
        Text(viewModel.futureCounter.hasData ? '${viewModel.futureCounter.data}' : 'Loading...'),
        const SizedBox(height: 10),
        Fab(onPressed: () => viewModel.futureCounter.value = setNumberSlowly(++viewModel.count)),
      ],
    );
  }
}

class FutureWidgetViewModel extends ViewModel {
  int count = 0;
  /// The below lines are identical
  // late final futureCounter = FutureProperty<int>(setNumberSlowly(count))..addListener(buildView);
  late final futureCounter = createFutureProperty<int>(setNumberSlowly(count));
}

/// Demonstrates [StreamProperty] by streaming numbers with a delay.
int streamCounter = 0;
Stream<int> addFiveSlowly() async* {
  int i = streamCounter;
  streamCounter += 5;
  for (; i <= streamCounter; i++) {
    await Future.delayed(const Duration(milliseconds: 350));
    yield i;
  }
}

class StreamWidget extends ViewWidget<StreamWidgetViewModel> {
  StreamWidget({super.key})
      : super(
          /// Below line adds the ViewModel to the Registry
          location: Location.registry,
          builder: () => StreamWidgetViewModel(),
        );

  @override
  Widget build(BuildContext context) {
    final streamCounter = get<StreamWidgetViewModel>().streamCounter;
    return Column(
      children: [
        const Text('Stream'),
        Text(streamCounter.hasData ? '${streamCounter.data}' : 'Loading...'),
        const SizedBox(height: 10),
        Fab(onPressed: () => streamCounter.value = addFiveSlowly()),
      ],
    );
  }
}

class StreamWidgetViewModel extends ViewModel {
  /// The below lines are identical
  // late final streamCounter = StreamProperty<int>(addToSlowly(streamCounter))..addListener(buildView);
  late final streamCounter = createStreamProperty<int>(Stream.value(0));
}

/// Grid of counters.
class _GridOfCounters extends StatelessWidget {
  const _GridOfCounters();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Spacer(),
      Row(
        children: [
          const Expanded(child: StatefulAndStateWidget()),
          Expanded(child: MyViewWidget()),
        ],
      ),
      const Spacer(),
      Row(
        children: [
          Expanded(child: PropertyWidget()),
          Expanded(child: GetListenToWidget()),
        ],
      ),
      const Spacer(),
      Row(
        children: [
          Expanded(child: ModelWidget()),
          Expanded(child: MixinWidget()),
        ],
      ),
      const Spacer(),
      Row(
        children: [
          Expanded(child: ContextOfWidget()),
          Expanded(child: GetListenToContextWidget()),
        ],
      ),
      const Spacer(),
      Row(
        children: [
          Expanded(child: FutureWidget()),
          Expanded(child: StreamWidget()),
        ],
      ),
      const Spacer(),
    ])));
  }
}

/// Counter floating action button.
class Fab extends StatelessWidget {
  const Fab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(backgroundColor: Colors.blue, shape: const CircleBorder()),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
