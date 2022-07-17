import 'package:example/counter_page/counter_page.dart';
import 'package:example/services/color_notifier.dart';
import 'package:flutter/material.dart';
import 'package:view/view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final appTitle = 'example';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierRegistrar<ColorNotifier>(
      changeNotifierBuilder: () => ColorNotifier(),
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
