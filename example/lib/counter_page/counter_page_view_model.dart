import 'dart:async';
import 'dart:ui';

import 'package:example/services/color_service.dart';
import 'package:example/services/color_notifier.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

class CounterPageViewModel extends ViewModel {
  CounterPageViewModel({super.register, super.name});

  String message = '';
  Timer? _timer;
  late final StreamSubscription<Color> _streamSubscription;

  @override
  void initState() {
    super.initState();
    // listen to the letter color ChangeNotifier
    listenTo<ColorNotifier>(listener: letterColorChanged);
    // listen to the number color stream
    _streamSubscription = ColorService.currentColor.listen(setNumberColor);
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
    notifyListeners();
  }

  void letterColorChanged() {
    _setMessage('Letter color changed!');
    notifyListeners();
  }

  void _setMessage(String newMessage) {
    if (_timer != null) {
      _timer!.cancel();
    }
    message = message == '' ? newMessage : '$message $newMessage';
    _timer = Timer(const Duration(seconds: 2), () {
      message = '';
      notifyListeners();
    });
    notifyListeners();
  }

  int _numberCounter = 0;
  int get numberCounter => _numberCounter;
  void incrementNumberCounter() {
    _numberCounter = _numberCounter == 9 ? 0 : _numberCounter + 1;
    notifyListeners();
  }

  String _letterCounter = 'a';
  String get lowercaseCounter => _letterCounter;
  void incrementLetterCounter() {
    _letterCounter = _letterCounter == 'z' ? 'a' : String.fromCharCode(_letterCounter.codeUnits[0] + 1);
    notifyListeners();
  }
}
