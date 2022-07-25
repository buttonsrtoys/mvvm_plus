import 'package:example/counter_page/counter_page.dart';
import 'package:example/services/color_notifier.dart';
import 'package:flutter/material.dart';
import 'package:registrar/registrar.dart';
import 'package:view/get_mvvm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final appTitle = 'example';

  @override
  Widget build(BuildContext context) {
    return Registrar<ColorNotifier>(
      builder: () => ColorNotifier(),
      child: MaterialApp(
        title: appTitle,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CounterPage(title: appTitle),
      ),
    );
  }
}
