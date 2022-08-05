import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

import 'unit_test.dart';

const _number = 42;
const _viewModelName = 'ViewModel Name';

/// Test app for all widget tests
///
/// [listen] true to listen to [MyNotifier]
/// [register] true to register [MyWidgetViewModel]
/// [name] is option name of registered [MyWidgetViewModel]
Widget testApp({
  required bool listen,
  required bool register,
  required String? name,
}) =>
    MaterialApp(
      home: Registrar(
        builder: () => MyNotifier(),
        child: MyWidget(
          listen: listen,
          register: register,
          name: name,
        ),
      ),
    );

/// The [Registrar] service
class MyNotifier extends ChangeNotifier {
  final number = _number;
}

/// The [View]
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
      ],
    );
  }
}

/// The [ViewModel]
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
      listenTo<MyNotifier>(); // 1st listen
      myNotifier = listenTo<MyNotifier>(); // 2nd listen
    }
  }

  int get number => myNotifier.number;
}

void main() {
  setUp(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyNotifier>(), false);
    expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
  });

  tearDown(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyNotifier>(), false);
    expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
  });

  group('MyWidget', () {
    testWidgets('not registered', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listen: true, register: false, name: null));

      expect(Registrar.isRegistered<MyNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('register, not named', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listen: true, register: true, name: null));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), true);
      expect(Registrar.get<MyWidgetViewModel>().number, _number);
    });

    testWidgets('register, named', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listen: true, register: true, name: _viewModelName));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: _viewModelName), true);
      expect(Registrar.get<MyWidgetViewModel>(name: _viewModelName).number, _number);
    });
  });
}
