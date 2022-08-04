import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:registrar/registrar.dart';

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

class IncrementButton extends View<IncrementButtonViewModel> {
  IncrementButton({
    required void Function() onIncrementNumber,
    required void Function() onIncrementLetter,
    super.key,
  }) : super(
            viewModelBuilder: () => IncrementButtonViewModel(
                  incrementNumber: onIncrementNumber,
                  incrementLetter: onIncrementLetter,
                ));

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: viewModel.incrementCounter,
      child: Text(viewModel.label, style: const TextStyle(fontSize: 24)),
    );
  }
}

enum FabLabel {
  number('+1'),
  letter('+a');

  const FabLabel(this.value);
  final String value;
  FabLabel get nextLabel => value == number.value ? letter : number;
}

class IncrementButtonViewModel extends ViewModel {
  IncrementButtonViewModel({
    required this.incrementNumber,
    required this.incrementLetter,
  });

  final void Function() incrementNumber;
  final void Function() incrementLetter;
  final _currentFabLabel = ValueNotifier<FabLabel>(FabLabel.number);

  @override
  void initState() {
    super.initState();
    _currentFabLabel.addListener(buildView);
  }

  void incrementCounter() {
    _currentFabLabel.value == FabLabel.number ? incrementNumber() : incrementLetter();
    _currentFabLabel.value = _currentFabLabel.value.nextLabel;
  }

  String get label => _currentFabLabel.value.value;
}

class CounterPage extends View<CounterPageViewModel> {
  CounterPage({
    required this.title,
    super.key,
  }) : super(
            viewModelBuilder: () => CounterPageViewModel(
                  register: true, // <- makes gettable by other widgets (overkill for this simple example)
                ));

  final String title;

  @override
  Widget build(BuildContext context) {
    final upperCaseColorNotifier = Registrar.get<ColorNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(viewModel.message),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  viewModel.letterCount.value,
                  style: TextStyle(fontSize: 64, color: upperCaseColorNotifier.color),
                ),
                Text(
                  viewModel.numberCounter.toString(),
                  style: TextStyle(fontSize: 64, color: viewModel.numberColor),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: IncrementButton(
        // Typically view models are referenced with the "viewModel" member, like this:
        onIncrementNumber: () => viewModel.incrementNumberCounter(),
        // Alternatively, view models can be registered and retrieved with "View.get" (see below). That is overkill for
        // this simple example as "viewModel" is available but, hey, we're demoing! :)
        onIncrementLetter: () => Registrar.get<CounterPageViewModel>().incrementLetterCounter(),
      ),
    );
  }
}

class CounterPageViewModel extends ViewModel {
  CounterPageViewModel({super.register, super.name});

  String message = '';
  Timer? _timer;
  late final StreamSubscription<Color> _streamSubscription;
  int _numberCounter = 0; // <- Demoing without ValueNotifier
  final letterCount = ValueNotifier<String>('a'); // <- Demoing with ValueNotifier

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
    _streamSubscription.cancel();
    if (_timer != null) {
      _timer!.cancel();
    }
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

class ColorService {
  static final currentColor = Stream<Color>.periodic(const Duration(seconds: 5), (int i) {
    return <Color>[Colors.red, Colors.green, Colors.blue][i % 3];
  });
}
