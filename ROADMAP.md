## Add Property

**Status: Done v0.4.0**

Consider extending ValueNotifier to "Property" to facilitate adding listeners and registering. E.g.,

    class MyViewModel extends ViewModel {
      final counter = Property<int>(0, register: true, name: 'MyViewModel.counter');
      // or if remove register:true requirement when naming
      final counter = Property<int>(0, name: 'MyViewModel.counter');
      final someNotifier = Property<SomeNotifier>(SomeNotifier());
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

**Status: Done v0.4.0**