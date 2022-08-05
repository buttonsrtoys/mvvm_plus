import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

class MyWidgetViewModel extends ViewModel {
  final answer = 42;
}

void main() {
  group('View', () {
    test('unnamed view model', () {
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      Registrar.register<MyWidgetViewModel>(instance: MyWidgetViewModel());
      expect(Registrar.isRegistered<MyWidgetViewModel>(), true);
      expect(Registrar.get<MyWidgetViewModel>().answer, 42);
      Registrar.unregister<MyWidgetViewModel>();
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(() => Registrar.get<MyWidgetViewModel>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyWidgetViewModel>(), throwsA(isA<Exception>()));
    });

    test('named view model', () {
      String name = 'Some name';
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      Registrar.register<MyWidgetViewModel>(instance: MyWidgetViewModel(), name: name);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: name), true);
      expect(Registrar.get<MyWidgetViewModel>(name: name).answer, 42);
      Registrar.unregister<MyWidgetViewModel>(name: name);
      expect(Registrar.isRegistered<MyWidgetViewModel>(), false);
      expect(Registrar.isRegistered<MyWidgetViewModel>(name: name), false);
      expect(() => Registrar.get<MyWidgetViewModel>(name: name), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyWidgetViewModel>(name: name), throwsA(isA<Exception>()));
    });
  });
}
