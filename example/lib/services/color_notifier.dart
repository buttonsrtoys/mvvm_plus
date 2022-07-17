import 'dart:async';

import 'package:flutter/material.dart';

class ColorNotifier extends ChangeNotifier {
  ColorNotifier() {
    _timer = Timer.periodic(const Duration(seconds: 9), (_) {
      color = <Color>[Colors.orange, Colors.purple, Colors.cyan][++_counter % 3];
      notifyListeners();
    });
  }

  late Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  int _counter = 0;
  Color color = Colors.black;
}
