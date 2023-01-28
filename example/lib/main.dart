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
          child: Scaffold(
            appBar: AppBar(title: const Text('Counter example')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  MixinWidget(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Fab extends StatelessWidget {
  const Fab({
    super.key,
    required this.onPressed,
  });

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
        Fab(onPressed: () => viewModel.count.value++),
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
Future<int> setNumberSlowly(int number) async => Future.delayed(const Duration(milliseconds: 500), () => number);

class FutureWidget extends View<FutureWidgetViewModel> {
  FutureWidget({super.key}) : super(builder: () => FutureWidgetViewModel());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Future'),
        Text(viewModel.futureProperty.hasData ? viewModel.futureProperty.data.toString() : 'Loading...'),
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
  await Future.delayed(const Duration(milliseconds: 500));
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
        Text(viewModel.streamProperty.hasData ? viewModel.streamProperty.data.toString() : 'Loading...'),
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
  final double factor = 2;
}

class MixinWidgetState extends ViewState<MixinWidgetViewModel> with MyMixin {}

class MixinWidgetViewModel extends ViewModel {
  late final count = createProperty<int>(0);
}
