import 'dart:async';

import 'package:example/services/color_service.dart';
import 'package:example/services/color_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

class CounterPageViewModel extends ViewModel {
  CounterPageViewModel({super.register, super.name});

  String message = '';
  Timer? _timer;
  late final StreamSubscription<Color> _streamSubscription;
  int _numberCounter = 0;                                   // <- Demoing without ValueNotifier
  final letterCount = ValueNotifier<String>('a');           // <- Demoing with ValueNotifier

  @override
  void initState() {
    super.initState();
    // listen to the letter color ChangeNotifier
    listenTo<ColorNotifier>(listener: letterColorChanged);
    // listen to the number color stream
    _streamSubscription = ColorService.currentColor.listen(setNumberColor);
    letterCount.addListener(buildView);
  }

  @override
  void dispose() {
    // cancel listener to the number color stream
    _streamSubscription = ColorService.currentColor.listen(setNumberColor);
    _streamSubscription.cancel();
    super.dispose();
  }

  Color _numberColor = const Color.fromRGBO(0, 0, 0, 1.0);
  Color get numberColor => _numberColor;
  void setNumberColor(Color color) {
    _setMessage('Number color changed!');
    _numberColor = color;
    buildView();
  }

  void letterColorChanged() {
    _setMessage('Letter color changed!');
    buildView();
  }

  void _setMessage(String newMessage) {
    if (_timer != null) {
      _timer!.cancel();
    }
    message = message == '' ? newMessage : '$message $newMessage';
    _timer = Timer(const Duration(seconds: 2), () {
      message = '';
      buildView();
    });
    buildView();
  }

  int get numberCounter => _numberCounter;
  void incrementNumberCounter() {
    _numberCounter = _numberCounter == 9 ? 0 : _numberCounter + 1;
    buildView();
  }

  void incrementLetterCounter() {
    letterCount.value = letterCount.value == 'z' ? 'a' : String.fromCharCode(letterCount.value.codeUnits[0] + 1);
  }
}
