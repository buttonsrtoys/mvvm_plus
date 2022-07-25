import 'package:flutter_test/flutter_test.dart';
import 'package:view/registrar.dart';
import 'package:view/view.dart';

class MyViewModel extends ViewModel {
  final answer = 42;
}

void main() {
  group('View', () {
    test('unnamed view model', () {
      expect(Registrar.isRegistered<MyViewModel>(), false);
      Registrar.register<MyViewModel>(instance: MyViewModel());
      expect(Registrar.isRegistered<MyViewModel>(), true);
      expect(Registrar.get<MyViewModel>().answer, 42);
      Registrar.unregister<MyViewModel>();
      expect(Registrar.isRegistered<MyViewModel>(), false);
      expect(() => Registrar.get<MyViewModel>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyViewModel>(), throwsA(isA<Exception>()));
    });

    test('named view model', () {
      String name = 'Some name';
      expect(Registrar.isRegistered<MyViewModel>(), false);
      Registrar.register<MyViewModel>(instance: MyViewModel(), name: name);
      expect(Registrar.isRegistered<MyViewModel>(), false);
      expect(Registrar.isRegistered<MyViewModel>(name: name), true);
      expect(Registrar.get<MyViewModel>(name: name).answer, 42);
      Registrar.unregister<MyViewModel>(name: name);
      expect(Registrar.isRegistered<MyViewModel>(), false);
      expect(Registrar.isRegistered<MyViewModel>(name: name), false);
      expect(() => Registrar.get<MyViewModel>(name: name), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyViewModel>(name: name), throwsA(isA<Exception>()));
    });
  });
}
