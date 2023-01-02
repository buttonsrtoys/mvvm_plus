import 'package:flutter_test/flutter_test.dart';
import 'package:bilocator/bilocator.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

class MyNumberViewModel extends ViewModel {
  // final answer = 42;
  late final answer = createProperty<int>(42);
}

void main() {
  group('View', () {
    test('unnamed view model', () {
      expect(Bilocator.isRegistered<MyNumberViewModel>(), false);
      Bilocator.register<MyNumberViewModel>(instance: MyNumberViewModel());
      expect(Bilocator.isRegistered<MyNumberViewModel>(), true);
      expect(Bilocator.get<MyNumberViewModel>().answer.value, 42);
      Bilocator.unregister<MyNumberViewModel>();
      expect(Bilocator.isRegistered<MyNumberViewModel>(), false);
      expect(() => Bilocator.get<MyNumberViewModel>(), throwsA(isA<Exception>()));
      expect(() => Bilocator.unregister<MyNumberViewModel>(), throwsA(isA<Exception>()));
    });

    test('named view model', () {
      String name = 'Some name';
      expect(Bilocator.isRegistered<MyNumberViewModel>(), false);
      Bilocator.register<MyNumberViewModel>(instance: MyNumberViewModel(), name: name);
      expect(Bilocator.isRegistered<MyNumberViewModel>(), false);
      expect(Bilocator.isRegistered<MyNumberViewModel>(name: name), true);
      expect(Bilocator.get<MyNumberViewModel>(name: name).answer.value, 42);
      Bilocator.unregister<MyNumberViewModel>(name: name);
      expect(Bilocator.isRegistered<MyNumberViewModel>(), false);
      expect(Bilocator.isRegistered<MyNumberViewModel>(name: name), false);
      expect(() => Bilocator.get<MyNumberViewModel>(name: name), throwsA(isA<Exception>()));
      expect(() => Bilocator.unregister<MyNumberViewModel>(name: name), throwsA(isA<Exception>()));
    });

    test('buildViewCalls', () {
      final myNumberViewModel = MyNumberViewModel();
      expect(myNumberViewModel.buildViewCalls(), 0);
      myNumberViewModel.answer.value = 43;
      expect(myNumberViewModel.buildViewCalls(), 1);
      myNumberViewModel.answer.value = 42;
      expect(myNumberViewModel.buildViewCalls(), 2);
      // ignore: invalid_use_of_protected_member
      myNumberViewModel.buildView = () {};
      expect(myNumberViewModel.buildViewCalls(), -1);
    });
  });
}
