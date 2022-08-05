import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

import 'unit_test.dart';

const _number = 42;
const _listening = 'Listening';
const _notListening = 'Not Listening';
const _registered = 'Registered';
const _notRegistered = 'Not Registered';
const _viewModelName = 'ViewModel Name';
const _named = 'Named';
const _notNamed = 'Not Named';

Widget testApp({
  required bool listen,
  required bool register,
  required String? name,
}) =>
    MaterialApp(
      home: MyWidget(
        listen: listen,
        register: register,
        name: name,
      ),
    );

class MyNotifier extends ChangeNotifier {
  final number = _number;
}

class MyWidget extends View<MyWidgetViewModel> {
  MyWidget({
    super.key,
    required bool listen,
    required bool register,
    required String? name,
  }) : super(
            viewModelBuilder: () => MyWidgetViewModel(
                  listen: listen,
                  register: register,
                  name: name,
                ));

  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        Text('${viewModel.number}'),
        Text(viewModel.listeningStatus),
        Text(viewModel.registerStatus),
        Text(viewModel.namedStatus),
      ],
    );
  }
}

class MyWidgetViewModel extends ViewModel {
  MyWidgetViewModel({
    this.listen = false,
    super.register,
    super.name,
  });

  final bool listen;
  late final MyNotifier myNotifier;

  @override
  void initState() {
    super.initState();
    if (listen) {
      // listen twice so can later test that only one listener added
      listenTo<MyNotifier>();
      myNotifier = listenTo<MyNotifier>();
      // quick tests:
      assert(myNotifier.number == Registrar.get<MyNotifier>().number);
      assert(get<MyNotifier>().number == Registrar.get<MyNotifier>().number);
    }
  }

  int get number => myNotifier.number;

  String get listeningStatus => listen ? _listening : _notListening;

  String get registerStatus => register ? _registered : _notRegistered;

  String get namedStatus => name == null ? _notNamed : _named;
}

void main() {
  group('MyWidget', () {
    testWidgets('listening to builder', (WidgetTester tester) async {
      expect(Registrar.isRegistered<MyNotifier>(), false);
      Registrar.register<MyNotifier>(builder: () => MyNotifier());
      expect(Registrar.isRegistered<MyNotifier>(), true);

      await tester.pumpWidget(testApp(listen: true, register: false, name: null));

      expect(find.text('$_number'), findsOneWidget);
      expect(find.text(_listening), findsOneWidget);
      expect(find.text(_notRegistered), findsOneWidget);
      expect(find.text(_notNamed), findsOneWidget);

      Registrar.unregister<MyNotifier>();
      expect(Registrar.isRegistered<MyNotifier>(), false);
      expect(() => Registrar.get<MyNotifier>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyNotifier>(), throwsA(isA<Exception>()));

      final isRegistered = Registrar.isRegistered<MyWidgetViewModel>();
      expect(isRegistered, false);
    });

    testWidgets('register, not named', (WidgetTester tester) async {
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyNotifier>(), false);
      Registrar.register<MyNotifier>(builder: () => MyNotifier());
      expect(Registrar.isRegistered<MyNotifier>(), true);

      await tester.pumpWidget(testApp(listen: true, register: true, name: null));

      expect(find.text('$_number'), findsOneWidget);
      expect(find.text(_listening), findsOneWidget);
      expect(find.text(_registered), findsOneWidget);
      expect(find.text(_notNamed), findsOneWidget);

      Registrar.unregister<MyNotifier>();
      expect(Registrar.isRegistered<MyNotifier>(), false);
      expect(() => Registrar.get<MyNotifier>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyNotifier>(), throwsA(isA<Exception>()));

      expect(Registrar.isRegistered<MyWidgetViewModel>(), true);
    });

    testWidgets('register, named', (WidgetTester tester) async {
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: _viewModelName), false);
      expect(Registrar.isRegistered<MyNotifier>(), false);
      Registrar.register<MyNotifier>(builder: () => MyNotifier());
      expect(Registrar.isRegistered<MyNotifier>(), true);

      await tester.pumpWidget(testApp(listen: true, register: true, name: _viewModelName));

      expect(find.text('$_number'), findsOneWidget);
      expect(find.text(_listening), findsOneWidget);
      expect(find.text(_registered), findsOneWidget);
      expect(find.text(_named), findsOneWidget);

      Registrar.unregister<MyNotifier>();
      expect(Registrar.isRegistered<MyNotifier>(), false);
      expect(() => Registrar.get<MyNotifier>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyNotifier>(), throwsA(isA<Exception>()));

      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: _viewModelName), true);
    });
  });
}
