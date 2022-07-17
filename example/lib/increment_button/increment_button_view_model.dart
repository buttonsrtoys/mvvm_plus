import 'package:get_mvvm/view.dart';

enum IncrementType { number, letter }

class IncrementButtonViewModel extends ViewModel {
  IncrementButtonViewModel({
    required this.incrementNumber,
    required this.incrementLetter,
  });

  IncrementType _currentType = IncrementType.number;
  final void Function() incrementNumber;
  final void Function() incrementLetter;

  void incrementCounter() {
    _currentType == IncrementType.number ? incrementNumber() : incrementLetter();
    _currentType = _currentType == IncrementType.number ? IncrementType.letter : IncrementType.number;
    notifyListeners();
  }

  String get label => <String>['+1', '+a'][_currentType.index];
}
