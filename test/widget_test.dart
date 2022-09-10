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
const _updateMyInheritedServiceButtonText = 'Update MyInheritedService';
const _updateMyWidgetButtonText = 'Update MyWidget';

/// [listenToMyRegisteredService] true to listen to [My]
/// [myWidgetIsRegistered] true to register [MyWidgetViewModel]
/// [myWidgetIsInherited] true to make [MyWidgetViewModel] part of inheritedWidget.
/// [myWidgetRegisteredName] is option name of registered [MyWidgetViewModel]
Widget testApp({
  required bool listenToMyRegisteredService,
  required bool myWidgetIsInherited,
  required bool myWidgetIsRegistered,
  required String? myWidgetRegisteredName,
}) =>
    MaterialApp(
      home: Registrar(
        builder: () => MyRegisteredService(),
        child: Registrar(
          builder: () => MyInheritedService(),
          inherited: true,
          child: MyWidget(
            listenToRegisteredService: listenToMyRegisteredService,
            inherited: myWidgetIsInherited,
            register: myWidgetIsRegistered,
            name: myWidgetRegisteredName,
          ),
        ),
      ),
    );

class MyRegisteredService extends Model {
  int number = _number;

  final myFloatProperty = Property<double>(_floatDefault);

  void incrementNumber() {
    number++;
    notifyListeners();
  }
}

class MyInheritedService extends Model {
  late final text = Property<String>(_inheritedStringDefault)..addListener(notifyListeners);
}

/// The [View]
class MyWidget extends View<MyWidgetViewModel> {
  MyWidget({
    super.key,
    required bool listenToRegisteredService,
    required this.inherited,
    required this.register,
    this.name,
  }) : super(
            inherited: inherited,
            register: register,
            name: name,
            builder: () => MyWidgetViewModel(
                  listenToRegistrar: listenToRegisteredService,
                ));

  final bool inherited;
  final bool register;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final float = listenTo<Property<double>>(notifier: get<MyRegisteredService>().myFloatProperty).value;
    return Column(
      children: [
        /// Add button the tests can tap
        OutlinedButton(
            onPressed: () => viewModel.updateMyInheritedService(),
            child: const Text(_updateMyInheritedServiceButtonText)),
        /// Add button that isn't tapped, but confirms registered or inherited [MyWidgetViewModel] is gettable
        if (inherited || register) TextWidgetThatUsesGet(inherited: inherited, name: name),
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

/// Get text from inherited or registered [ViewModel]
class TextWidgetThatUsesGet extends ViewWithStatelessViewModel {
  TextWidgetThatUsesGet({super.key, required this.inherited, required this.name});

  final bool inherited;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Text(get<MyWidgetViewModel>(context: inherited ? context : null, name: name).untestedText);
  }
}

/// The [ViewModel]
class MyWidgetViewModel extends ViewModel {
  MyWidgetViewModel({
    this.listenToRegistrar = false,
  });

  final bool listenToRegistrar;
  late final MyRegisteredService myModel;
  late final myStringProperty = Property<String>(_stringDefault)..addListener(buildView);
  late final myRegisteredStringProperty = Property<String>(_registeredStringDefault)..addListener(buildView);
  late final myNamedStringProperty = Property<String>(_namedStringDefault)..addListener(buildView);

  /// Text for displaying but not testing with expects. Typically used to confirm [get] or [listenTo] did not throw.
  final untestedText = 'Blah';

  String get inheritedText => listenTo<MyInheritedService>(context: context).text.value;

  /// Method used to confirm [get] works.
  void unusedMethod() {}

  void updateMyInheritedService() {
    get<MyInheritedService>(context: context).text.value = _inheritedStringUpdated;
  }

  @override
  void initState() {
    super.initState();
    if (listenToRegistrar) {
      // listen twice so can later test that only one listener added
      listenTo<MyRegisteredService>(); // 1st listen
      myModel = listenTo<MyRegisteredService>(); // 2nd listen
    } else {
      myModel = get<MyRegisteredService>();
    }
  }

  int get number => myModel.number;
}

/// Test app for widget subclassed from [ViewWithStatelessViewModel]
Widget statelessTestApp({required bool listen}) => MaterialApp(
      home: Registrar(
        builder: () => MyRegisteredService(),
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
    return listen ? Text('${listenTo<MyRegisteredService>().number}') : Text('${get<MyRegisteredService>().number}');
  }
}

void main() {
  setUp(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyRegisteredService>(), false);
    expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
  });

  tearDown(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyRegisteredService>(), false);
    expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
  });

  group('MyWidget', () {
    testWidgets('not listening to Registrar, not registered, and not named ViewModel does not update value',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: false,
        myWidgetIsInherited: true,
        myWidgetIsRegistered: false,
        myWidgetRegisteredName: null,
      ));

      expect(Registrar.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      // expect does not increment b/c not listening
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to Registrar but not registered ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
          listenToMyRegisteredService: true,
          myWidgetIsInherited: true,
          myWidgetIsRegistered: false,
          myWidgetRegisteredName: null));

      expect(Registrar.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening to Registrar and registered ViewModel  but not named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: true,
        myWidgetIsInherited: false,
        myWidgetIsRegistered: true,
        myWidgetRegisteredName: null,
      ));

      expect(Registrar.isRegistered<MyWidgetViewModel>(), true);
      expect(Registrar.get<MyWidgetViewModel>().number, _number);

      // expect default values
      expect(find.text('$_number'), findsOneWidget);
      expect(find.text(_stringDefault), findsOneWidget);
      expect(find.text(_registeredStringDefault), findsOneWidget);
      expect(find.text(_namedStringDefault), findsOneWidget);
      expect(find.text('$_floatDefault'), findsOneWidget);

      // change values
      Registrar.get<MyRegisteredService>().incrementNumber();
      Registrar.get<MyWidgetViewModel>().myStringProperty.value = _stringUpdated;
      Registrar.get<MyWidgetViewModel>().myRegisteredStringProperty.value = _registeredStringUpdated;
      Registrar.get<MyWidgetViewModel>().myNamedStringProperty.value = _namedStringUpdated;
      Registrar.get<MyRegisteredService>().myFloatProperty.value = _floatUpdated;

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
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: true,
        myWidgetIsInherited: false,
        myWidgetIsRegistered: true,
        myWidgetRegisteredName: _viewModelName,
      ));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: _viewModelName), true);
      expect(Registrar.get<MyWidgetViewModel>(name: _viewModelName).number, _number);

      Registrar.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening to Registrar, registered and named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: true,
        myWidgetIsInherited: false,
        myWidgetIsRegistered: true,
        myWidgetRegisteredName: _viewModelName,
      ));

      expect(find.text('$_number'), findsOneWidget);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: _viewModelName), true);
      expect(Registrar.get<MyWidgetViewModel>(name: _viewModelName).number, _number);

      Registrar.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });

  group('Inherited model', () {
    testWidgets('listening to inherited model', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: false,
        myWidgetIsInherited: false,
        myWidgetIsRegistered: true,
        myWidgetRegisteredName: _viewModelName,
      ));

      expect(Registrar.isRegistered<MyInheritedService>(), false);
      expect(find.text(_inheritedStringDefault), findsOneWidget);

      await tester.tap(find.text(_updateMyInheritedServiceButtonText));
      await tester.pump();

      expect(find.text(_inheritedStringUpdated), findsOneWidget);
    });
  });

  group('MyStatelessViewWidget', () {
    testWidgets('non-listening stateless View does not update', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: false));

      expect(Registrar.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      // expect number did not increment (because not listening)
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening stateless View updates', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: true));

      expect(Registrar.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Registrar.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });
}
