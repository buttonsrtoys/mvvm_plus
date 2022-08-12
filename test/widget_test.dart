import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

import 'unit_test.dart';

const _number = 42;
const _defaultString = 'Default';
const _updatedString = 'Hello';
const _viewModelName = 'ViewModel Name';

/// Test app for all widget tests
///
/// [listenToRegistrar] true to listen to [MyRegistrarNotifier]
/// [registerViewModel] true to register [MyTestWidgetViewModel]
/// [viewModelName] is option name of registered [MyTestWidgetViewModel]
Widget testApp({
  required bool listenToRegistrar,
  required bool registerViewModel,
  required String? viewModelName,
}) =>
    MaterialApp(
      home: Registrar(
        builder: () => MyRegistrarNotifier(),
        child: MyTestWidget(
          listenToRegistrar: listenToRegistrar,
          registerViewModel: registerViewModel,
          viewModelName: viewModelName,
        ),
      ),
    );

/// The [Registrar] service
class MyRegistrarNotifier extends ChangeNotifier {
  int number = _number;

  void incrementNumber() {
    number++;
    notifyListeners();
  }
}

/// The [View]
class MyTestWidget extends View<MyTestWidgetViewModel> {
  MyTestWidget({
    super.key,
    required bool listenToRegistrar,
    required bool registerViewModel,
    required String? viewModelName,
  }) : super(
            viewModelBuilder: () => MyTestWidgetViewModel(
                  listenToRegistrar: listenToRegistrar,
                  register: registerViewModel,
                  name: viewModelName,
                ));

  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        Text('${viewModel.number}'),
        Text(viewModel.myStringProperty.value),
      ],
    );
  }
}

/// The [ViewModel]
class MyTestWidgetViewModel extends ViewModel {
  MyTestWidgetViewModel({
    this.listenToRegistrar = false,
    super.register,
    super.name,
  });

  final bool listenToRegistrar;
  late final MyRegistrarNotifier myRegistrarNotifier;
  late final myStringProperty = Property<String>(_defaultString)..addListener(buildView);

  @override
  void initState() {
    super.initState();
    if (listenToRegistrar) {
      // listen twice so can later test that only one listener added
      listenTo<MyRegistrarNotifier>(); // 1st listen
      myRegistrarNotifier = listenTo<MyRegistrarNotifier>(); // 2nd listen
    } else {
      myRegistrarNotifier = get<MyRegistrarNotifier>();
    }
  }

  int get number => myRegistrarNotifier.number;
}

/// Test app for widget subclassed from [ViewWithStatelessViewModel]
Widget statelessTestApp({required bool listen}) => MaterialApp(
      home: Registrar(
        builder: () => MyRegistrarNotifier(),
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
    return listen ? Text('${listenTo<MyRegistrarNotifier>().number}') : Text('${get<MyRegistrarNotifier>().number}');
  }
}

void main() {
  setUp(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyRegistrarNotifier>(), false);
    expect(Registrar.isRegistered<MyTestWidgetViewModel>(), false);
  });

  tearDown(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyRegistrarNotifier>(), false);
    expect(Registrar.isRegistered<MyTestWidgetViewModel>(), false);
  });

  group('MyTestWidget', () {
    testWidgets('not listening to Registrar, not registered, and not named ViewModel does not update value',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: false, registerViewModel: false, viewModelName: null));

      expect(Registrar.isRegistered<MyRegistrarNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegistrarNotifier>().incrementNumber();
      await tester.pump();

      // expect does not increment b/c not listening
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to Registrar but not registered ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: true, registerViewModel: false, viewModelName: null));

      expect(Registrar.isRegistered<MyRegistrarNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegistrarNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening to Registrar and registered ViewModel  but not named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: true, registerViewModel: true, viewModelName: null));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyTestWidgetViewModel>(), true);
      expect(Registrar.get<MyTestWidgetViewModel>().number, _number);

      Registrar.get<MyRegistrarNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);

      Registrar.get<MyTestWidgetViewModel>().myStringProperty.value = _updatedString;
      await tester.pump();

      expect(find.text(_updatedString), findsOneWidget);
    });

    testWidgets('listening to Registrar, registered and named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: true, registerViewModel: true, viewModelName: _viewModelName));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyTestWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyTestWidgetViewModel>(name: _viewModelName), true);
      expect(Registrar.get<MyTestWidgetViewModel>(name: _viewModelName).number, _number);

      Registrar.get<MyRegistrarNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });

  group('MyStatelessViewWidget', () {
    testWidgets('non-listening stateless View does not update', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: false));

      expect(Registrar.isRegistered<MyRegistrarNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegistrarNotifier>().incrementNumber();
      await tester.pump();

      // expect number did not increment (because not listening)
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening stateless View updates', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: true));

      expect(Registrar.isRegistered<MyRegistrarNotifier>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegistrarNotifier>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });
}
