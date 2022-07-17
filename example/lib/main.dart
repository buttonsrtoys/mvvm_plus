import 'package:example/counter_page/counter_page.dart';
import 'package:example/services/letter_color_notifier.dart';
import 'package:flutter/material.dart';
import 'package:get_mvvm/view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final appTitle = 'example';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierRegistrar<LetterColorNotifier>(
      changeNotifierBuilder: () => LetterColorNotifier(),
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
