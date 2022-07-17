import 'dart:async';

import 'package:flutter/material.dart';

class ColorService {
  static final currentColor = Stream<Color>.periodic(const Duration(seconds: 5), (int i) {
    return <Color>[Colors.red, Colors.green, Colors.blue][i % 3];
  });
}
