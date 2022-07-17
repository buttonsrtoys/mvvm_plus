import 'dart:async';

import 'package:flutter/material.dart';

class LetterColorNotifier extends ChangeNotifier {
  LetterColorNotifier() {
    Timer.periodic(const Duration(seconds: 9), (_) {
      color = <Color>[Colors.orange, Colors.purple, Colors.cyan][++_counter % 3];
      notifyListeners();
    });
  }

  int _counter = 0;
  Color color = Colors.black;
}
