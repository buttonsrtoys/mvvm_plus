import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

class MyNumberViewModel extends ViewModel {
  final answer = 42;
}

void main() {
  group('View', () {
    test('unnamed view model', () {
      expect(Registrar.isRegistered<MyNumberViewModel>(), false);
      Registrar.register<MyNumberViewModel>(instance: MyNumberViewModel());
      expect(Registrar.isRegistered<MyNumberViewModel>(), true);
      expect(Registrar.get<MyNumberViewModel>().answer, 42);
      Registrar.unregister<MyNumberViewModel>();
      expect(Registrar.isRegistered<MyNumberViewModel>(), false);
      expect(() => Registrar.get<MyNumberViewModel>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyNumberViewModel>(), throwsA(isA<Exception>()));
    });

    test('named view model', () {
      String name = 'Some name';
      expect(Registrar.isRegistered<MyNumberViewModel>(), false);
      Registrar.register<MyNumberViewModel>(instance: MyNumberViewModel(), name: name);
      expect(Registrar.isRegistered<MyNumberViewModel>(), false);
      expect(Registrar.isRegistered<MyNumberViewModel>(name: name), true);
      expect(Registrar.get<MyNumberViewModel>(name: name).answer, 42);
      Registrar.unregister<MyNumberViewModel>(name: name);
      expect(Registrar.isRegistered<MyNumberViewModel>(), false);
      expect(Registrar.isRegistered<MyNumberViewModel>(name: name), false);
      expect(() => Registrar.get<MyNumberViewModel>(name: name), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyNumberViewModel>(name: name), throwsA(isA<Exception>()));
    });
  });
}
