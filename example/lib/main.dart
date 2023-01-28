import 'dart:async';

import 'package:bilocator/bilocator.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

void main() => runApp(myApp());

Widget myApp() => const MaterialApp(debugShowCheckedModeBanner: false, home: Home());

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
        key: const ValueKey('Bilocators'), // <- Use a consistent key to support hot reloading
        delegates: [
          BilocatorDelegate<MyClass>(builder: () => MyClass()),
          BilocatorDelegate<MyModel>(builder: () => MyModel()),
        ],
        child: Bilocator(
            location: Location.tree,
            builder: () => MyModel(),
            child: Bilocator(
              location: Location.tree,
              builder: () => MyClass(),
              child: const _GridOfCounters(),
            )));
  }
}

/// Demonstrates [StatefulWidget] and [State] classes for comparison to [View] and [ViewModel].
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

/// Demonstrates the [View], [ViewModel] classes and the [buildView] function.
class BuildViewWidget extends View<BuildViewWidgetViewModel> {
  BuildViewWidget({super.key}) : super(builder: () => BuildViewWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('buildView'),
        Text('${viewModel.count}'),
        const SizedBox(height: 10),
        Fab(onPressed: viewModel.incrementCount),
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

/// Demonstrates the [buildView] function.
class ViewAndViewModelWidget extends View<PropertyWidgetViewModel> {
  ViewAndViewModelWidget({super.key}) : super(builder: () => PropertyWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('View/ViewModel'),
        Text('${viewModel.count.value}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => viewModel.count.value++),
      ],
    );
  }
}

class PropertyWidgetViewModel extends ViewModel {
  late final count = createProperty<int>(0);
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
        Fab(onPressed: () {
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
        Fab(onPressed: get<MyModel>().incrementCount),
      ],
    );
  }
}

/// Demonstrates [BuildContext.of] extension
class ContextOfWidget extends ViewWithStatelessViewModel {
  ContextOfWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Context.of'),
        Text('${context.of<MyModel>().count}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => context.of<MyModel>().incrementCount()),
      ],
    );
  }
}

/// Demonstrates [get] and [listenTo] with [BuildContext]
class GetListenToContextWidget extends ViewWithStatelessViewModel {
  GetListenToContextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final countProperty = get<MyClass>(context: context).count;
    return Column(
      children: [
        const Text('get/listenTo(context)'),
        Text('${listenTo(notifier: countProperty).value}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => get<MyClass>(context: context).count.value++),
      ],
    );
  }
}

/// Demonstrates [FutureProperty] by using a future to delay a counter.
Future<int> setNumberSlowly(int number) async => Future.delayed(const Duration(milliseconds: 200), () => number);

class FutureWidget extends View<FutureWidgetViewModel> {
  FutureWidget({super.key}) : super(builder: () => FutureWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Future'),
        Text(viewModel.futureProperty.hasData ? '${viewModel.futureProperty.data}' : 'Loading...'),
        const SizedBox(height: 10),
        Fab(onPressed: () => viewModel.futureProperty.value = setNumberSlowly(++viewModel.count)),
      ],
    );
  }
}

class FutureWidgetViewModel extends ViewModel {
  int count = 0;
  late final futureProperty = FutureProperty<int>(setNumberSlowly(count))..addListener(buildView);
}

/// Demonstrates [StreamProperty] by streaming numbers with a delay.
int streamCounter = 0;
Stream<int> addToSlowly(int increment) async* {
  int i = streamCounter;
  streamCounter += increment;
  for (; i <= streamCounter; i++) {
    await Future.delayed(const Duration(milliseconds: 200));
    yield i;
  }
}

class StreamWidget extends View<StreamWidgetViewModel> {
  StreamWidget({super.key}) : super(builder: () => StreamWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Stream'),
        Text(viewModel.streamProperty.hasData ? '${viewModel.streamProperty.data}' : 'Loading...'),
        const SizedBox(height: 10),
        Fab(onPressed: () {
          viewModel.streamProperty.value = addToSlowly(5);
        }),
      ],
    );
  }
}

class StreamWidgetViewModel extends ViewModel {
  late final streamProperty = StreamProperty<int>(addToSlowly(streamCounter))..addListener(buildView);
}

/// Demonstrates exposing [ViewState] to use a mixin.
class MixinWidget extends View<MixinWidgetViewModel> {
  MixinWidget({super.key}) : super(builder: () => MixinWidgetViewModel());

  @override
  MixinWidgetState createState() => MixinWidgetState();

  late final factor = getState<MixinWidgetState>().factor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Mixin'),
        Text('${viewModel.count.value * getState<MixinWidgetState>().factor}'),
        const SizedBox(height: 10),
        Fab(onPressed: () => viewModel.count.value++),
      ],
    );
  }
}

mixin MyMixin {
  final int factor = 2;
}

class MixinWidgetState extends ViewState<MixinWidgetViewModel> with MyMixin {}

class MixinWidgetViewModel extends ViewModel {
  late final count = createProperty<int>(0);
}

/// Grid of counters.
class _GridOfCounters extends StatelessWidget {
  const _GridOfCounters();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Counter example')),
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(),
          Row(
            children: [
              const Expanded(child: StatefulAndStateWidget()),
              Expanded(child: ViewAndViewModelWidget()),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: BuildViewWidget()),
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
