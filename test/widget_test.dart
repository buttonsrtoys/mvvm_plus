import 'package:bilocator/bilocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_plus/src/src.dart';

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

/// [listenToMyRegisteredService] true to listen to [My]
/// [myWidgetIsRegistered] true to register [MyWidgetViewModel]
/// [myWidgetIsInherited] true to make [MyWidgetViewModel] part of inheritedWidget.
/// [myWidgetRegisteredName] is option name of registered [MyWidgetViewModel]
Widget testApp({
  required bool listenToMyRegisteredService,
  required Location? location,
  required String? myWidgetRegisteredName,
}) =>
    MaterialApp(
      home: Bilocator(
        builder: () => MyRegisteredService(),
        child: Bilocator(
          builder: () => MyInheritedService(),
          location: Location.tree,
          child: MyWidget(
            listenToRegisteredService: listenToMyRegisteredService,
            location: location,
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
    required this.location,
    this.name,
  }) : super(
            location: location,
            name: name,
            builder: () => MyWidgetViewModel(
                  listenToBilocator: listenToRegisteredService,
                ));

  final Location? location;
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
        if (location != null) TextWidgetThatUsesGet(location: location!, name: name),
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
class TextWidgetThatUsesGet extends StatelessView {
  TextWidgetThatUsesGet({super.key, required this.location, required this.name});

  final Location location;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Text(get<MyWidgetViewModel>(context: location == Location.tree ? context : null, name: name).untestedText);
  }
}

/// The [ViewModel]
class MyWidgetViewModel extends ViewModel {
  MyWidgetViewModel({
    this.listenToBilocator = false,
  });

  final bool listenToBilocator;
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
    if (listenToBilocator) {
      // listen twice so can later test that only one listener added
      listenTo<MyRegisteredService>(); // 1st listen
      myModel = listenTo<MyRegisteredService>(); // 2nd listen
    } else {
      myModel = get<MyRegisteredService>();
    }
  }

  int get number => myModel.number;
}

/// Test app for widget subclassed from [StatelessView]
Widget statelessTestApp({required bool listen}) => MaterialApp(
      home: Bilocator(
        builder: () => MyRegisteredService(),
        child: MyStatelessView(listen: listen),
      ),
    );

/// The [Bilocator] service
class MyStatelessView extends StatelessView {
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
    expect(Bilocator.isRegistered<MyRegisteredService>(), false);
    expect(Bilocator.isRegistered<MyWidgetViewModel>(), false);
  });

  tearDown(() {
    /// Ensure no residuals
    expect(Bilocator.isRegistered<MyRegisteredService>(), false);
    expect(Bilocator.isRegistered<MyWidgetViewModel>(), false);
  });

  group('MyWidget', () {
    testWidgets('not listening to Registrar, not registered, and not named ViewModel does not update value',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: false,
        location: Location.tree,
        myWidgetRegisteredName: null,
      ));

      expect(Bilocator.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Bilocator.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      // expect does not increment b/c not listening
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to Bilocator but not registered ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          testApp(listenToMyRegisteredService: true, location: Location.tree, myWidgetRegisteredName: null));

      expect(Bilocator.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Bilocator.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening to Bilocator and registered ViewModel  but not named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: true,
        location: Location.registry,
        myWidgetRegisteredName: null,
      ));

      expect(Bilocator.isRegistered<MyWidgetViewModel>(), true);
      expect(Bilocator.get<MyWidgetViewModel>().number, _number);

      // expect default values
      expect(find.text('$_number'), findsOneWidget);
      expect(find.text(_stringDefault), findsOneWidget);
      expect(find.text(_registeredStringDefault), findsOneWidget);
      expect(find.text(_namedStringDefault), findsOneWidget);
      expect(find.text('$_floatDefault'), findsOneWidget);

      // change values
      Bilocator.get<MyRegisteredService>().incrementNumber();
      Bilocator.get<MyWidgetViewModel>().myStringProperty.value = _stringUpdated;
      Bilocator.get<MyWidgetViewModel>().myRegisteredStringProperty.value = _registeredStringUpdated;
      Bilocator.get<MyWidgetViewModel>().myNamedStringProperty.value = _namedStringUpdated;
      Bilocator.get<MyRegisteredService>().myFloatProperty.value = _floatUpdated;

      await tester.pump();

      // expect updated values
      expect(find.text('${_number + 1}'), findsOneWidget);
      expect(find.text(_stringUpdated), findsOneWidget);
      expect(find.text(_registeredStringUpdated), findsOneWidget);
      expect(find.text(_namedStringUpdated), findsOneWidget);
      expect(find.text('$_floatUpdated'), findsOneWidget);
    });

    testWidgets('listening to Bilocator, registered and named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: true,
        location: Location.registry,
        myWidgetRegisteredName: _viewModelName,
      ));

      expect(find.text('$_number'), findsOneWidget);
      expect(Bilocator.isRegistered<MyWidgetViewModel>(), false);
      expect(Bilocator.isRegistered<MyWidgetViewModel>(name: _viewModelName), true);
      expect(Bilocator.get<MyWidgetViewModel>(name: _viewModelName).number, _number);

      Bilocator.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listening to Bilocator, registered and named ViewModel shows correct values',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: true,
        location: Location.registry,
        myWidgetRegisteredName: _viewModelName,
      ));

      expect(find.text('$_number'), findsOneWidget);
      expect(Bilocator.isRegistered<MyWidgetViewModel>(), false);
      expect(Bilocator.isRegistered<MyWidgetViewModel>(name: _viewModelName), true);
      expect(Bilocator.get<MyWidgetViewModel>(name: _viewModelName).number, _number);

      Bilocator.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });

  group('Inherited model', () {
    testWidgets('listening to inherited model', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(
        listenToMyRegisteredService: false,
        location: Location.registry,
        myWidgetRegisteredName: _viewModelName,
      ));

      expect(Bilocator.isRegistered<MyInheritedService>(), false);
      expect(find.text(_inheritedStringDefault), findsOneWidget);

      await tester.tap(find.text(_updateMyInheritedServiceButtonText));
      await tester.pump();

      expect(find.text(_inheritedStringUpdated), findsOneWidget);
    });
  });

  group('MyStatelessViewWidget', () {
    testWidgets('non-listening stateless View does not update', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: false));

      expect(Bilocator.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Bilocator.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      // expect number did not increment (because not listening)
      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening stateless View updates', (WidgetTester tester) async {
      await tester.pumpWidget(statelessTestApp(listen: true));

      expect(Bilocator.isRegistered<MyRegisteredService>(), true);
      expect(find.text('$_number'), findsOneWidget);

      Bilocator.get<MyRegisteredService>().incrementNumber();
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });
}
