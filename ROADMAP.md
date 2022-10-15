# Create Property class
- Replaces property typedef
- Immutable
- Includes error handling
    A SO response suggested having a Error property that is set when an error occurs:
    https://stackoverflow.com/questions/4228483/where-do-i-catch-exceptions-in-mvvm

    This SO approach works with the current implementation.

    final counter = createProperty<int>(0);

    if (counter.value == max) {
      counter.isValid = false;
    } else {
      counter.value += 1;
    }

    String text = counter.isValid ? 'Invalid number' : counter.value.toString();

    Also, `value` getter would throw if used when value was bad?

    class Property<T extends object> extends ValueNotifier<T> {
      bool _isValid;
      bool get isValid => _isValid;
      
      // Logs when value set to invalid
      set isValid(bool value) {
        if (kDebug) {
          debugPrint('Property<T> was set to invalid');
        }
        _isValid = value;
      }
      
      T get value {
        if (!isValid) {
          throw Exception('Property<$T> contains in invalid value');
        }
      }
    }