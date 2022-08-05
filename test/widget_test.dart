import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

Widget testApp({required bool listening}) => MaterialApp(
      home: MyWidget(listening: listening),
    );

class MyNotifier extends ChangeNotifier {
  final number = 42;
}

class MyWidgetViewModel extends ViewModel {
  MyWidgetViewModel({this.listening = false});

  final bool listening;

  @override
  void initState() {
    super.initState();
    if (listening) {
      listenTo<MyNotifier>();
    }
  }

  int get number => get<MyNotifier>().number;
}

class MyWidget extends View<MyWidgetViewModel> {
  MyWidget({super.key, required bool listening})
      : super(
            viewModelBuilder: () => MyWidgetViewModel(
                  listening: listening,
                ));

  @override
  Widget build(BuildContext _) {
    return Text('${viewModel.number}');
  }
}

void main() {
  group('MyWidget', () {
    testWidgets('listening to builder', (WidgetTester tester) async {
      expect(Registrar.isRegistered<MyNotifier>(), false);
      Registrar.register<MyNotifier>(builder: () => MyNotifier());
      expect(Registrar.isRegistered<MyNotifier>(), true);

      await tester.pumpWidget(testApp(listening: true));

      expect(find.text('42'), findsOneWidget);

      Registrar.unregister<MyNotifier>();
      expect(Registrar.isRegistered<MyNotifier>(), false);
      expect(() => Registrar.get<MyNotifier>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyNotifier>(), throwsA(isA<Exception>()));
    });
  });
}
