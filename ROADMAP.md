# Create Property class
- Replaces property typedef
- Immutable
- `error` members. E.g.,

    final counter = createProperty<int>(0);

    if (counter.value == max) {
      counter.errorMessage = 'Counter reached max';
    } else {
      counter.value += 1;
    }

    String text = counter.hasError ? counter.errorMessage : counter.value.toString();

    Also, `value` getter would throw if used when value was bad?

    class Property<T extends object> extends ValueNotifier<T> {
      set errorMessage (String message) {
        _errorMessage = message;
      }

      bool hasError => errorMessage != null;
      
      T get value {
        if (hasError) {
          throw Exception(errorMessage);
        }
      }
    }

- Option to add custom error handler that is called every time an error is set.
