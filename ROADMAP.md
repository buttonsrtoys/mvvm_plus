# Create Property class
- Replaces property typedef
- Extends ValueNotifier
- Immutable
- No error handling b/c can be handled with custom property. See
    https://stackoverflow.com/questions/4228483/where-do-i-catch-exceptions-in-mvvm
- Add isValid field
    This SO approach works with the current implementation.

    final counter = createProperty<int>(0);

    if (counter.value == max) {
      counter.isValid = false;
    } else {
      counter.value += 1;
    }

    String text = counter.isValid ? 'Invalid number' : counter.value.toString();

    -  `value` getter would throw if used when value was inValid?

    class Property<T extends object> extends ValueNotifier<T> {
      bool _isValid;
      bool get isValid => _isValid;
      
      // Logs when value set to invalid
      set isValid(bool value) {
        if (kDebug) {
          debugPrint('Property<T>.isValid was set to $value');
        }
        _isValid = value;
      }
      
      T get value {
        if (!isValid) {
          throw Exception('Property<$T>.value getter called on invalid value');
        }
      }
    }