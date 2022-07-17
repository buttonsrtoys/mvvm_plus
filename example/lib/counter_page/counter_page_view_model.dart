import 'dart:async';
import 'dart:ui';

import 'package:example/services/color_service.dart';
import 'package:example/services/letter_color_notifier.dart';
import 'package:view/view.dart';

class CounterPageViewModel extends ViewModel {
  @override
  void initState() {
    // give the services the color listeners
    listenTo<LetterColorNotifier>(listener: letterColorChanged);
    _streamSubscription = ColorService.currentColor.listen(setNumberColor);
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  late final StreamSubscription<Color> _streamSubscription;
  Color _numberColor = const Color.fromRGBO(0, 0, 0, 1.0);
  Color get numberColor => _numberColor;
  Timer? _timer;

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

  String message = '';

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
