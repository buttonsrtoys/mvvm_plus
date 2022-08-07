import 'package:flutter/material.dart';
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
  int number = _number;

  void incrementNumber() {
    number++;
    notifyListeners();
  }
}

/// The [View]
class MyWidget extends View<MyWidgetViewModel> {
  MyWidget({
    super.key,
    required bool listen,
    required bool register,
    required String? name,
  }) : super(
      viewModelBuilder: () =>
          MyWidgetViewModel(
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
    } else {
      myNotifier = get<MyNotifier>();
    }
  }

  int get number => myNotifier.number;
}

/// Test app for widget subclassed from [ViewWithStatelessViewModel]
Widget statelessTestApp({required bool listen}) =>
    MaterialApp(
      home: Registrar(
        builder: () => MyNotifier(),
        child: MyStatelessView(listen: listen),
      ),
    );

/// The [Registrar] service
class MyStatelessView extends ViewWithStatelessViewModel {
  MyStatelessView({
    super.key,
    required this.listen,
  });

  final bool listen;

  @override
  Widget build(BuildContext context) {
    return listen ? Text('${listenTo<MyNotifier>().number}') : Text('${get<MyNotifier>().number}');
  }
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
    testWidgets('not listening, registered, or named ViewModel does not update value', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listen: false, register: false, name: null));

      expect(Registrar.isRegistered<MyNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyNotifier>().incrementNumber();
      await tester.pump();

      // expect does not increment b/c not listening
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening but not registered ViewModel shows correct values', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listen: true, register: false, name: null));

      expect(Registrar.isRegistered<MyNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening and registered but not named ViewModel shows correct values', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listen: true, register: true, name: null));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), true);
      expect(Registrar
          .get<MyWidgetViewModel>()
          .number, _number);

      Registrar.get<MyNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening, registered, and named ViewModel shows correct values', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listen: true, register: true, name: _viewModelName));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: _viewModelName), true);
      expect(Registrar
          .get<MyWidgetViewModel>(name: _viewModelName)
          .number, _number);

      Registrar.get<MyNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });

  group('MyStatelessViewWidget', () {
    testWidgets('non-listening stateless View does not update', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: false));

      expect(Registrar.isRegistered<MyNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyNotifier>().incrementNumber();
      await tester.pump();

      // expect number did not increment (because not listening)
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening stateless View updates', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: true));

      expect(Registrar.isRegistered<MyNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });
}
