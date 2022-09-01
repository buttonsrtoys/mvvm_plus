import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:registrar/registrar.dart';

void main() => runApp(Registrar<ColorService>( // <---- Registers a single service
    builder: () => ColorService(seconds: 1),
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Registrar<ColorService>(
          builder: () => ColorService(seconds: 3),
          inherited: true, // <------------------------ Registers an inherited model
          child: Page(),
        ))));

class IncrementButton extends View<IncrementButtonViewModel> {
  IncrementButton({super.key}) : super(viewModelBuilder: () => IncrementButtonViewModel());

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: viewModel.incrementCounter, // <---- "viewModel" gets ViewModel instance
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
              // Pass context to listen to color changes of the inherited model:
              style: TextStyle(fontSize: 64, color: listenTo<ColorService>(context: context).color)),
          Text(viewModel.numberCounter.toString(),
              // No context to listen to color changes of the registered service:
              style: TextStyle(fontSize: 64, color: listenTo<ColorService>().color)),
        ])
      ])),
      floatingActionButton: IncrementButton(),
    );
  }
}

class PageViewModel extends ViewModel {
  PageViewModel({super.register, super.name});

  late final letterCount = ValueNotifier<String>('a')..addListener(buildView); // <---- Use Properties
  int numberCounter = 0; // <---------------------------------------------------------- Fields are fine, too!

  void incrementNumberCounter() {
    numberCounter = numberCounter == 9 ? 0 : numberCounter + 1;
    buildView();
  }

  void incrementLetterCounter() =>
      letterCount.value = letterCount.value == 'z' ? 'a' : String.fromCharCode(letterCount.value.codeUnits[0] + 1);
}

class ColorService extends Model {
  ColorService({required int seconds}) : _duration = Duration(seconds: seconds) {
    colorStream.listen((newColor) {
      color = newColor;
      notifyListeners();
    });
  }

  final Duration _duration;
  Color color = Colors.black;
  late final colorStream = Stream<Color>.periodic(_duration, (int i) => [Colors.red, Colors.green, Colors.blue][i % 3]);
}
