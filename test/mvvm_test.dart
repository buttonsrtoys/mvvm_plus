import 'package:flutter_test/flutter_test.dart';
import 'package:view/view.dart';

class MyViewModel extends ViewModel {
  final answer = 42;
}

void main() {
  group('View', () {
    test('unnamed view model', () {
      expect(View.isRegistered<MyViewModel>(), false);
      View.register<MyViewModel>(MyViewModel());
      expect(View.isRegistered<MyViewModel>(), true);
      expect(View.get<MyViewModel>().answer, 42);
      View.unregister<MyViewModel>();
      expect(View.isRegistered<MyViewModel>(), false);
      expect(() => View.get<MyViewModel>(), throwsA(isA<Exception>()));
      expect(() => View.unregister<MyViewModel>(), throwsA(isA<Exception>()));
    });

    test('named view model', () {
      String name = 'Some name';
      expect(View.isRegistered<MyViewModel>(), false);
      View.register<MyViewModel>(MyViewModel(), name: name);
      expect(View.isRegistered<MyViewModel>(), false);
      expect(View.isRegistered<MyViewModel>(name: name), true);
      expect(View.get<MyViewModel>(name: name).answer, 42);
      View.unregister<MyViewModel>(name: name);
      expect(View.isRegistered<MyViewModel>(), false);
      expect(View.isRegistered<MyViewModel>(name: name), false);
      expect(() => View.get<MyViewModel>(name: name), throwsA(isA<Exception>()));
      expect(() => View.unregister<MyViewModel>(name: name), throwsA(isA<Exception>()));
    });
  });
}
