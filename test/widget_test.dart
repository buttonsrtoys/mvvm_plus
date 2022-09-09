import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

const _number = 42;
const _floatDefault = 3.14159;
const _floatUpdated = 42.42;
const _stringDefault = 'Default';
const _stringUpdated = 'Updated';
const _registeredStringDefault = 'Registered Default';
const _registeredStringUpdated = 'Registered Updated';
const _namedStringDefault = 'Named Default';
const _namedStringUpdated = 'Named Updated';
const _viewModelName = 'ViewModel Name';
const _inheritedStringDefault = 'Inherited Default';
const _inheritedStringUpdated = 'Inherited Updated';
const _updateButtonText = 'Update';

/// Test app for all widget tests
///
/// [listenToRegistrar] true to listen to [My]
/// [registerViewModel] true to register [MyTestWidgetViewModel]
/// [viewModelName] is option name of registered [MyTestWidgetViewModel]
/// Rich, add [inherited] and [register] as params and add tests for the new register feature.
Widget testApp({
  required bool listenToRegistrar,
  required bool registerViewModel,
  required String? viewModelName,
}) =>
    MaterialApp(
      home: Registrar(
        builder: () => MyRegisteredModel(),
        child: Registrar(
          builder: () => MyInheritedModel(),
          inherited: true,
          child: MyTestWidget(
            listenToRegistrar: listenToRegistrar,
            registerViewModel: registerViewModel,
            viewModelName: viewModelName,
          ),
        ),
      ),
    );

class MyRegisteredModel extends Model {
  int number = _number;

  final myFloatProperty = Property<double>(_floatDefault);

  void incrementNumber() {
    number++;
    notifyListeners();
  }
}

class MyInheritedModel extends Model {
  late final text = Property<String>(_inheritedStringDefault)..addListener(notifyListeners);
}

/// The [View]
class MyTestWidget extends View<MyTestWidgetViewModel> {
  MyTestWidget({
    super.key,
    required bool listenToRegistrar,
    required bool registerViewModel,
    required String? viewModelName,
  }) : super(
            register: registerViewModel,
            name: viewModelName,
            builder: () => MyTestWidgetViewModel(
                  listenToRegistrar: listenToRegistrar,
                ));

  @override
  Widget build(BuildContext _) {
    final float = listenTo<Property<double>>(notifier: get<MyRegisteredModel>().myFloatProperty).value;
    return Column(
      children: [
        OutlinedButton(onPressed: viewModel.update, child: const Text(_updateButtonText)),
        Text('${viewModel.number}'),
        Text(viewModel.myStringProperty.value),
        Text(viewModel.myRegisteredStringProperty.value),
        Text(viewModel.myNamedStringProperty.value),
        Text(viewModel.inheritedText),
        Text('$float'),
      ],
    );
  }
}

/// The [ViewModel]
class MyTestWidgetViewModel extends ViewModel {
  MyTestWidgetViewModel({
    this.listenToRegistrar = false,
  });

  final bool listenToRegistrar;
  late final MyRegisteredModel myModel;
  late final myStringProperty = Property<String>(_stringDefault)..addListener(buildView);
  late final myRegisteredStringProperty = Property<String>(_registeredStringDefault)..addListener(buildView);
  late final myNamedStringProperty = Property<String>(_namedStringDefault)..addListener(buildView);

  String get inheritedText => listenTo<MyInheritedModel>(context: context).text.value;

  void update() {
    get<MyInheritedModel>(context: context).text.value = _inheritedStringUpdated;
  }

  @override
  void initState() {
    super.initState();
    if (listenToRegistrar) {
      // listen twice so can later test that only one listener added
      listenTo<MyRegisteredModel>(); // 1st listen
      myModel = listenTo<MyRegisteredModel>(); // 2nd listen
    } else {
      myModel = get<MyRegisteredModel>();
    }
  }

  int get number => myModel.number;
}

/// Test app for widget subclassed from [ViewWithStatelessViewModel]
Widget statelessTestApp({required bool listen}) => MaterialApp(
      home: Registrar(
        builder: () => MyRegisteredModel(),
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
  Widget build(BuildContext _) {
    return listen ? Text('${listenTo<MyRegisteredModel>().number}') : Text('${get<MyRegisteredModel>().number}');
  }
}

void main() {
  setUp(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyRegisteredModel>(), false);
    expect(Registrar.isRegistered<MyTestWidgetViewModel>(), false);
  });

  tearDown(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyRegisteredModel>(), false);
    expect(Registrar.isRegistered<MyTestWidgetViewModel>(), false);
  });

  group('MyTestWidget', () {
    testWidgets('not listening to Registrar, not registered, and not named ViewModel does not update value',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: false, registerViewModel: false, viewModelName: null));

      expect(Registrar.isRegistered<MyRegisteredModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredModel>().incrementNumber();
      await tester.pump();

      // expect does not increment b/c not listening
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to Registrar but not registered ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: true, registerViewModel: false, viewModelName: null));

      expect(Registrar.isRegistered<MyRegisteredModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredModel>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening to Registrar and registered ViewModel  but not named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: true, registerViewModel: true, viewModelName: null));

      expect(Registrar.isRegistered<MyTestWidgetViewModel>(), true);
      expect(Registrar.get<MyTestWidgetViewModel>().number, _number);

      // expect default values
      expect(find.text('$_number'), findsOneWidget);
      expect(find.text(_stringDefault), findsOneWidget);
      expect(find.text(_registeredStringDefault), findsOneWidget);
      expect(find.text(_namedStringDefault), findsOneWidget);
      expect(find.text('$_floatDefault'), findsOneWidget);

      // change values
      Registrar.get<MyRegisteredModel>().incrementNumber();
      Registrar.get<MyTestWidgetViewModel>().myStringProperty.value = _stringUpdated;
      Registrar.get<MyTestWidgetViewModel>().myRegisteredStringProperty.value = _registeredStringUpdated;
      Registrar.get<MyTestWidgetViewModel>().myNamedStringProperty.value = _namedStringUpdated;
      Registrar.get<MyRegisteredModel>().myFloatProperty.value = _floatUpdated;

      await tester.pump();

      // expect updated values
      expect(find.text('${_number + 1}'), findsOneWidget);
      expect(find.text(_stringUpdated), findsOneWidget);
      expect(find.text(_registeredStringUpdated), findsOneWidget);
      expect(find.text(_namedStringUpdated), findsOneWidget);
      expect(find.text('$_floatUpdated'), findsOneWidget);
    });

    testWidgets('listening to Registrar, registered and named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(listenToRegistrar: true, registerViewModel: true, viewModelName: _viewModelName));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyTestWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyTestWidgetViewModel>(name: _viewModelName), true);
      expect(Registrar.get<MyTestWidgetViewModel>(name: _viewModelName).number, _number);

      Registrar.get<MyRegisteredModel>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });

  group('Inherited model', () {
    testWidgets('listening to inherited model', (WidgetTester tester) async {
      await tester
          .pumpWidget(testApp(listenToRegistrar: false, registerViewModel: true, viewModelName: _viewModelName));

      expect(Registrar.isRegistered<MyInheritedModel>(), false);
      expect(find.text(_inheritedStringDefault), findsOneWidget);

      await tester.tap(find.text(_updateButtonText));
      await tester.pump();

      expect(find.text(_inheritedStringUpdated), findsOneWidget);
    });
  });

  group('MyStatelessViewWidget', () {
    testWidgets('non-listening stateless View does not update', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: false));

      expect(Registrar.isRegistered<MyRegisteredModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredModel>().incrementNumber();
      await tester.pump();

      // expect number did not increment (because not listening)
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening stateless View updates', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: true));

      expect(Registrar.isRegistered<MyRegisteredModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredModel>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });
}
