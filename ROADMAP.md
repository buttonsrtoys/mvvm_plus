## StateNotifier

Consider extending ValueNotifier to StateNotifier to facilitate adding listeners and registering.
E.g.,

    class MyViewModel extends ViewModel {
      final counter = StateNotifier<int>(0, register: true, name: 'MyViewModel.counter');
      // or if remove register:true requirement when naming
      final counter = StateNotifier<int>(0, name: 'MyViewModel.counter');
      final someNotifier = StateNotifier<SomeNotifier>(SomeNotifier());
      @override
      void initState() {
        super.initState();

        // manually add listeners
        counter.addListener(buildView);
        someNotifier.addListener(notifyListeners);

        // or batch add like this...
        addListeners([
          {counter, buildView},
          {someNotifier, notifyListeners},
          {anotherNotifier, customListener},
        ]);
      }
    }

## For brevity, consider removing requirement to set 'register' true when 'name' != null;