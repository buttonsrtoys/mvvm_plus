## Move ViewModel to mixin like the new Stateless package?

    class MyWidget extends View with MyWidgetViewModel {

    }

## Optionally use InheritedWidget (like Provider) instead of Registrar

Add InheritedWidget functionality.

    // locator
    Registrar(
      builder: () => Cloud(),
      child: Blah(),
    );
          :
    final userNotifier = get<Cloud>().user;
    final user = listenTo<Cloud>(context: context).value;
    final user = listenTo<Property<User>>(notifier: get<Cloud>().user).value;

    // inherited
    Registrar(
      builder: () => Cloud(),
      inherited: true,
      child: Blah(),
    );
          :
    final cloud = context.get<Cloud>();
    final user = context.listenTo<Cloud>().user.value;
    final user = listenTo<Property<User>>(notifier: context.get<Cloud>().user).value;

    Could add decent error checking to above. E.g., if added context and not found, could check to 
    see if in registry and notify developer.

Hmm. How to use context.get<Cloud>() inside ViewModel, which doesn't have context? I suppose
we could add context to Model. So, "builder" sets Model.context.

Maaaaybe, have command to register inherited notifiers temporarily. E.g., when Navigator.push
used and widget on other branch needs to access temporarily. Hmmm. Could just use 
Registrar.(un)register, so probably should defer this until needed.

    context.register<MyInheritedNotifier>();
    await Navigator.push(MyEditPage());
    Registrar.unregister<MyInheritedNotifier>();

    or

    Registrar.register<MyInheritedNotifier>(instance: context.get<MyInheritedNotifier>());
    await Navigator.push(MyEditPage());
    Registrar.unregister<MyInheritedNotifier>();

## Add registry output for debugging

When a registry lookup fails, it would be handy to dump the closest matches. E.g., With same type or
with different type but same name.

This would be a change to Registrar.

