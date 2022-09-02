import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:registrar/registrar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Registrar<ColorService>(
        builder: () => ColorService(milliSeconds: 1500),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Registrar<ColorService>(
              builder: () => ColorService(milliSeconds: 2250),
              inherited: true,
              child: Page(),
            )));
  }
}

class IncrementButton extends View<IncrementButtonViewModel> {
  IncrementButton({super.key}) : super(viewModelBuilder: () => IncrementButtonViewModel());

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: viewModel.incrementCounter,
      child: Text(viewModel.label, style: const TextStyle(fontSize: 24)),
    );
  }
}

class IncrementButtonViewModel extends ViewModel {
  bool isNumber = false;
  String get label => isNumber ? '+a' : '+1';
  void incrementCounter() {
    isNumber ? get<PageViewModel>().incrementLetterCounter() : get<PageViewModel>().incrementNumberCounter();
    isNumber = !isNumber;
    buildView();
  }
}

class Page extends View<PageViewModel> {
  Page({super.key}) : super(viewModelBuilder: () => PageViewModel(register: true));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(viewModel.letterCount.value,
              style: TextStyle(fontSize: 64, color: listenTo<ColorService>(context: context).color)),
          Text(viewModel.numberCounter.toString(),
              style: TextStyle(fontSize: 64, color: listenTo<ColorService>().color)),
        ])
      ])),
      floatingActionButton: IncrementButton(),
    );
  }
}

class PageViewModel extends ViewModel {
  PageViewModel({super.register, super.name});

  late final letterCount = ValueNotifier<String>('a')..addListener(buildView);
  int numberCounter = 0;

  void incrementNumberCounter() {
    numberCounter = numberCounter == 9 ? 0 : numberCounter + 1;
    buildView();
  }

  void incrementLetterCounter() =>
      letterCount.value = letterCount.value == 'z' ? 'a' : String.fromCharCode(letterCount.value.codeUnits[0] + 1);
}

class ColorService extends Model {
  ColorService({required int milliSeconds}) {
    _timer = Timer.periodic(Duration(milliseconds: milliSeconds), (_) {
      color = <Color>[Colors.red, Colors.black, Colors.blue, Colors.orange][++_counter % 4];
      notifyListeners();
    });
  }

  int _counter = 0;
  Color color = Colors.orange;
  late Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
